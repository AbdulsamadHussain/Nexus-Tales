-- Character portrait selection
alter table public.canonical_state
  add column if not exists portrait text not null default 'default';

-- Allow campaign authors to make their world publicly discoverable
alter table public.campaigns
  add column if not exists is_public boolean not null default false;

-- Index for browsing public campaigns
create index if not exists campaigns_is_public_idx on public.campaigns(is_public) where is_public = true;
