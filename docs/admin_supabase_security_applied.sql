-- SCRUM-24 ADMIN SECURITY: ALREADY APPLIED MANUALLY IN SUPABASE SQL EDITOR.
-- Deployment facts supplied by the project owner on 2026-10-08.
-- This file records those changes; Codex has NOT executed this SQL.
-- No Broadcast, System, queue, Auth implementation, or schema-column changes.
-- Reapplication must use a trusted migration connection, never the Flutter client.
-- Default ROLLBACK makes this a non-persisting replay/review script. Change to
-- COMMIT only during a separately authorized deployment, if one is needed.
--
-- Preconditions: public.profiles(id, role, full_name) exists with RLS enabled;
-- the own-profile INSERT and SELECT policies already exist; profiles.id matches
-- Supabase Auth UUIDs; Admin roles are provisioned through trusted workflows.
-- postgres must have SELECT on profiles and bypass its RLS to avoid recursion:
-- SUPERUSER/BYPASSRLS, or table ownership without FORCE ROW LEVEL SECURITY.
-- Keep admin_private OUT of Supabase's exposed API schemas. Verify existing
-- policies/grants do not permit self-promotion or other broad profile reads.
-- These assumptions are not a claim that a full live privilege audit was done.

BEGIN;

-- Fail closed on unexpected ownership when replaying against an existing schema.
-- CREATE OR REPLACE must not overwrite an unrelated helper of the same name;
-- review its definition/ownership first if this is not the recorded deployment.
DO $preflight$
BEGIN
  IF current_user <> 'postgres' THEN
    RAISE EXCEPTION 'Use the reviewed postgres migration connection';
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_catalog.pg_namespace
    WHERE nspname = 'admin_private'
      AND nspowner <> 'postgres'::regrole
  ) THEN
    RAISE EXCEPTION 'Unexpected admin_private owner; review before replay';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_class AS c
    JOIN pg_catalog.pg_roles AS r ON r.rolname = 'postgres'
    WHERE c.oid = 'public.profiles'::regclass
      AND c.relrowsecurity
      AND (r.rolsuper OR r.rolbypassrls
        OR (c.relowner = r.oid AND NOT c.relforcerowsecurity))
  ) OR NOT pg_catalog.has_table_privilege(
    'postgres', 'public.profiles', 'SELECT'
  ) THEN
    RAISE EXCEPTION 'Verify profiles RLS and helper owner SELECT/RLS bypass';
  END IF;
END;
$preflight$;

-- 1. Applied: self-profile creation is restricted to the caller's CUSTOMER row.
-- TO public is the supplied deployed policy scope. auth.uid() is NULL without
-- an authenticated identity, so anonymous callers cannot satisfy this check.
-- This does not grant INSERT or change any other INSERT/UPDATE/DELETE policy.
ALTER POLICY "Users can insert own profile."
ON public.profiles
TO public
WITH CHECK (
  auth.uid() = id
  AND role = 'customer'
);

-- 2. Applied: private, parameterless Admin authorization helper.
CREATE SCHEMA IF NOT EXISTS admin_private AUTHORIZATION postgres;
REVOKE ALL ON SCHEMA admin_private FROM PUBLIC, anon, authenticated;
GRANT USAGE ON SCHEMA admin_private TO authenticated;

CREATE OR REPLACE FUNCTION admin_private.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT auth.uid() IS NOT NULL
    AND EXISTS (
      SELECT 1
      FROM public.profiles AS p
      WHERE p.id = auth.uid()
        AND p.role = 'admin'
    );
$function$;

ALTER FUNCTION admin_private.is_admin() OWNER TO postgres;
REVOKE ALL ON FUNCTION admin_private.is_admin()
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION admin_private.is_admin() TO authenticated;

-- 3. Applied: separate permissive Admin read policy. The existing
-- "Users can view own profile." SELECT policy (auth.uid() = id) is untouched.
DROP POLICY IF EXISTS "Admin read all profiles" ON public.profiles;
CREATE POLICY "Admin read all profiles"
ON public.profiles
AS PERMISSIVE
FOR SELECT
TO authenticated
USING ((SELECT admin_private.is_admin()));

-- 4. Applied: remove the formerly unrestricted FOR ALL / TO public /
-- USING (true) policy. Adding an Admin policy alone would not remove that access.
-- The existing public restaurant SELECT policy remains untouched.
DROP POLICY IF EXISTS "Public manage restaurants" ON public.restaurants;
DROP POLICY IF EXISTS "Admin manage restaurants" ON public.restaurants;
CREATE POLICY "Admin manage restaurants"
ON public.restaurants
AS PERMISSIVE
FOR ALL
TO authenticated
USING ((SELECT admin_private.is_admin()))
WITH CHECK ((SELECT admin_private.is_admin()));

-- Application behavior: Admin restaurant CRUD persists to Supabase and is
-- protected by the Admin mutation policy. Price/phone stay session-only because
-- the deployed restaurant table has no such columns. The signup UI may still
-- display privileged role options, but non-customer self-profile INSERT is now
-- rejected by the database under the recorded policy set. This file does not
-- modify signup UI or Auth code, grant self-role UPDATE, or provision Admins.
-- No service-role credentials are needed in Flutter; RLS remains enabled.

-- Replay safety only: the live changes recorded above remain live independently
-- of this documentation file. No database commands were run to create this file.
ROLLBACK;
