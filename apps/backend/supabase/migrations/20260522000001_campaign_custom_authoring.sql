-- Allow user-owned custom campaigns with narrator customisation fields.

alter table public.campaigns
  add column if not exists user_id uuid references auth.users(id) on delete cascade,
  add column if not exists narrator_tone text not null default 'grimdark',
  add column if not exists world_description text not null default '',
  add column if not exists is_custom boolean not null default false;

-- Seed campaign_01 keeps user_id null (system-owned).
update public.campaigns
  set narrator_tone = 'grimdark',
      world_description = 'A plague-ridden dark fantasy world where ancient evils stir beneath crumbling institutions. Death is common, trust is rare, and power always has a price.',
      is_custom = false
  where id = 'campaign_01';

-- RLS: users can read system campaigns (user_id is null) and their own custom campaigns.
alter table public.campaigns enable row level security;

drop policy if exists "campaigns_select" on public.campaigns;
create policy "campaigns_select" on public.campaigns
  for select using (user_id is null or user_id = auth.uid());

drop policy if exists "campaigns_insert" on public.campaigns;
create policy "campaigns_insert" on public.campaigns
  for insert with check (user_id = auth.uid());

drop policy if exists "campaigns_delete" on public.campaigns;
create policy "campaigns_delete" on public.campaigns
  for delete using (user_id = auth.uid());
