-- Track when a player last changed their class (once per 30 days).
alter table public.canonical_state
  add column if not exists last_class_change_at timestamptz;
