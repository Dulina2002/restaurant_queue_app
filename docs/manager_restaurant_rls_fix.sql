-- Fix for Manager/Admin restaurant creation Row-Level Security (RLS) error:
-- "PostgrestException(message: new row violates row-level security policy for table "restaurants", code: 42501, details: Unauthorized)"
--
-- Choose either OPTION 1 (Authenticated Managers & Admins) or OPTION 2 (Demo/Public mode).

-- ============================================================================
-- OPTION 1 (RECOMMENDED): Authorize both 'manager' and 'admin' roles
-- Run this in the Supabase SQL Editor if users sign in with Supabase Auth accounts.
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS admin_private AUTHORIZATION postgres;
GRANT USAGE ON SCHEMA admin_private TO authenticated;

CREATE OR REPLACE FUNCTION admin_private.is_admin_or_manager()
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
        AND p.role IN ('admin', 'manager')
    );
$function$;

ALTER FUNCTION admin_private.is_admin_or_manager() OWNER TO postgres;
REVOKE ALL ON FUNCTION admin_private.is_admin_or_manager() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION admin_private.is_admin_or_manager() TO authenticated;

-- Replace the Admin-only policy with a Staff policy covering Managers & Admins
DROP POLICY IF EXISTS "Admin manage restaurants" ON public.restaurants;
DROP POLICY IF EXISTS "Staff manage restaurants" ON public.restaurants;

CREATE POLICY "Staff manage restaurants"
ON public.restaurants
AS PERMISSIVE
FOR ALL
TO authenticated
USING ((SELECT admin_private.is_admin_or_manager()))
WITH CHECK ((SELECT admin_private.is_admin_or_manager()));

-- Ensure public can read active restaurants
DROP POLICY IF EXISTS "Public read restaurants" ON public.restaurants;
CREATE POLICY "Public read restaurants"
ON public.restaurants
AS PERMISSIVE
FOR SELECT
TO public
USING (true);


-- ============================================================================
-- OPTION 2 (DEMO / DEVELOPMENT MODE): Allow unrestricted restaurant management
-- Run this in the Supabase SQL Editor if using fixed demo staff accounts
-- or quick-launching where auth.uid() is null (anonymous client session).
-- ============================================================================
--
-- DROP POLICY IF EXISTS "Admin manage restaurants" ON public.restaurants;
-- DROP POLICY IF EXISTS "Staff manage restaurants" ON public.restaurants;
-- DROP POLICY IF EXISTS "Public manage restaurants" ON public.restaurants;
--
-- CREATE POLICY "Public manage restaurants"
-- ON public.restaurants
-- AS PERMISSIVE
-- FOR ALL
-- TO public
-- USING (true)
-- WITH CHECK (true);
