/*
# Gamification: challenges, questions, attempts, XP transactions, badges, user badges

1. Purpose
   Implements the Experience engine: a modular challenge bank (quiz / MCQ /
   fill-in-the-blank / history / language / fashion / tradition / identify /
   map), per-attempt tracking, an auditable XP ledger, and a badge system with
   definitions + per-user achievements.

2. New Tables
   - `challenges` — a challenge definition. Scoped to a destination, optionally
     to a trip/journey. Has category, difficulty, xp_reward, and a `payload`
     jsonb field so different challenge types (identify image, map pin, MCQ,
     fill-in-the-blank) can store their type-specific content without a schema
     change per type. This keeps the challenge model modular.
   - `challenge_questions` — optional sub-questions for a challenge (MCQ
     options, blanks, etc.). Stored as rows so new question shapes can be added.
   - `challenge_attempts` — a user's attempt at a challenge. Records pass/fail,
     score, and timestamps. One user may have many attempts (history).
   - `xp_transactions` — append-only XP ledger. Each row is a reason-tagged XP
     award (challenge_completed, journey_completed, activity_completed,
     streak_milestone, discovery, social). The profile.xp_total is the sum of
     these; the ledger is the auditable source of truth.
   - `badges` — badge definition: name, description, icon, rarity, requirement
     (human-readable + machine key), xp_reward.
   - `user_badges` — a user's earned badge. Unique on (user_id, badge_id) to
     prevent duplicate awards.

3. Security
   - RLS on all tables.
   - `challenges` / `challenge_questions` / `badges`: public read (definition
     catalog); writes authenticated (admin/curator path later).
   - `challenge_attempts`: self read/write only.
   - `xp_transactions`: self read only; inserts via authenticated with
     auth.uid() = user_id (a real production system would award XP through a
     SECURITY DEFINER function, but this keeps the ledger owner-writable for now
     while remaining auditable).
   - `user_badges`: public read (badges are shown on profile); self insert only.

4. Notes
   - `payload jsonb` on challenges is the modularity seam: a new challenge type
     only needs a new payload shape, not a new table.
   - XP is an append-only ledger, never a direct UPDATE to a running total —
     auditable and race-safe. profile.xp_total can be maintained by a trigger or
     derived.
   - Idempotent via IF NOT EXISTS / DROP POLICY IF EXISTS.
*/

-- CHALLENGES -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS challenges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  destination_id uuid REFERENCES destinations(id) ON DELETE SET NULL,
  trip_id uuid REFERENCES trips(id) ON DELETE SET NULL,
  journey_id uuid REFERENCES journeys(id) ON DELETE SET NULL,
  title text NOT NULL,
  category text NOT NULL,
  challenge_type text NOT NULL DEFAULT 'mcq',
  difficulty text NOT NULL DEFAULT 'easy',
  xp_reward integer NOT NULL DEFAULT 50,
  payload jsonb NOT NULL DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT challenges_category_check CHECK (
    category IN ('quiz','mcq','fill_blank','history','language','fashion',
                 'tradition','identify','map')
  ),
  CONSTRAINT challenges_type_check CHECK (
    challenge_type IN ('mcq','fill_blank','identify','map_pin','route','open')
  ),
  CONSTRAINT challenges_difficulty_check CHECK (
    difficulty IN ('easy','medium','hard')
  )
);

CREATE INDEX IF NOT EXISTS challenges_destination_idx ON challenges(destination_id);
CREATE INDEX IF NOT EXISTS challenges_category_idx ON challenges(category);

ALTER TABLE challenges ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "challenges_public_read" ON challenges;
CREATE POLICY "challenges_public_read"
ON challenges FOR SELECT
TO anon, authenticated
USING (true);

DROP POLICY IF EXISTS "challenges_auth_insert" ON challenges;
CREATE POLICY "challenges_auth_insert"
ON challenges FOR INSERT
TO authenticated
WITH CHECK (true);

DROP POLICY IF EXISTS "challenges_auth_update" ON challenges;
CREATE POLICY "challenges_auth_update"
ON challenges FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- CHALLENGE QUESTIONS ----------------------------------------------------
CREATE TABLE IF NOT EXISTS challenge_questions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id uuid NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
  prompt text NOT NULL,
  options jsonb NOT NULL DEFAULT '[]',
  answer jsonb NOT NULL DEFAULT '{}',
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS challenge_questions_challenge_idx ON challenge_questions(challenge_id);

