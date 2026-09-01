/*
# Journey + social system: journeys, participants, follows, likes, saves

1. Purpose
   Turns a trip plan into a live journey with a state lifecycle, and adds the
   social graph (follows) and trip interactions (likes / saves / join requests)
   that the Home feed and Profile pages rely on.

2. New Tables
   - `journeys` — a trip that has been "started" by its owner. Lifecycle states:
     planned -> started -> in_progress -> completed (plus cancelled). References
     the source trip. Tracks start/finish timestamps. Owned by user.
   - `journey_participants` — users who requested to join or were accepted onto
     someone else's journey. Status: pending / accepted / declined / left.
     Unique on (journey_id, user_id) to prevent duplicate join requests.
   - `user_follows` — directed follow relationship (follower -> following).
     Unique on (follower_id, following_id) to prevent duplicate follows.
   - `trip_likes` — like relationship (user -> trip). Unique on (user_id, trip_id)
     to prevent duplicate likes.
   - `trip_saves` — save/bookmark relationship (user -> trip). Unique on
     (user_id, trip_id) to prevent duplicate saves.

3. Security
   - RLS on all tables.
   - `journeys`: SELECT visible to all when state IN ('started','in_progress',
     'completed') OR owner; write owner only.
   - `journey_participants`: participant or journey owner can SELECT; inserts are
     self-service (a user can request to join); updates/deletes restricted to
     the participant themselves or the journey owner.
   - `user_follows`: public read (social graph is visible); insert/delete self
     only (follower_id = auth.uid()).
   - `trip_likes` / `trip_saves`: public read (counts are public); insert/delete
     self only. Self-serve so any authenticated user can like/save a published
     trip.

4. Notes
   - Likes/saves are real persisted rows, not frontend state. Counts come from
     COUNT(*) over these tables.
   - Unique constraints enforce no duplicate likes / follows / join requests at
     the database level (race-safe).
   - Idempotent via IF NOT EXISTS / DROP POLICY IF EXISTS.
*/

-- JOURNEYS ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS journeys (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id uuid NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  state text NOT NULL DEFAULT 'planned',
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT journeys_state_check CHECK (
    state IN ('planned','started','in_progress','completed','cancelled')
  )
);

CREATE INDEX IF NOT EXISTS journeys_user_idx ON journeys(user_id);
CREATE INDEX IF NOT EXISTS journeys_state_idx ON journeys(state);

ALTER TABLE journeys ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "journeys_select" ON journeys;
CREATE POLICY "journeys_select"
ON journeys FOR SELECT
TO anon, authenticated
USING (
  state IN ('started','in_progress','completed') OR auth.uid() = user_id
);

DROP POLICY IF EXISTS "journeys_insert" ON journeys;
CREATE POLICY "journeys_insert"
ON journeys FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "journeys_update" ON journeys;
CREATE POLICY "journeys_update"
ON journeys FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "journeys_delete" ON journeys;
CREATE POLICY "journeys_delete"
ON journeys FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- JOURNEY PARTICIPANTS ---------------------------------------------------
CREATE TABLE IF NOT EXISTS journey_participants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  journey_id uuid NOT NULL REFERENCES journeys(id) ON DELETE CASCADE,
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'pending',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (journey_id, user_id),
  CONSTRAINT journey_participants_status_check CHECK (
    status IN ('pending','accepted','declined','left')
  )
);

CREATE INDEX IF NOT EXISTS journey_participants_journey_idx ON journey_participants(journey_id);
CREATE INDEX IF NOT EXISTS journey_participants_user_idx ON journey_participants(user_id);

ALTER TABLE journey_participants ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "journey_participants_select" ON journey_participants;
CREATE POLICY "journey_participants_select"
ON journey_participants FOR SELECT
TO authenticated
USING (
  user_id = auth.uid()
  OR EXISTS (
    SELECT 1 FROM journeys
    WHERE journeys.id = journey_participants.journey_id
      AND journeys.user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "journey_participants_insert" ON journey_participants;
CREATE POLICY "journey_participants_insert"
ON journey_participants FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "journey_participants_update" ON journey_participants;
CREATE POLICY "journey_participants_update"
ON journey_participants FOR UPDATE
TO authenticated
USING (
  user_id = auth.uid()
  OR EXISTS (
    SELECT 1 FROM journeys
    WHERE journeys.id = journey_participants.journey_id
      AND journeys.user_id = auth.uid()
  )
)
WITH CHECK (
  user_id = auth.uid()
  OR EXISTS (
    SELECT 1 FROM journeys
    WHERE journeys.id = journey_participants.journey_id
      AND journeys.user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "journey_participants_delete" ON journey_participants;
CREATE POLICY "journey_participants_delete"
ON journey_participants FOR DELETE
TO authenticated
USING (
  user_id = auth.uid()
  OR EXISTS (
    SELECT 1 FROM journeys
    WHERE journeys.id = journey_participants.journey_id
      AND journeys.user_id = auth.uid()
  )
);

-- USER FOLLOWS -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_follows (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  following_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (follower_id, following_id),
  CONSTRAINT no_self_follow CHECK (follower_id <> following_id)
);

CREATE INDEX IF NOT EXISTS user_follows_following_idx ON user_follows(following_id);
CREATE INDEX IF NOT EXISTS user_follows_follower_idx ON user_follows(follower_id);

ALTER TABLE user_follows ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "user_follows_select" ON user_follows;
CREATE POLICY "user_follows_select"
ON user_follows FOR SELECT
TO anon, authenticated
USING (true);

DROP POLICY IF EXISTS "user_follows_insert" ON user_follows;
CREATE POLICY "user_follows_insert"
ON user_follows FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = follower_id);

DROP POLICY IF EXISTS "user_follows_delete" ON user_follows;
CREATE POLICY "user_follows_delete"
ON user_follows FOR DELETE
TO authenticated
USING (auth.uid() = follower_id);

-- TRIP LIKES -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS trip_likes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  trip_id uuid NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, trip_id)
);

CREATE INDEX IF NOT EXISTS trip_likes_trip_idx ON trip_likes(trip_id);
CREATE INDEX IF NOT EXISTS trip_likes_user_idx ON trip_likes(user_id);

ALTER TABLE trip_likes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "trip_likes_select" ON trip_likes;
CREATE POLICY "trip_likes_select"
ON trip_likes FOR SELECT
TO anon, authenticated
USING (true);

DROP POLICY IF EXISTS "trip_likes_insert" ON trip_likes;
CREATE POLICY "trip_likes_insert"
ON trip_likes FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "trip_likes_delete" ON trip_likes;
CREATE POLICY "trip_likes_delete"
ON trip_likes FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- TRIP SAVES -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS trip_saves (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  trip_id uuid NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, trip_id)
);

CREATE INDEX IF NOT EXISTS trip_saves_trip_idx ON trip_saves(trip_id);
CREATE INDEX IF NOT EXISTS trip_saves_user_idx ON trip_saves(user_id);

ALTER TABLE trip_saves ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "trip_saves_select" ON trip_saves;
CREATE POLICY "trip_saves_select"
ON trip_saves FOR SELECT
TO anon, authenticated
USING (true);

DROP POLICY IF EXISTS "trip_saves_insert" ON trip_saves;
CREATE POLICY "trip_saves_insert"
ON trip_saves FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "trip_saves_delete" ON trip_saves;
CREATE POLICY "trip_saves_delete"
ON trip_saves FOR DELETE
TO authenticated
USING (auth.uid() = user_id);
