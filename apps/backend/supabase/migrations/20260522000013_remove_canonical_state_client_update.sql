-- Migration: remove_canonical_state_client_update
-- Remove the authenticated client UPDATE policy on canonical_state.
--
-- After this migration all gameplay writes go through authoritative edge functions:
--   simulation_service  — combat, movement, skills, items (via SVC_ROLE_KEY)
--   canonical_command   — BUY_ITEM, CHOOSE_SKILL, EDIT_PROFILE (JWT-verified command path)
--
-- Clients retain:
--   SELECT  — to read their own character state
--   DELETE  — to remove a character (character management screen)
--   INSERT  — removed here also; create_character edge function handles character creation
--
-- The INSERT policy is also removed because create_character uses the service role
-- and there is no other legitimate path for clients to directly INSERT into canonical_state.

DROP POLICY IF EXISTS "Users can update own characters" ON public.canonical_state;
DROP POLICY IF EXISTS "Users can insert own characters" ON public.canonical_state;
