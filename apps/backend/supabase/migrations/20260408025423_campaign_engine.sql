-- ── CAMPAIGNS ────────────────────────────────────────────────────
create table public.campaigns (
  id            text primary key,  -- e.g. campaign_plague_vault
  title         text not null,
  description   text not null,
  version       int  not null default 1,
  is_active     boolean not null default true,
  created_at    timestamptz not null default now()
);

-- ── SCENES ───────────────────────────────────────────────────────
create table public.scenes (
  id              text primary key,  -- e.g. scene_vault_entrance
  campaign_id     text not null references public.campaigns(id),
  title           text not null,
  description     text not null,  -- what Gemma knows about this place
  atmosphere      text not null,  -- tone instructions for narrator
  exits           jsonb not null default '{}',  -- {direction: scene_id}
  is_start_scene  boolean not null default false
);

-- ── NPCS ─────────────────────────────────────────────────────────
create table public.npcs (
  id              text primary key,  -- e.g. npc_plague_warden
  campaign_id     text not null references public.campaigns(id),
  name            text not null,
  description     text not null,
  personality     text not null,  -- narrator instructions for voice
  hp              int  not null default 20,
  hp_max          int  not null default 20,
  faction         text,
  is_hostile      boolean not null default false,
  loot            jsonb not null default '[]'  -- items dropped on defeat
);

-- ── ITEMS ────────────────────────────────────────────────────────
create table public.items (
  id              text primary key,  -- e.g. item_cipher_scroll
  campaign_id     text not null references public.campaigns(id),
  name            text not null,
  description     text not null,
  rarity          text not null default 'common',  -- common/rare/legendary
  item_type       text not null default 'misc',    -- weapon/armor/consumable/key/misc
  effects         jsonb not null default '{}'      -- {hp_restore: 10} etc
);

-- ── SCENE ITEMS ──────────────────────────────────────────────────
-- Items that can be found in a scene
create table public.scene_items (
  id              uuid primary key default gen_random_uuid(),
  scene_id        text not null references public.scenes(id),
  item_id         text not null references public.items(id),
  find_dc         int  not null default 12,  -- difficulty to find
  quantity        int  not null default 1,
  is_hidden       boolean not null default false
);

-- ── SCENE NPCS ───────────────────────────────────────────────────
-- NPCs present in a scene
create table public.scene_npcs (
  id              uuid primary key default gen_random_uuid(),
  scene_id        text not null references public.scenes(id),
  npc_id          text not null references public.npcs(id),
  spawn_condition jsonb not null default '{}'  -- conditions for NPC to appear
);

-- ── STORY BEATS ──────────────────────────────────────────────────
-- Conditions that trigger story progression
create table public.story_beats (
  id              uuid primary key default gen_random_uuid(),
  campaign_id     text not null references public.campaigns(id),
  title           text not null,
  trigger_type    text not null,  -- EVENT, STATE_CONDITION, ITEM_ACQUIRED, NPC_DEFEATED
  trigger_data    jsonb not null default '{}',  -- what triggers this beat
  consequences    jsonb not null default '{}',  -- what happens: scene_change, item_grant, etc
  is_repeatable   boolean not null default false,
  priority        int  not null default 0  -- higher = checked first
);

-- ── PLAYER CAMPAIGN STATE ─────────────────────────────────────────
-- Tracks each player's progress through a campaign
create table public.player_campaign_state (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references auth.users(id) on delete cascade,
  campaign_id     text not null references public.campaigns(id),
  current_scene   text not null references public.scenes(id),
  beaten_beats    text[] not null default '{}',  -- story beat IDs already fired
  npc_states      jsonb not null default '{}',   -- {npc_id: {hp, is_dead, dialogue_state}}
  scene_item_states jsonb not null default '{}', -- {scene_item_id: {found, taken}}
  started_at      timestamptz not null default now(),
  last_played_at  timestamptz not null default now(),
  unique(user_id, campaign_id)
);

-- ── CHARACTER PRESETS ─────────────────────────────────────────────
create table public.character_presets (
  id              text primary key,  -- e.g. preset_shadow_rogue
  name            text not null,
  class           text not null,
  origin          text not null,
  description     text not null,
  backstory       text not null,
  hp_max          int  not null default 40,
  mp_max          int  not null default 20,
  stamina_max     int  not null default 20,
  starting_items  jsonb not null default '[]',
  skills          jsonb not null default '{}'
);

-- ── RLS ──────────────────────────────────────────────────────────
alter table public.campaigns              enable row level security;
alter table public.scenes                 enable row level security;
alter table public.npcs                   enable row level security;
alter table public.items                  enable row level security;
alter table public.scene_items            enable row level security;
alter table public.scene_npcs             enable row level security;
alter table public.story_beats            enable row level security;
alter table public.player_campaign_state  enable row level security;
alter table public.character_presets      enable row level security;

-- Public read for campaign content
create policy "public read campaigns"    on public.campaigns           for select using (true);
create policy "public read scenes"       on public.scenes              for select using (true);
create policy "public read npcs"         on public.npcs                for select using (true);
create policy "public read items"        on public.items               for select using (true);
create policy "public read scene_items"  on public.scene_items         for select using (true);
create policy "public read scene_npcs"   on public.scene_npcs          for select using (true);
create policy "public read story_beats"  on public.story_beats         for select using (true);
create policy "public read presets"      on public.character_presets   for select using (true);

-- Players read/write only their own campaign state
create policy "users read own campaign state"
  on public.player_campaign_state for select
  using (auth.uid() = user_id);

-- Realtime for campaign state
alter publication supabase_realtime add table public.player_campaign_state;