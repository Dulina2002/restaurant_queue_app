-- Migration: Add image_url column to public.restaurants
-- Run this script in the Supabase SQL Editor to support restaurant image URLs in the backend database.

ALTER TABLE public.restaurants ADD COLUMN IF NOT EXISTS image_url text;
