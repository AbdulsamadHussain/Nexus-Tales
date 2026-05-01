-- Add graphic violence preference to default user content settings.
-- This keeps future user_preferences rows aligned with the client/gateway contract.

alter table public.user_preferences
alter column content_settings set default '{
  "violence": true,
  "graphic": false,
  "horror": true,
  "romance": true,
  "mature": false
}'::jsonb;


-- Backfill existing user_preferences rows that do not already have "graphic".
-- This is safe even if you already edited your current live row manually.

update public.user_preferences
set content_settings = jsonb_set(
  content_settings,
  '{graphic}',
  'false'::jsonb,
  true
)
where not (content_settings ? 'graphic');


-- Add NPC counter-attack damage.
-- Simulation reads npcs.attack_damage and falls back to 5 if missing,
-- but the schema should explicitly own the value.

alter table public.npcs
add column if not exists attack_damage int not null default 5;


-- Seed authored NPC combat damage values for campaign_01.

update public.npcs
set attack_damage = 12
where id = 'npc_plague_warden';

update public.npcs
set attack_damage = 8
where id = 'npc_mira_voss';