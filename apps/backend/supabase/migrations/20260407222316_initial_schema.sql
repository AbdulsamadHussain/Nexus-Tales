-- ── CANONICAL STATE ──────────────────────────────────────────────
-- One row per user. The simulation service is the only writer.
create table public.canonical_state (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references auth.users(id) on delete cascade,
  schema_version  int  not null default 1,

  -- Player resources
  hp              int  not null default 40,
  hp_max          int  not null default 40,
  mp              int  not null default 20,
  mp_max          int  not null default 20,
  stamina         int  not null default 20,
  stamina_max     int  not null default 20,
  gold            int  not null default 0,
  xp              int  not null default 0,
  level           int  not null default 1,

  -- Character info
  character_name  text not null default 'Unnamed',
  character_class text not null default 'Rogue',
  origin          text not null default 'Unknown',

  -- World state
  current_location text not null default 'start',
  campaign_id      text not null default 'campaign_01',

  -- JSON blobs for flexible data
  inventory        jsonb not null default '[]',
  quest_state      jsonb not null default '{}',
  relationships    jsonb not null default '{}',
  factions         jsonb not null default '{}',
  known_lore       jsonb not null default '[]',
  content_settings jsonb not null default '{"violence":true,"horror":true,"romance":false,"mature":false}',

  updated_at      timestamptz not null default now(),
  unique(user_id)
);

-- ── REVISIONS ────────────────────────────────────────────────────
-- One row per committed player turn. Immutable after insert.
create table public.revisions (
  id                  text primary key,  -- e.g. rev_008142
  user_id             uuid not null references auth.users(id) on delete cascade,
  previous_id         text references public.revisions(id),
  schema_version      int  not null default 1,

  -- What happened
  player_action       text not null,
  route_category      text not null,
  gateway_decision    text not null,
  success_tier        text not null default 'NO_ROLL',

  -- Roll data (null if no roll)
  roll_die            int,
  roll_modifier       int,
  roll_total          int,
  roll_dc             int,

  -- State snapshot at commit time (for rollback)
  state_snapshot      jsonb not null default '{}',

  -- Post-commit flags
  events              text[]  not null default '{}',
  autosave_candidate  boolean not null default false,
  summary_job_queued  boolean not null default false,
  narration_done      boolean not null default false,

  created_at          timestamptz not null default now()
);

-- ── CANONICAL EVENTS ─────────────────────────────────────────────
-- Event log emitted by simulation service. Immutable after insert.
create table public.canonical_events (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  revision_id text not null references public.revisions(id),
  event_type  text not null,  -- COMBAT_ENDED, QUEST_UPDATED, etc.
  payload     jsonb not null default '{}',
  created_at  timestamptz not null default now()
);

-- ── CHAPTER SUMMARIES ────────────────────────────────────────────
create table public.chapter_summaries (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  revision_id text not null references public.revisions(id),
  trigger     text not null,  -- HARD or SOFT
  content     text not null,
  created_at  timestamptz not null default now()
);

-- ── INDEXES ──────────────────────────────────────────────────────
create index on public.revisions(user_id, created_at desc);
create index on public.canonical_events(user_id, revision_id);
create index on public.chapter_summaries(user_id, created_at desc);

-- ── ROW LEVEL SECURITY ───────────────────────────────────────────
-- Users can only read their own rows.
-- Writes go through Edge Functions using the service_role key, which bypasses RLS.
alter table public.canonical_state    enable row level security;
alter table public.revisions          enable row level security;
alter table public.canonical_events   enable row level security;
alter table public.chapter_summaries  enable row level security;

create policy "users read own state"
  on public.canonical_state for select
  using (auth.uid() = user_id);

create policy "users read own revisions"
  on public.revisions for select
  using (auth.uid() = user_id);

create policy "users read own events"
  on public.canonical_events for select
  using (auth.uid() = user_id);

create policy "users read own summaries"
  on public.chapter_summaries for select
  using (auth.uid() = user_id);

-- ── REALTIME ─────────────────────────────────────────────────────
-- Flutter subscribes to new revision rows to update the UI.
alter publication supabase_realtime add table public.revisions;
alter publication supabase_realtime add table public.canonical_state;