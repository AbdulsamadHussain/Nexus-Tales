-- Migration: fix_multi_character_constraints
-- Applied live via MCP on 2026-05-22.
-- Fixes three issues discovered during database audit after the multi-character migration:

-- 1. canonical_state still had a UNIQUE constraint on user_id that prevented a second character
--    per user. Drop it so character_id (the true PK) is the uniqueness boundary.
ALTER TABLE public.canonical_state
  DROP CONSTRAINT IF EXISTS canonical_state_user_id_key;

-- 2. Backfill character_id on revisions rows that were created before multi-character migration.
--    Joins on user_id since those rows have exactly one canonical_state per user at that time.
UPDATE public.revisions r
SET character_id = cs.character_id
FROM public.canonical_state cs
WHERE r.user_id = cs.user_id
  AND r.character_id IS NULL;

-- 3. Backfill character_id on manual_saves rows for the same reason.
UPDATE public.manual_saves ms
SET character_id = cs.character_id
FROM public.canonical_state cs
WHERE ms.user_id = cs.user_id
  AND ms.character_id IS NULL;

-- 4. Drop the "public read campaigns" policy that leaked all campaigns to all users.
--    Replaced by the RLS policies added in migration 20260522000009.
DROP POLICY IF EXISTS "public read campaigns" ON public.campaigns;

-- 5. Drop duplicate RLS policy on canonical_state (was registered twice under different names).
DROP POLICY IF EXISTS "users read own state" ON public.canonical_state;
