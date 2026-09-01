/*
# Notifications + analytics events + updated_at triggers

1. Purpose
   Adds a persisted notification inbox (so social/gamification events survive
   reloads) and a generic analytics event sink (so product analytics can later
   measure trip creation, journey completion, challenge completion, retention,
   etc. without hard-coding analytics calls throughout the UI). Also installs a
   reusable updated_at trigger so profile/trip/journey rows keep their
   updated_at fresh.

2. New Tables
   - `notifications` — a persisted notification for a user. Has type
     (follow / trip_liked / journey_join_request / journey_joined /
     journey_update / badge_earned / challenge_completed), an actor (the user
     who caused it), an optional reference (trip/journey/challenge/badge), a
     message, and a read flag. Scoped to a recipient user_id.
   - `analytics_events` — a generic event sink: user, event name, properties
     jsonb, timestamp. Single table so analytics logic stays out of UI code.

3. New Functions / Triggers
   - `touch_updated_at()` — sets NEW.updated_at = now() on any row that has an
     updated_at column.
   - Triggers on profiles, trips, journeys, journey_participants so their
     updated_at auto-refreshes on UPDATE.

4. Security
   - RLS on both new tables.
   - `notifications`: recipient can read/update (mark read) their own; inserts
     self-service for now (a production system would create notifications from a
     SECURITY DEFINER function or edge function, but this keeps the inbox
     owner-writable). Deletes self only.
   - `analytics_events`: self insert only; self read only. Public aggregation
     would happen server-side later.

5. Notes
   - Notifications are persisted, not generated in the frontend — required by
     the spec.
   - Analytics is a single sink table with a jsonb properties column so new
     events can be added without schema changes.
   - Idempotent via IF NOT EXISTS / DROP POLICY IF EXISTS / DROP TRIGGER IF EXISTS.
*/

-- NOTIFICATIONS ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  actor_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  type text NOT NULL,
  reference_type text,
  reference_id uuid,
  message text,
  read boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT notifications_type_check CHECK (
    type IN ('follow','trip_liked','trip_saved','journey_join_request',
             'journey_joined','journey_update','badge_earned',
             'challenge_completed','journey_started','journey_completed')
  )
);

CREATE INDEX IF NOT EXISTS notifications_user_idx ON notifications(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS notifications_unread_idx ON notifications(user_id) WHERE read = false;

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "notifications_select" ON notifications;
CREATE POLICY "notifications_select"
ON notifications FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "notifications_insert" ON notifications;
CREATE POLICY "notifications_insert"
ON notifications FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "notifications_update" ON notifications;
CREATE POLICY "notifications_update"
ON notifications FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "notifications_delete" ON notifications;
CREATE POLICY "notifications_delete"
ON notifications FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- ANALYTICS EVENTS -------------------------------------------------------
CREATE TABLE IF NOT EXISTS analytics_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  event_name text NOT NULL,
  properties jsonb NOT NULL DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS analytics_events_user_idx ON analytics_events(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS analytics_events_name_idx ON analytics_events(event_name);

ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "analytics_events_select" ON analytics_events;
CREATE POLICY "analytics_events_select"
ON analytics_events FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "analytics_events_insert" ON analytics_events;
CREATE POLICY "analytics_events_insert"
ON analytics_events FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "analytics_events_delete" ON analytics_events;
CREATE POLICY "analytics_events_delete"
ON analytics_events FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- UPDATED_AT TRIGGER -----------------------------------------------------
CREATE OR REPLACE FUNCTION touch_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS profiles_updated_at ON profiles;
CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

DROP TRIGGER IF EXISTS trips_updated_at ON trips;
CREATE TRIGGER trips_updated_at
  BEFORE UPDATE ON trips
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

DROP TRIGGER IF EXISTS journeys_updated_at ON journeys;
CREATE TRIGGER journeys_updated_at
  BEFORE UPDATE ON journeys
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

DROP TRIGGER IF EXISTS journey_participants_updated_at ON journey_participants;
CREATE TRIGGER journey_participants_updated_at
  BEFORE UPDATE ON journey_participants
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
