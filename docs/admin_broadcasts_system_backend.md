# SCRUM-30 Admin Broadcasts and System backend

**ALREADY APPLIED MANUALLY / DO NOT AUTOMATICALLY EXECUTE**

The project owner supplied the live schema and behavior below. This task did not
execute SQL, deploy database changes, or call live mutation APIs. Existing
Restaurant and Users behavior is preserved. No SCRUM-31 work is included.

## Broadcasts

`public.broadcasts`: id UUID primary key/default gen_random_uuid(), title/message
required text, priority required text/default NORMAL/check NORMAL|WARNING|URGENT,
is_active required boolean/default true, created_by UUID referencing auth.users(id)
ON DELETE SET NULL, created_at required timestamptz/default now(). RLS is enabled:
authenticated SELECT; Admin-only INSERT/UPDATE/DELETE using admin_private.is_admin().

The service reads newest first and preserves empty results. Creation sends only
title/message/priority, through the current authenticated client and RLS. It relies
on the supplied database default auth.uid() for created_by; verify that default
exists (the column list alone does not establish it). It returns the inserted row.
The UI updates only on success, keeps Send open on failure, and shows local-time
created_at and active/archive status. Persisted announcements do NOT deliver push
notifications. No service-role key is used in Flutter.

## System

`public.platform_settings`: id text primary key constrained to global,
platform_frozen required boolean/default false, updated_by UUID referencing
Auth users ON DELETE SET NULL, updated_at required timestamptz/default now().
The global row exists; authenticated reads are permitted.

`public.set_platform_freeze(p_frozen boolean)` is an Admin-authorized SECURITY
DEFINER RPC. It updates the global value, auth.uid() attribution and timestamp,
returning platform_frozen/updated_at. Service accepts the returned one-row array
or object. Missing global row/invalid confirmation is an error. UI changes only
after confirmed success and retains previous state on failure.

Live BEFORE INSERT triggers on reservations and queue_entries reject NEW rows
when frozen. Existing rows are not deleted or modified. Enforcement is server-side;
this task does not change Customer/Manager/Receptionist/Auth code or error handling.

`public.flush_waitlists()` is Admin-authorized SECURITY DEFINER, returns an integer
count and updates waiting/called -> cancelled plus updated_at. Rows/history remain.
Flutter calls the RPC; it never directly deletes or updates queue rows. Warning
covers every restaurant waitlist; success reports count including a clear zero-case.
The UI prevents overlapping System mutations. Network ambiguity remains possible:
verify outcome before retrying flush, since a retry can affect new arrivals.

## SQL documentation/replay reference

The full deployed SQL, exact policy/trigger names, grants, function ownership,
search_path and concurrency details were NOT supplied. The definitions below are
reconstructed from the supplied contracts, NOT a verified pg_dump or a claim about
the deployed function bodies. Do not run them over an existing deployment. Obtain
pg_get_functiondef/pg_get_triggerdef and policy exports from a trusted operator
before preparing any reviewed replay. In particular, do not invent or silently
replace production triggers. Database defaults/constraints/grants must be audited.

```sql
-- ALREADY APPLIED MANUALLY / DO NOT AUTOMATICALLY EXECUTE
-- Schema/default reference reconstructed from owner-supplied facts.
BEGIN;
CREATE TABLE public.broadcasts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  message text NOT NULL,
  priority text NOT NULL DEFAULT 'NORMAL'
    CHECK (priority IN ('NORMAL', 'WARNING', 'URGENT')),
  is_active boolean NOT NULL DEFAULT true,
  created_by uuid DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.broadcasts ENABLE ROW LEVEL SECURITY;
-- Policy names here are descriptive replay names, not verified deployed names.
CREATE POLICY "Authenticated read broadcasts" ON public.broadcasts
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "Admin insert broadcasts" ON public.broadcasts
  FOR INSERT TO authenticated WITH CHECK ((SELECT admin_private.is_admin()));
CREATE POLICY "Admin update broadcasts" ON public.broadcasts
  FOR UPDATE TO authenticated USING ((SELECT admin_private.is_admin()))
  WITH CHECK ((SELECT admin_private.is_admin()));
CREATE POLICY "Admin delete broadcasts" ON public.broadcasts
  FOR DELETE TO authenticated USING ((SELECT admin_private.is_admin()));

CREATE TABLE public.platform_settings (
  id text PRIMARY KEY CHECK (id = 'global'),
  platform_frozen boolean NOT NULL DEFAULT false,
  updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);
INSERT INTO public.platform_settings (id) VALUES ('global');
ALTER TABLE public.platform_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated read platform settings" ON public.platform_settings
  FOR SELECT TO authenticated USING (true);
-- Direct writes/grants were not provided: none is invented here.

-- Reference RPC call shapes, not execution instructions:
-- SELECT * FROM public.set_platform_freeze(p_frozen => true);
-- SELECT public.flush_waitlists();
-- Freeze RPC's supplied write contract:
-- UPDATE public.platform_settings SET platform_frozen = p_frozen,
--   updated_by = auth.uid(), updated_at = now() WHERE id = 'global'
--   RETURNING platform_frozen, updated_at;
-- Flush RPC's supplied write contract:
-- UPDATE public.queue_entries SET status = 'cancelled', updated_at = now()
--   WHERE status IN ('waiting', 'called');
-- GET DIAGNOSTICS affected_count = ROW_COUNT; RETURN affected_count;
-- BOTH RPCs first require admin_private.is_admin(). Their complete deployed
-- SECURITY DEFINER definitions and EXECUTE grants require operator export.
-- BEFORE INSERT trigger contract for reservations and queue_entries:
-- if global.platform_frozen then RAISE EXCEPTION; otherwise RETURN NEW.
-- Exact trigger names/bodies, search_path and locks require operator export.
ROLLBACK;
```

For read-only inspection by a trusted SQL operator (NOT run during this task):

```sql
SELECT pg_get_functiondef(p.oid)
FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname IN ('set_platform_freeze', 'flush_waitlists');
SELECT pg_get_triggerdef(oid), tgfoid::regprocedure
FROM pg_trigger
WHERE tgrelid IN ('public.reservations'::regclass, 'public.queue_entries'::regclass)
  AND NOT tgisinternal;
SELECT tablename, policyname, roles, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'public' AND tablename IN ('broadcasts','platform_settings');
```

## Validation and limitations

Admin widget tests use injected fake services, no live Supabase calls. Tests cover
persisted/empty/failed reads, priorities, delayed successful and failed sends,
persisted freeze/unfreeze, delayed freeze success/failure, count/zero/error flush,
and existing Admin Users behavior. Historical local-preview assertions were updated.

No realtime subscription or push delivery is implemented. Reloading the dashboard
fetches persisted state; other Admin sessions can leave this snapshot stale until
reload. The deployed RPC/trigger security and locking are owner-reported contracts,
not independently inspected by this task. Live end-to-end RLS/RPC verification
must be performed separately by an authorized operator.
