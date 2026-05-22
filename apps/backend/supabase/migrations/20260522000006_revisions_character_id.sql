alter table public.revisions
  add column if not exists character_id uuid;

create index if not exists revisions_character_id_idx on public.revisions(character_id);
