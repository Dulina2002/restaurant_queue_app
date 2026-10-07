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
--    reviewed Customer/staff queue policies or RPCs in the same release before
--    enabling their workflows. This draft does not invent those permissions.
-- 7. Profile writes below are backend-only to protect the authorization source.
--    Coordinate safe full_name editing/provisioning endpoints before rollout.
-- 8. Never ship service-role credentials to Flutter. Never disable RLS.

BEGIN;

-- ============================================================================
-- SECTION A: PREFLIGHT AND PROPOSED CREATE STATEMENTS
-- ============================================================================

DO $preflight$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'profiles'
      AND column_name = 'id' AND udt_name = 'uuid'
  ) THEN
    RAISE EXCEPTION 'Review blocker: profiles.id must match Supabase Auth UUIDs';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'queue_entries'
      AND column_name = 'updated_at' AND udt_name = 'timestamptz'
  ) THEN
    RAISE EXCEPTION 'Review blocker: verify/add queue_entries.updated_at timestamptz separately';
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
AS $function$
DECLARE
  affected_count bigint;
BEGIN
  IF auth.uid() IS NULL OR NOT admin_private.is_admin() THEN
    RAISE EXCEPTION 'Authenticated Admin required' USING ERRCODE = '42501';
  END IF;

  -- Serialize with queue INSERT/UPDATE/DELETE for the transaction. Pending
  -- writers wait; rows committed before this lock are evaluated by the UPDATE.
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
-- Proposed follow-up: transactionally audit actor, time, reason, affected IDs.
-- No audit table exists today; do not claim this draft adds one.

-- ============================================================================
-- SECTION B: PROPOSED POLICY AND GRANT CHANGES (EXISTING AND NEW TABLES)
-- ============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.restaurants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.queue_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.broadcasts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.platform_settings ENABLE ROW LEVEL SECURITY;

-- Protect the role source. Preserve existing own-profile SELECT policy exactly.
-- No INSERT/UPDATE/DELETE is granted to application clients in this draft.
-- Revoke table AND known column write grants (table revoke alone is insufficient).
REVOKE INSERT, UPDATE, DELETE ON public.profiles FROM PUBLIC, anon, authenticated;
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
-- Inspect/revoke any column-level mutation grants too. The verified queue column
-- list is incomplete, so this draft does not invent a list of those columns.
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
-- Freeze persistence does NOT enforce a freeze. Queue/reservation write endpoints
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
