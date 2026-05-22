-- Add character_id as the new primary key for canonical_state.
-- user_id becomes a non-unique foreign key (one user → many characters).

-- 1. Add the column (generate IDs for existing rows)
alter table public.canonical_state
  add column if not exists character_id uuid not null default gen_random_uuid();

-- 2. Drop the old primary key constraint (was user_id)
alter table public.canonical_state
  drop constraint if exists canonical_state_pkey;

-- 3. Set character_id as the new primary key
alter table public.canonical_state
  add constraint canonical_state_pkey primary key (character_id);

-- 4. Keep an index on user_id for fast lookups by owner
create index if not exists canonical_state_user_id_idx on public.canonical_state(user_id);

-- 5. Update RLS: users can see all their own characters
drop policy if exists "Users can view own state" on public.canonical_state;
drop policy if exists "Users can update own state" on public.canonical_state;
drop policy if exists "Users can insert own state" on public.canonical_state;

create policy "Users can view own characters"
  on public.canonical_state for select
  using (auth.uid() = user_id);

create policy "Users can update own characters"
  on public.canonical_state for update
  using (auth.uid() = user_id);

create policy "Users can insert own characters"
  on public.canonical_state for insert
  with check (auth.uid() = user_id);

create policy "Users can delete own characters"
  on public.canonical_state for delete
  using (auth.uid() = user_id);
