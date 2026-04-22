alter table public.canonical_state
  alter column relationships type jsonb using relationships::jsonb;

alter table public.canonical_state
  alter column factions type jsonb using factions::jsonb;

alter table public.canonical_state
  alter column quest_state type jsonb using quest_state::jsonb;

alter table public.canonical_state
  alter column content_settings type jsonb using content_settings::jsonb;

alter table public.canonical_state
  alter column known_lore type jsonb using known_lore::jsonb;

alter table public.canonical_state
  alter column skills type jsonb using skills::jsonb;

alter table public.canonical_state
  alter column inventory type jsonb using inventory::jsonb;