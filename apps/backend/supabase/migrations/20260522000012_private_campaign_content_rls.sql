-- Migration: private_campaign_content_rls
-- Drop the unrestricted public-read SELECT policies on all campaign content tables.
-- Replace them with scoped policies permitting access only when the parent campaign is:
--   (a) system-owned  — campaigns.user_id IS NULL
--   (b) owned by the authenticated user — campaigns.user_id = auth.uid()
--   (c) custom and public — is_custom = true AND is_public = true
--
-- For junction tables (scene_items, scene_npcs), visibility is enforced through
-- the linked scene's campaign because those tables have no direct campaign_id column.

-- ── SCENES ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "public read scenes" ON public.scenes;
CREATE POLICY "campaign content read scenes"
  ON public.scenes FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.campaigns c
      WHERE c.id = scenes.campaign_id
        AND (
          c.user_id IS NULL
          OR c.user_id = auth.uid()
          OR (c.is_custom = true AND c.is_public = true)
        )
    )
  );

-- ── NPCS ────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "public read npcs" ON public.npcs;
CREATE POLICY "campaign content read npcs"
  ON public.npcs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.campaigns c
      WHERE c.id = npcs.campaign_id
        AND (
          c.user_id IS NULL
          OR c.user_id = auth.uid()
          OR (c.is_custom = true AND c.is_public = true)
        )
    )
  );

-- ── ITEMS ────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "public read items" ON public.items;
CREATE POLICY "campaign content read items"
  ON public.items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.campaigns c
      WHERE c.id = items.campaign_id
        AND (
          c.user_id IS NULL
          OR c.user_id = auth.uid()
          OR (c.is_custom = true AND c.is_public = true)
        )
    )
  );

-- ── SCENE_ITEMS (visibility through the linked scene's campaign) ─────
DROP POLICY IF EXISTS "public read scene_items" ON public.scene_items;
CREATE POLICY "campaign content read scene_items"
  ON public.scene_items FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.scenes s
      JOIN public.campaigns c ON c.id = s.campaign_id
      WHERE s.id = scene_items.scene_id
        AND (
          c.user_id IS NULL
          OR c.user_id = auth.uid()
          OR (c.is_custom = true AND c.is_public = true)
        )
    )
  );

-- ── SCENE_NPCS (visibility through the linked scene's campaign) ──────
DROP POLICY IF EXISTS "public read scene_npcs" ON public.scene_npcs;
CREATE POLICY "campaign content read scene_npcs"
  ON public.scene_npcs FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.scenes s
      JOIN public.campaigns c ON c.id = s.campaign_id
      WHERE s.id = scene_npcs.scene_id
        AND (
          c.user_id IS NULL
          OR c.user_id = auth.uid()
          OR (c.is_custom = true AND c.is_public = true)
        )
    )
  );

-- ── STORY_BEATS ──────────────────────────────────────────────────────
DROP POLICY IF EXISTS "public read story_beats" ON public.story_beats;
CREATE POLICY "campaign content read story_beats"
  ON public.story_beats FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.campaigns c
      WHERE c.id = story_beats.campaign_id
        AND (
          c.user_id IS NULL
          OR c.user_id = auth.uid()
          OR (c.is_custom = true AND c.is_public = true)
        )
    )
  );
