-- Migration: player_campaign_state_character_id
-- Applied live via MCP on 2026-05-22.
-- Fixes collision bug: two characters in the same campaign overwrote each other's
-- NPC states and scene position because the table was keyed on (user_id, campaign_id).
-- The correct key is (character_id, campaign_id).

-- 1. Add character_id column (nullable to allow backfill before constraints are added).
ALTER TABLE public.player_campaign_state
  ADD COLUMN IF NOT EXISTS character_id uuid;

-- 2. Backfill character_id from canonical_state on user_id + campaign_id match.
UPDATE public.player_campaign_state pcs
SET character_id = cs.character_id
FROM public.canonical_state cs
WHERE pcs.user_id = cs.user_id
  AND pcs.campaign_id = cs.campaign_id
  AND pcs.character_id IS NULL;

-- 3. Drop the old unique constraint that keyed on (user_id, campaign_id).
ALTER TABLE public.player_campaign_state
  DROP CONSTRAINT IF EXISTS player_campaign_state_user_id_campaign_id_key;

-- 4. Add the correct unique constraint on (character_id, campaign_id).
ALTER TABLE public.player_campaign_state
  ADD CONSTRAINT player_campaign_state_character_campaign_key
    UNIQUE (character_id, campaign_id);

-- 5. Add index on character_id for fast per-character lookups.
CREATE INDEX IF NOT EXISTS player_campaign_state_character_id_idx
  ON public.player_campaign_state (character_id);
