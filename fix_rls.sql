-- Fix queue_entries update policy
DROP POLICY IF EXISTS "Allow users to update own queue_entries" ON public.queue_entries;
CREATE POLICY "Allow users to update own queue_entries" 
ON public.queue_entries FOR UPDATE 
USING (auth.uid() = user_id) 
WITH CHECK (auth.uid() = user_id);

-- Make sure bookings also has an update policy (receptionist or user)
DROP POLICY IF EXISTS "Allow users to update own bookings" ON public.bookings;
CREATE POLICY "Allow users to update own bookings" 
ON public.bookings FOR UPDATE 
USING (auth.uid() = user_id) 
WITH CHECK (auth.uid() = user_id);

-- Also allow receptionists/managers to update queue and bookings (if role based)
-- For now we just ensure users can update their own.