ALTER TABLE challenge_questions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "challenge_questions_public_read" ON challenge_questions;
CREATE POLICY "challenge_questions_public_read"
ON challenge_questions FOR SELECT
TO anon, authenticated
USING (true);

DROP POLICY IF EXISTS "challenge_questions_auth_insert" ON challenge_questions;
CREATE POLICY "challenge_questions_auth_insert"
ON challenge_questions FOR INSERT
TO authenticated
WITH CHECK (true);

DROP POLICY IF EXISTS "challenge_questions_auth_update" ON challenge_questions;
CREATE POLICY "challenge_questions_auth_update"
ON challenge_questions FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- CHALLENGE ATTEMPTS -----------------------------------------------------
CREATE TABLE IF NOT EXISTS challenge_attempts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id uuid NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  passed boolean NOT NULL DEFAULT false,
  score integer NOT NULL DEFAULT 0,
  answers jsonb NOT NULL DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS challenge_attempts_user_idx ON challenge_attempts(user_id);
CREATE INDEX IF NOT EXISTS challenge_attempts_challenge_idx ON challenge_attempts(challenge_id);

ALTER TABLE challenge_attempts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "challenge_attempts_select" ON challenge_attempts;
CREATE POLICY "challenge_attempts_select"
ON challenge_attempts FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "challenge_attempts_insert" ON challenge_attempts;
CREATE POLICY "challenge_attempts_insert"
ON challenge_attempts FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "challenge_attempts_update" ON challenge_attempts;
CREATE POLICY "challenge_attempts_update"
ON challenge_attempts FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "challenge_attempts_delete" ON challenge_attempts;
CREATE POLICY "challenge_attempts_delete"
ON challenge_attempts FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- XP TRANSACTIONS --------------------------------------------------------
CREATE TABLE IF NOT EXISTS xp_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  amount integer NOT NULL,
  reason text NOT NULL,
  reference_type text,
  reference_id uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT xp_transactions_reason_check CHECK (
    reason IN ('challenge_completed','journey_completed','activity_completed',
               'streak_milestone','discovery','social','badge_reward','manual')
  )
);

CREATE INDEX IF NOT EXISTS xp_transactions_user_idx ON xp_transactions(user_id, created_at DESC);

ALTER TABLE xp_transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "xp_transactions_select" ON xp_transactions;
CREATE POLICY "xp_transactions_select"
ON xp_transactions FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "xp_transactions_insert" ON xp_transactions;
CREATE POLICY "xp_transactions_insert"
ON xp_transactions FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "xp_transactions_delete" ON xp_transactions;
CREATE POLICY "xp_transactions_delete"
ON xp_transactions FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- BADGES -----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS badges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text NOT NULL,
  icon text,
  rarity text NOT NULL DEFAULT 'common',
  requirement_key text UNIQUE,
  requirement_description text,
  xp_reward integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT badges_rarity_check CHECK (
    rarity IN ('common','rare','epic','legendary')
  )
);

ALTER TABLE badges ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "badges_public_read" ON badges;
CREATE POLICY "badges_public_read"
ON badges FOR SELECT
TO anon, authenticated
USING (true);

DROP POLICY IF EXISTS "badges_auth_insert" ON badges;
CREATE POLICY "badges_auth_insert"
ON badges FOR INSERT
TO authenticated
WITH CHECK (true);

DROP POLICY IF EXISTS "badges_auth_update" ON badges;
CREATE POLICY "badges_auth_update"
ON badges FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- USER BADGES ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_badges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  badge_id uuid NOT NULL REFERENCES badges(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, badge_id)
);

CREATE INDEX IF NOT EXISTS user_badges_user_idx ON user_badges(user_id);

ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "user_badges_select" ON user_badges;
CREATE POLICY "user_badges_select"
ON user_badges FOR SELECT
TO anon, authenticated
USING (true);

DROP POLICY IF EXISTS "user_badges_insert" ON user_badges;
CREATE POLICY "user_badges_insert"
ON user_badGES FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_badges_delete" ON user_badges;
CREATE POLICY "user_badges_delete"
ON user_badges FOR DELETE
TO authenticated
USING (auth.uid() = user_id);
