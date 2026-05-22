alter table public.canonical_state
  add column if not exists turn_count integer not null default 0;
