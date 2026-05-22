-- Allow any authenticated user to read public custom campaigns (for Browse Worlds)
drop policy if exists "campaigns_select_public" on public.campaigns;
create policy "campaigns_select_public" on public.campaigns
  for select
  using (is_public = true and is_custom = true);
