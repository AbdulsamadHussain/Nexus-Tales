alter table public.canonical_state 
  add column if not exists skills jsonb not null default '{}';