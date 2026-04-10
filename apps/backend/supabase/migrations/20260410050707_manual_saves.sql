create table public.manual_saves (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  revision_id text not null,
  save_name text not null,
  campaign_id text not null,
  schema_version int not null default 1,
  state_snapshot jsonb not null,
  created_at timestamptz not null default now()
);

alter table public.manual_saves enable row level security;

create policy "Users can manage their own saves"
  on public.manual_saves
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create index manual_saves_user_id_idx on public.manual_saves(user_id);
create index manual_saves_campaign_id_idx on public.manual_saves(campaign_id);