-- Store character backstory to enrich the AI narrator's system prompt.
alter table public.canonical_state
  add column if not exists backstory text not null default '';
