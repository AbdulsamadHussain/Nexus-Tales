alter table public.canonical_state
  add column if not exists turns_since_last_summary int not null default 0;

alter table public.canonical_state
  add column if not exists last_summary_type text;

alter table public.canonical_state
  add column if not exists hard_summary_cooldown int not null default 0;buildNarrationContext