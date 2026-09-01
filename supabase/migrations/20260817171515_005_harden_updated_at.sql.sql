/*
# Harden touch_updated_at with an explicit search_path

1. Purpose
   Resolves the "Function Search Path Mutable" security advisor warning by
   recreating the updated_at trigger function with an explicit, immutable
   search_path. This prevents search-path manipulation from affecting the
   trigger's behavior.

2. Changes
   - Drops and recreates `touch_updated_at` with `SET search_path = public`.
   - Existing triggers on profiles / trips / journeys / journey_participants
     continue to call it by name; no trigger changes needed.

3. Notes
   - Idempotent: CREATE OR REPLACE FUNCTION.
*/

CREATE OR REPLACE FUNCTION public.touch_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;
