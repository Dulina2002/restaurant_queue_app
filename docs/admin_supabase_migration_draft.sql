-- DO NOT APPLY UNTIL SUPABASE AUTH MIGRATION IS MERGED AND VERIFIED
-- PROPOSED MIGRATION DRAFT ONLY. Nothing in this file has been deployed.
-- Do not run this file against Supabase as part of the current task.
-- Default ending is ROLLBACK. A reviewed deployment must deliberately replace
-- it with COMMIT after Auth, authorization, schema, and workflow tests pass.
-- Reference: https://supabase.com/docs/guides/database/postgres/row-level-security
-- Reference: https://supabase.com/docs/guides/database/functions
-- Reference: https://www.postgresql.org/docs/current/sql-createfunction.html

-- VERIFIED CURRENT STATE
-- profiles: id, role, full_name. No email column.
-- restaurants: id, name, cuisine, tag, location, rating, reviews_count,
-- is_active, is_queue_available, est_wait, waitlist_count, created_at.
-- queue statuses: waiting, called, seated, cancelled.
-- "Public manage restaurants" and "Public manage queue_entries" use USING (true).
-- No application database functions, broadcasts, or settings tables exist today.

-- REVIEW PREREQUISITES (NOT VERIFIED BY THE ABOVE FACTS)
-- 1. Supabase Auth is active for every role; profiles.id matches auth.uid().
--    This draft assumes profiles.id is UUID and uniquely identifies a user.
-- 2. Execute as a trusted migration owner (postgres in this draft), never Flutter.
--    The SECURITY DEFINER owner must have the needed table privileges and bypass
--    profiles RLS to avoid recursive Admin SELECT-policy evaluation. Review any
--    FORCE ROW LEVEL SECURITY setting and the owner's privileges beforehand.
-- 3. Provision/repair Admin roles using a trusted backend only. Never let users
--    choose their own privileged role at signup. No auth.users client queries.
-- 4. Review ALL existing policies, grants, triggers, foreign keys, and defaults.
--    Additional permissive policies can broaden access; this is not an audit of
--    unverified policies. Restaurant delete cascades/retention require review.
-- 5. queue_entries.updated_at was NOT verified. The preflight below requires an
--    existing timestamptz column. If absent, a separately reviewed proposed DDL is:
--    ALTER TABLE public.queue_entries
--      ADD COLUMN updated_at timestamptz NOT NULL DEFAULT now();
--    This addition is intentionally NOT executed by this draft.
-- 6. The queue policy change below closes broad direct mutation access. Deploy
--    reviewed Customer/staff queue policies or RPCs BEFORE removing existing
--    capabilities. This draft does not invent those permissions or workflows.
-- 7. Profile writes below are backend-only to protect the authorization source.
--    Coordinate safe full_name editing/provisioning endpoints before rollout.
-- 8. Never ship service-role credentials to Flutter. Never disable RLS.

BEGIN;

-- ============================================================================
-- SECTION A: PREFLIGHT AND PROPOSED CREATE STATEMENTS
-- ============================================================================

DO $preflight$
DECLARE
  -- INTENTIONALLY FALSE: listing policies/grants is not an authorization audit.
  -- A reviewer must reconcile the output with the approved access matrix and
  -- explicitly attest these gates in a separate, reviewed deployment version.
  policies_and_privileges_audited boolean := false;
  secure_profile_replacements_ready boolean := false;
  secure_queue_replacements_ready boolean := false;
  auth_migration_verified boolean := false;
  audit_row record;
  app_role text;
