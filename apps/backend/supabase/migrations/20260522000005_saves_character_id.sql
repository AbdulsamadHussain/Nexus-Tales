-- Scope manual saves to individual characters
alter table public.manual_saves
  add column if not exists character_id uuid;

create index if not exists manual_saves_character_id_idx on public.manual_saves(character_id);
