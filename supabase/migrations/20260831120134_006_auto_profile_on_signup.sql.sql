/*
# Auto-create profile on signup

1. Purpose
   When a new user signs up via Supabase Auth, automatically create a matching
   row in `profiles` so the profile always exists before the frontend tries to
   read or update it. This avoids the "profile not found" race after signup.

2. New Function
   - `handle_new_user()` — SECURITY DEFINER function that inserts a profile row
     using the new auth user's id, email-derived handle, and display name.

3. New Trigger
   - `on_auth_user_created` — fires AFTER INSERT on `auth.users`, calls
     `handle_new_user()`.

4. Security
   - Function is SECURITY DEFINER so it can write to `profiles` even though the
     anon/authenticated role normally can't INSERT into a table owned by the
     postgres role. search_path is locked to `public` to satisfy the linter.
   - The handle is derived from the email local-part with a random suffix to
     keep the UNIQUE constraint satisfied. Users can change it later.

5. Notes
   - Idempotent: CREATE OR REPLACE FUNCTION + DROP TRIGGER IF EXISTS.
*/

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  base_handle text;
  suffix text;
BEGIN
  base_handle := split_part(new.email, '@', 1);
  suffix := substr(md5(random()::text), 1, 4);
  INSERT INTO profiles (id, handle, display_name)
  VALUES (
    new.id,
    base_handle || '_' || suffix,
    split_part(new.email, '@', 1)
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
