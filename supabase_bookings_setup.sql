-- Create bookings table
CREATE TABLE public.bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id UUID REFERENCES public.restaurants(id) NOT NULL,
    user_id UUID NOT NULL,
    booking_date TIMESTAMP WITH TIME ZONE NOT NULL,
    party_size INTEGER NOT NULL DEFAULT 1,
    status TEXT NOT NULL DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'cancelled', 'completed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

-- Policy to allow users to read their own bookings
CREATE POLICY "Users can view their own bookings" 
ON public.bookings FOR SELECT 
USING (auth.uid() = user_id);

-- Policy to allow users to insert their own bookings
CREATE POLICY "Users can create their own bookings" 
ON public.bookings FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- Policy to allow users to update their own bookings
CREATE POLICY "Users can update their own bookings" 
ON public.bookings FOR UPDATE 
USING (auth.uid() = user_id);