BEGIN
  -- Backend-only inspection of auth.users; this is not a Flutter query.
  -- The migration itself does not create, modify, or delete Auth identities.
  IF current_user <> 'postgres' THEN
    RAISE EXCEPTION 'Review blocker: this draft requires the trusted postgres migration owner';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'profiles'
      AND column_name = 'id' AND udt_name = 'uuid'
  ) THEN
    RAISE EXCEPTION 'Review blocker: profiles.id must match Supabase Auth UUIDs';
  END IF;
  -- Nonnullable, valid, immediate, single-column unique index/PK suitable for
  -- foreign-key references. Partial/expression/deferrable uniqueness is rejected.
  IF NOT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_attribute AS a
    JOIN pg_catalog.pg_index AS i
      ON i.indrelid = a.attrelid AND i.indkey[0] = a.attnum
    WHERE a.attrelid = 'public.profiles'::regclass AND a.attname = 'id'
      AND a.attnotnull AND NOT a.attisdropped
      AND i.indisunique AND i.indisvalid AND i.indimmediate
      AND i.indnkeyatts = 1 AND i.indpred IS NULL AND i.indexprs IS NULL
  ) THEN
    RAISE EXCEPTION 'Review blocker: profiles.id needs a nonnull FK-suitable unique key/PK';
  END IF;
  IF EXISTS (
    SELECT 1 FROM public.profiles AS p
    LEFT JOIN auth.users AS u ON u.id = p.id
    WHERE u.id IS NULL
  ) THEN
    RAISE EXCEPTION 'Review blocker: some profiles.id values have no matching Supabase Auth user';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles AS p JOIN auth.users AS u ON u.id = p.id
    WHERE p.role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Review blocker: no Auth-linked Admin profile exists';
  END IF;
  -- Matching UUIDs proves referential compatibility, NOT that the correct person
  -- owns each profile. Verify account mapping, role provisioning, and actual
  -- signed-in sessions manually before attesting auth_migration_verified.
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'queue_entries'
      AND column_name = 'updated_at' AND udt_name = 'timestamptz'
  ) THEN
    RAISE EXCEPTION 'Review blocker: verify/add queue_entries.updated_at timestamptz separately';
  END IF;

  -- Function ownership alone does not imply RLS bypass. The helper must read
  -- profiles without invoking its own policy, even when FORCE RLS is enabled.
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_roles AS r
    JOIN pg_catalog.pg_class AS c ON c.oid = 'public.profiles'::regclass
    WHERE r.rolname = 'postgres'
      AND (r.rolsuper OR r.rolbypassrls
        OR (c.relowner = r.oid AND NOT c.relforcerowsecurity))
  ) OR NOT pg_catalog.has_table_privilege('postgres', 'public.profiles', 'SELECT')
    OR NOT pg_catalog.has_table_privilege('postgres', 'public.queue_entries', 'SELECT')
    OR NOT pg_catalog.has_table_privilege('postgres', 'public.queue_entries', 'UPDATE')
  THEN
    RAISE EXCEPTION 'Review blocker: verify helper/RPC owner privileges and profiles RLS bypass';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_roles AS r
    JOIN pg_catalog.pg_class AS c ON c.oid = 'public.queue_entries'::regclass
    WHERE r.rolname = 'postgres'
      AND (r.rolsuper OR r.rolbypassrls
        OR (c.relowner = r.oid AND NOT c.relforcerowsecurity))
  ) THEN
    RAISE EXCEPTION 'Review blocker: flush owner must bypass queue RLS after direct writes are revoked';
  END IF;

  -- Inventory ALL policies, including roles, permissive/restrictive composition,
  -- USING, and WITH CHECK. Do not silently ignore additional broad policies.
  FOR audit_row IN
    SELECT tablename, policyname, permissive, roles, cmd, qual, with_check
    FROM pg_catalog.pg_policies
    WHERE schemaname = 'public'
      AND tablename IN ('profiles', 'restaurants', 'queue_entries')
    ORDER BY tablename, policyname
  LOOP
    RAISE NOTICE 'POLICY AUDIT: %', pg_catalog.row_to_json(audit_row);
  END LOOP;
  FOR audit_row IN
    SELECT c.relname, pg_catalog.pg_get_userbyid(c.relowner) AS owner,
      c.relrowsecurity AS rls_enabled, c.relforcerowsecurity AS force_rls
    FROM pg_catalog.pg_class AS c
    JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname IN ('profiles', 'restaurants', 'queue_entries')
  LOOP
    RAISE NOTICE 'OWNER/RLS AUDIT: %', pg_catalog.row_to_json(audit_row);
  END LOOP;
  -- Effective privileges include direct, PUBLIC, and inherited role grants.
  -- Column privileges are included: row policies are not a substitute for ACLs.
  FOREACH app_role IN ARRAY ARRAY['anon', 'authenticated']::text[] LOOP
    FOR audit_row IN
      SELECT t.table_name, v.privilege,
        pg_catalog.has_table_privilege(app_role,
          pg_catalog.format('public.%I', t.table_name), v.privilege) AS allowed
      FROM (VALUES ('profiles'), ('restaurants'), ('queue_entries')) AS t(table_name)
      CROSS JOIN (VALUES ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE'),
        ('TRUNCATE'), ('REFERENCES'), ('TRIGGER')) AS v(privilege)
      ORDER BY t.table_name, v.privilege
    LOOP
      RAISE NOTICE 'EFFECTIVE TABLE ACL [%]: %', app_role, pg_catalog.row_to_json(audit_row);
    END LOOP;
    FOR audit_row IN
      SELECT c.table_name, c.column_name, v.privilege,
        pg_catalog.has_column_privilege(app_role,
          pg_catalog.format('public.%I', c.table_name),
          c.column_name, v.privilege) AS allowed
      FROM information_schema.columns AS c
      CROSS JOIN (VALUES ('SELECT'), ('INSERT'), ('UPDATE'), ('REFERENCES')) AS v(privilege)
      WHERE c.table_schema = 'public'
        AND c.table_name IN ('profiles', 'restaurants', 'queue_entries')
      ORDER BY c.table_name, c.ordinal_position, v.privilege
    LOOP
      RAISE NOTICE 'EFFECTIVE COLUMN ACL [%]: %', app_role, pg_catalog.row_to_json(audit_row);
    END LOOP;
  END LOOP;

  -- FAIL CLOSED before CREATE/DROP/REVOKE. These attestations are deliberately
  -- not auto-set by successful catalog checks. Keep this file a blocked DRAFT.
  IF NOT auth_migration_verified OR NOT policies_and_privileges_audited
    OR NOT secure_profile_replacements_ready OR NOT secure_queue_replacements_ready
  THEN
    RAISE EXCEPTION 'DRAFT BLOCKED: Auth verification, policy/ACL audit, and secure profile/queue replacement workflows must be approved first';
  END IF;
