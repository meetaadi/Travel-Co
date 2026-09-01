/*
# Core schema: profiles, destinations, places, trips, trip days, activities

1. Purpose
   Lays the foundation for roamwell: user profiles, geographic reference data
   (destinations + places), and the trip/itinerary model (trips -> trip_days ->
   activities). This is the backbone the journey, social, and gamification layers
   build on.

2. New Tables
   - `profiles` — public user profile (1:1 with auth.users). Stores handle,
     display name, avatar, home base, and bio. NOT the auth account itself.
   - `destinations` — curated geographic areas (city / region / coast). Used to
     group places and to scope trips and challenges.
   - `places` — points of interest (landmarks, restaurants, viewpoints).
     Optional destination + coordinates + opening hours + local tip.
   - `trips` — a travel plan created by a user. Has type (Day trip / Long
     weekend / Vacay), duration, budget, status (draft / published), and
     references a destination. Owned by a user (user_id defaults to auth.uid()).
   - `trip_days` — a day within a trip (ordered). Belongs to one trip.
   - `activities` — a time-blocked activity within a day. References an
     optional place, has start/end time, cost, category, notes, transport,
     coordinates, images, and a local tip.

3. Security
   - RLS enabled on every table.
   - `profiles`: public read of published profile data; self write only.
   - `destinations` / `places`: public read (curated reference data); writes
     restricted to authenticated users (admin path later).
   - `trips`: SELECT visible to all when status='published', otherwise owner
     only. INSERT/UPDATE/DELETE owner only (user_id DEFAULT auth.uid()).
   - `trip_days` / `activities`: access scoped through parent trip ownership
     (EXISTS check against trips.user_id). No direct user_id column on children.

4. Notes
   - `user_id uuid NOT NULL DEFAULT auth.uid()` on trips so frontend inserts
     that omit user_id succeed under RLS.
   - Child tables (trip_days, activities) do NOT have user_id; policy uses
     EXISTS (...) against the parent trip.
   - Idempotent: uses IF NOT EXISTS / DROP POLICY IF EXISTS so re-runs are safe.
*/

-- PROFILES ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  handle text UNIQUE NOT NULL,
  display_name text NOT NULL,
  avatar_url text,
  home_base text,
  bio text,
  xp_total integer NOT NULL DEFAULT 0,
  explorer_level integer NOT NULL DEFAULT 1,
  streak_days integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "profiles_public_read" ON profiles;
CREATE POLICY "profiles_public_read"
ON profiles FOR SELECT
TO anon, authenticated
USING (true);

DROP POLICY IF EXISTS "profiles_self_insert" ON profiles;
CREATE POLICY "profiles_self_insert"
ON profiles FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "profiles_self_update" ON profiles;
CREATE POLICY "profiles_self_update"
ON profiles FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- DESTINATIONS -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS destinations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  country text NOT NULL,
  slug text UNIQUE NOT NULL,
  blurb text,
  cover_image text,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE destinations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "destinations_public_read" ON destinations;
CREATE POLICY "destinations_public_read"
ON destinations FOR SELECT
TO anon, authenticated
USING (true);

DROP POLICY IF EXISTS "destinations_auth_insert" ON destinations;
CREATE POLICY "destinations_auth_insert"
ON destinations FOR INSERT
TO authenticated
WITH CHECK (true);

