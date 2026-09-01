/*
# Auto-generate notifications on social interactions

1. Purpose
   When a user likes a trip, saves a trip, or follows another user, automatically
   create a notification for the trip owner or followed user. This makes the
   notification bell show real, live activity without the frontend having to
   manually insert notification rows.

2. New Functions
   - `notify_trip_liked()` — AFTER INSERT on trip_likes: inserts a notification
     for the trip's owner with type 'trip_liked'.
   - `notify_trip_saved()` — AFTER INSERT on trip_saves: inserts a notification
     for the trip's owner with type 'trip_saved'.
   - `notify_user_followed()` — AFTER INSERT on user_follows: inserts a
     notification for the followed user with type 'follow'.

3. New Triggers
   - on_trip_liked, on_trip_saved, on_user_followed — fire AFTER INSERT on the
     respective tables.

4. Security
   - All functions are SECURITY DEFINER so they can insert into notifications
     even though the acting user doesn't own the recipient's notification rows.
   - search_path locked to public.
   - Functions check that the actor is not the same as the recipient to avoid
     self-notifications.

5. Notes
   - Idempotent: CREATE OR REPLACE FUNCTION + DROP TRIGGER IF EXISTS.
   - Notifications include the actor_id and a human-readable message with the
     actor's display name, resolved at insert time so the message is stable.
*/

CREATE OR REPLACE FUNCTION public.notify_trip_liked()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  trip_owner uuid;
  actor_name text;
BEGIN
  SELECT user_id INTO trip_owner FROM trips WHERE id = NEW.trip_id;
  IF trip_owner IS NULL OR trip_owner = NEW.user_id THEN
    RETURN NEW;
  END IF;
  SELECT display_name INTO actor_name FROM profiles WHERE id = NEW.user_id;
  INSERT INTO notifications (user_id, actor_id, type, reference_type, reference_id, message)
  VALUES (
    trip_owner,
    NEW.user_id,
    'trip_liked',
    'trip',
    NEW.trip_id,
    COALESCE(actor_name, 'Someone') || ' liked your trip'
  )
  ON CONFLICT DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_trip_liked ON trip_likes;
CREATE TRIGGER on_trip_liked
  AFTER INSERT ON trip_likes
  FOR EACH ROW EXECUTE FUNCTION public.notify_trip_liked();

CREATE OR REPLACE FUNCTION public.notify_trip_saved()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  trip_owner uuid;
  actor_name text;
BEGIN
  SELECT user_id INTO trip_owner FROM trips WHERE id = NEW.trip_id;
  IF trip_owner IS NULL OR trip_owner = NEW.user_id THEN
    RETURN NEW;
  END IF;
  SELECT display_name INTO actor_name FROM profiles WHERE id = NEW.user_id;
  INSERT INTO notifications (user_id, actor_id, type, reference_type, reference_id, message)
  VALUES (
    trip_owner,
    NEW.user_id,
    'trip_saved',
    'trip',
    NEW.trip_id,
    COALESCE(actor_name, 'Someone') || ' saved your trip'
  )
  ON CONFLICT DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_trip_saved ON trip_saves;
CREATE TRIGGER on_trip_saved
  AFTER INSERT ON trip_saves
  FOR EACH ROW EXECUTE FUNCTION public.notify_trip_saved();

CREATE OR REPLACE FUNCTION public.notify_user_followed()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  actor_name text;
BEGIN
  IF NEW.following_id = NEW.follower_id THEN
    RETURN NEW;
  END IF;
  SELECT display_name INTO actor_name FROM profiles WHERE id = NEW.follower_id;
  INSERT INTO notifications (user_id, actor_id, type, message)
  VALUES (
    NEW.following_id,
    NEW.follower_id,
    'follow',
    COALESCE(actor_name, 'Someone') || ' started following you'
  )
  ON CONFLICT DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_user_followed ON user_follows;
CREATE TRIGGER on_user_followed
  AFTER INSERT ON user_follows
  FOR EACH ROW EXECUTE FUNCTION public.notify_user_followed();