END;
$preflight$;

-- New private schema: keep it OUT of Supabase exposed API schemas.
CREATE SCHEMA admin_private AUTHORIZATION postgres;
REVOKE ALL ON SCHEMA admin_private FROM PUBLIC, anon, authenticated;
GRANT USAGE ON SCHEMA admin_private TO authenticated;

-- Takes no supplied user/role parameters. Checks only the verified caller.
-- SECURITY DEFINER avoids profiles policy recursion; no writable search schema.
CREATE FUNCTION admin_private.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT auth.uid() IS NOT NULL AND EXISTS (
    SELECT 1 FROM public.profiles AS p
    WHERE p.id = auth.uid() AND p.role = 'admin'
  );
$function$;
ALTER FUNCTION admin_private.is_admin() OWNER TO postgres;
REVOKE ALL ON FUNCTION admin_private.is_admin() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION admin_private.is_admin() TO authenticated;

-- Proposed new table. gen_random_uuid() availability must be verified.
CREATE TABLE public.broadcasts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL CHECK (length(btrim(title)) BETWEEN 1 AND 200),
  message text NOT NULL CHECK (length(btrim(message)) BETWEEN 1 AND 10000),
  priority text NOT NULL DEFAULT 'NORMAL'
    CHECK (priority IN ('NORMAL', 'WARNING', 'URGENT')),
  created_by uuid NOT NULL DEFAULT auth.uid() REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  active boolean NOT NULL DEFAULT true
);

-- Proposed singleton. Client cannot insert/delete rows; only update row 1.
CREATE TABLE public.platform_settings (
  id smallint PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  platform_frozen boolean NOT NULL DEFAULT false,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid REFERENCES public.profiles(id)
);
INSERT INTO public.platform_settings (id, platform_frozen) VALUES (1, false);

-- Automatic actor/time attribution; clients cannot forge these update values.
-- This proposed trigger is not an existing deployed function.
CREATE FUNCTION admin_private.stamp_platform_settings()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  IF auth.uid() IS NULL OR NOT admin_private.is_admin() THEN
    RAISE EXCEPTION 'Authenticated Admin required' USING ERRCODE = '42501';
  END IF;
  NEW.updated_by := auth.uid();
  NEW.updated_at := pg_catalog.statement_timestamp();
  RETURN NEW;
END;
$function$;
ALTER FUNCTION admin_private.stamp_platform_settings() OWNER TO postgres;
REVOKE ALL ON FUNCTION admin_private.stamp_platform_settings()
  FROM PUBLIC, anon, authenticated;
CREATE TRIGGER stamp_platform_settings_update
BEFORE UPDATE ON public.platform_settings
FOR EACH ROW EXECUTE FUNCTION admin_private.stamp_platform_settings();