DROP POLICY IF EXISTS "destinations_auth_update" ON destinations;
CREATE POLICY "destinations_auth_update"
ON destinations FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- PLACES -----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS places (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  destination_id uuid REFERENCES destinations(id) ON DELETE SET NULL,
  name text NOT NULL,
  category text,
  latitude double precision,
  longitude double precision,
  opening_hours jsonb,
  local_tip text,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE places ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "places_public_read" ON places;
CREATE POLICY "places_public_read"
ON places FOR SELECT
TO anon, authenticated
USING (true);

DROP POLICY IF EXISTS "places_auth_insert" ON places;
CREATE POLICY "places_auth_insert"
ON places FOR INSERT
TO authenticated
WITH CHECK (true);

DROP POLICY IF EXISTS "places_auth_update" ON places;
CREATE POLICY "places_auth_update"
ON places FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- TRIPS ------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS trips (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  destination_id uuid REFERENCES destinations(id) ON DELETE SET NULL,
  title text NOT NULL,
  type text NOT NULL DEFAULT 'Long weekend',
  duration_days integer NOT NULL DEFAULT 3,
  budget_text text,
  travelers integer NOT NULL DEFAULT 2,
  blurb text,
  cover_image text,
  status text NOT NULL DEFAULT 'draft',
  experiences text[] NOT NULL DEFAULT '{}',
  local_note text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT trips_status_check CHECK (status IN ('draft','published','archived')),
  CONSTRAINT trips_type_check CHECK (type IN ('Day trip','Long weekend','Vacay'))
);

CREATE INDEX IF NOT EXISTS trips_status_created_idx ON trips(status, created_at DESC);
CREATE INDEX IF NOT EXISTS trips_user_idx ON trips(user_id);

ALTER TABLE trips ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "trips_select" ON trips;
CREATE POLICY "trips_select"
ON trips FOR SELECT
TO anon, authenticated
USING (status = 'published' OR auth.uid() = user_id);

DROP POLICY IF EXISTS "trips_insert" ON trips;
CREATE POLICY "trips_insert"
ON trips FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "trips_update" ON trips;
CREATE POLICY "trips_update"
ON trips FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "trips_delete" ON trips;
CREATE POLICY "trips_delete"
ON trips FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- TRIP DAYS --------------------------------------------------------------
CREATE TABLE IF NOT EXISTS trip_days (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id uuid NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  day_index integer NOT NULL DEFAULT 1,
  label text,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (trip_id, day_index)
);

CREATE INDEX IF NOT EXISTS trip_days_trip_idx ON trip_days(trip_id);

ALTER TABLE trip_days ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "trip_days_select" ON trip_days;
CREATE POLICY "trip_days_select"
ON trip_days FOR SELECT
TO anon, authenticated
USING (
  EXISTS (
    SELECT 1 FROM trips
    WHERE trips.id = trip_days.trip_id
      AND (trips.status = 'published' OR trips.user_id = auth.uid())
  )
);

DROP POLICY IF EXISTS "trip_days_insert" ON trip_days;
CREATE POLICY "trip_days_insert"
ON trip_days FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM trips
    WHERE trips.id = trip_days.trip_id
      AND trips.user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "trip_days_update" ON trip_days;
CREATE POLICY "trip_days_update"
ON trip_days FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM trips
    WHERE trips.id = trip_days.trip_id
      AND trips.user_id = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM trips
    WHERE trips.id = trip_days.trip_id
      AND trips.user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "trip_days_delete" ON trip_days;
CREATE POLICY "trip_days_delete"
ON trip_days FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM trips
    WHERE trips.id = trip_days.trip_id
      AND trips.user_id = auth.uid()
  )
);

-- ACTIVITIES -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS activities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_day_id uuid NOT NULL REFERENCES trip_days(id) ON DELETE CASCADE,
  place_id uuid REFERENCES places(id) ON DELETE SET NULL,
  title text NOT NULL,
  start_time time,
  end_time time,
  category text,
  description text,
  cost_text text,
  transport text,
  notes text,
  latitude double precision,
  longitude double precision,
  images text[] NOT NULL DEFAULT '{}',
  local_tip text,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS activities_day_idx ON activities(trip_day_id);

ALTER TABLE activities ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "activities_select" ON activities;
CREATE POLICY "activities_select"
ON activities FOR SELECT
TO anon, authenticated
USING (
  EXISTS (
    SELECT 1 FROM trip_days
    JOIN trips ON trips.id = trip_days.trip_id
    WHERE trip_days.id = activities.trip_day_id
      AND (trips.status = 'published' OR trips.user_id = auth.uid())
  )
);

DROP POLICY IF EXISTS "activities_insert" ON activities;
CREATE POLICY "activities_insert"
ON activities FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM trip_days
    JOIN trips ON trips.id = trip_days.trip_id
    WHERE trip_days.id = activities.trip_day_id
      AND trips.user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "activities_update" ON activities;
CREATE POLICY "activities_update"
ON activities FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM trip_days
    JOIN trips ON trips.id = trip_days.trip_id
    WHERE trip_days.id = activities.trip_day_id
      AND trips.user_id = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM trip_days
    JOIN trips ON trips.id = trip_days.trip_id
    WHERE trip_days.id = activities.trip_day_id
      AND trips.user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "activities_delete" ON activities;
CREATE POLICY "activities_delete"
ON activities FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM trip_days
    JOIN trips ON trips.id = trip_days.trip_id
    WHERE trip_days.id = activities.trip_day_id
      AND trips.user_id = auth.uid()
  )
);