-- Proposed RPC: returns one bigint, the number of rows changed.
-- This is cancellation, NOT deletion. Historical/seated rows remain untouched.
CREATE FUNCTION public.flush_waitlists()
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
SET lock_timeout = '5s'
AS $function$
DECLARE
  affected_count bigint;
BEGIN
  IF auth.uid() IS NULL OR NOT admin_private.is_admin() THEN
    RAISE EXCEPTION 'Authenticated Admin required' USING ERRCODE = '42501';
  END IF;

  -- Serialize with queue INSERT/UPDATE/DELETE for the transaction. Pending
  -- writers wait; rows committed before this lock are evaluated by the UPDATE.
  -- Use READ COMMITTED for the intended cutoff at lock acquisition. Under a
  -- pre-existing REPEATABLE READ snapshot, this lock does not refresh the snapshot.
  -- Review the global scope and lock latency before production use.
  LOCK TABLE public.queue_entries IN SHARE ROW EXCLUSIVE MODE;
  UPDATE public.queue_entries
     SET status = 'cancelled', updated_at = pg_catalog.statement_timestamp()
   WHERE status IN ('waiting', 'called');
  GET DIAGNOSTICS affected_count = ROW_COUNT;
  RETURN affected_count;
END;
$function$;
ALTER FUNCTION public.flush_waitlists() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.flush_waitlists() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.flush_waitlists() TO authenticated;
-- authenticated execution alone is insufficient: the function also checks Admin.
-- lock_timeout limits EACH lock wait; it is not an overall execution deadline.
-- Configure a reviewed RPC/gateway statement_timeout (suggested 30 seconds)
-- BEFORE calling the function. Setting statement_timeout inside a function does
-- not reliably bound the already-running outer statement. Use short transactions;
-- the table lock remains held until the calling transaction ends.
-- Timeout/deadlock/serialization errors must roll back the whole call. Retry the
-- whole transaction with bounded attempts and exponential backoff/jitter; never
-- report success after an error. Calls are status-idempotent for already-cancelled
-- rows, but a retry can cancel NEW arrivals. After an ambiguous network timeout,
-- verify outcome/request scope before retrying; no request-id deduplication exists.
-- Proposed follow-up: transactionally audit actor, time, reason, affected IDs.
-- No audit table exists today; do not claim this draft adds one.

-- ============================================================================
-- SECTION B: PROPOSED POLICY AND GRANT CHANGES (EXISTING AND NEW TABLES)
-- ============================================================================

-- DEPLOYMENT GATE: do not reach these changes until the preflight attestations
-- are satisfied. Secure profile provisioning/editing and Customer/staff queue
-- replacements must already be deployed/tested, or be part of the same atomic
-- reviewed release. Auth migration by itself is insufficient. Replacement RPCs
-- can be used with these revocations; replacement direct-write policies ALSO
-- require narrowly scoped table/column grants absent from this draft.

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.restaurants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.queue_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.broadcasts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.platform_settings ENABLE ROW LEVEL SECURITY;

-- Protect the role source. Preserve existing own-profile SELECT policy exactly.
-- No INSERT/UPDATE/DELETE is granted to application clients in this draft.
-- PostgreSQL table-level REVOKE also revokes corresponding column privileges
-- granted by that grantor. The explicit column REVOKE is redundant hardening for
-- the known columns. Effective permissions can still arrive via inherited roles
-- or other grantors; audit them rather than assuming these statements remove all.
REVOKE INSERT, UPDATE, DELETE ON public.profiles FROM PUBLIC, anon, authenticated;
REVOKE TRUNCATE ON public.profiles FROM PUBLIC, anon, authenticated;
REVOKE INSERT (id, role, full_name), UPDATE (id, role, full_name),
  REFERENCES (id, role, full_name) ON public.profiles FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.profiles TO authenticated;
CREATE POLICY "Admin read all profiles" ON public.profiles
  FOR SELECT TO authenticated
  USING ((SELECT admin_private.is_admin()));
-- Trusted provisioning/role management must remain backend-only. Review all
-- other role memberships/functions to ensure no self-promotion bypass exists.

-- Preserve existing "Public read restaurants" SELECT policy; public browsing
-- is a stated application requirement. Remove the known broad ALL policy.
DROP POLICY "Public manage restaurants" ON public.restaurants;
REVOKE INSERT, UPDATE, DELETE ON public.restaurants FROM PUBLIC, anon;
REVOKE TRUNCATE ON public.restaurants FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.restaurants TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.restaurants TO authenticated;
CREATE POLICY "Admin insert restaurants" ON public.restaurants
  FOR INSERT TO authenticated
  WITH CHECK ((SELECT admin_private.is_admin()));
CREATE POLICY "Admin update restaurants" ON public.restaurants
  FOR UPDATE TO authenticated
  USING ((SELECT admin_private.is_admin()))
  WITH CHECK ((SELECT admin_private.is_admin()));
CREATE POLICY "Admin delete restaurants" ON public.restaurants
  FOR DELETE TO authenticated
  USING ((SELECT admin_private.is_admin()));
-- Inspect/remove any OTHER permissive mutation policies before relying on these.

-- Preserve existing queue SELECT policy. No direct queue mutation policy is
-- introduced: secure Customer/staff replacements must be reviewed separately.
DROP POLICY "Public manage queue_entries" ON public.queue_entries;
REVOKE INSERT, UPDATE, DELETE ON public.queue_entries FROM PUBLIC, anon, authenticated;
REVOKE TRUNCATE ON public.queue_entries FROM PUBLIC, anon, authenticated;
-- Corresponding column grants from the revoking grantor are revoked as well.
-- Recheck effective column/table ACLs and inherited access against the approved
-- replacement workflow matrix; do not invent grants from an incomplete schema.
-- The SECURITY DEFINER flush RPC can update with its trusted owner's privileges.

REVOKE ALL ON public.broadcasts FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.broadcasts TO authenticated;
-- Conservative proposal: signed-in recipients read active broadcasts only;
-- Admins can also read archived broadcasts. No anonymous/public read grant.
CREATE POLICY "Read active broadcasts or Admin archive" ON public.broadcasts
  FOR SELECT TO authenticated
  USING (active OR (SELECT admin_private.is_admin()));
CREATE POLICY "Admin create broadcasts" ON public.broadcasts
  FOR INSERT TO authenticated
  WITH CHECK ((SELECT admin_private.is_admin()) AND created_by = auth.uid());
CREATE POLICY "Admin update broadcasts" ON public.broadcasts
  FOR UPDATE TO authenticated
  USING ((SELECT admin_private.is_admin()))
  WITH CHECK ((SELECT admin_private.is_admin()));
CREATE POLICY "Admin delete broadcasts" ON public.broadcasts
  FOR DELETE TO authenticated USING ((SELECT admin_private.is_admin()));
-- Limit client edits to content/active flag; preserve creator/time attribution.
REVOKE UPDATE ON public.broadcasts FROM authenticated;
GRANT UPDATE (title, message, priority, active) ON public.broadcasts TO authenticated;
REVOKE INSERT ON public.broadcasts FROM authenticated;
GRANT INSERT (title, message, priority, active) ON public.broadcasts TO authenticated;

REVOKE ALL ON public.platform_settings FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.platform_settings TO authenticated;
GRANT UPDATE (platform_frozen) ON public.platform_settings TO authenticated;
CREATE POLICY "Authenticated read platform settings" ON public.platform_settings
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "Admin update platform settings" ON public.platform_settings
  FOR UPDATE TO authenticated
  USING (id = 1 AND (SELECT admin_private.is_admin()))
  WITH CHECK (id = 1 AND (SELECT admin_private.is_admin())
    AND updated_by = auth.uid());
-- No client INSERT/DELETE policies or grants: the singleton cannot be removed.
-- PLATFORM FREEZE IS INCOMPLETE: persistence alone does NOT enforce a freeze.
-- Queue/reservation write endpoints
-- must enforce the flag server-side with coordinated transactions before claiming
-- the platform is frozen. That shared/backend work is outside this draft.

-- REVIEW/TEST BEFORE ANY DEPLOYMENT:
-- Anonymous and ordinary authenticated callers cannot mutate restaurants/settings
-- or flush queues; verified Admins can. Self-profile reads still work. Admin-wide
-- reads do not recurse. Clients cannot assign themselves roles or spoof attribution.
-- Flush returns a count, preserves seated/cancelled rows, and updates timestamps.
-- Test concurrency, legitimate Customer/staff queue paths, and real Auth sessions.
-- No Dart/Auth/configuration changes or remote execution are part of this draft.
ROLLBACK;
