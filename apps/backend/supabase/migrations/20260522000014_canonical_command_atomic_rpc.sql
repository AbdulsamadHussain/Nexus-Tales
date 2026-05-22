-- Migration: canonical_command_atomic_rpc
-- Replaces the three-step non-atomic sequence in canonical_command Edge Function
-- (UPDATE canonical_state → INSERT revisions → INSERT canonical_events) with a
-- single PostgreSQL function that commits all three in one transaction protected
-- by a SELECT ... FOR UPDATE row lock.
--
-- One committed canonical mutation = one committed revision.  If any step fails,
-- all steps roll back — canonical_state never changes without a matching revision.
--
-- Security:
--   SECURITY DEFINER  — runs as function owner (postgres) to bypass RLS.
--   search_path = ''  — fully qualified table refs; prevents search_path injection.
--   EXECUTE revoked from public/anon/authenticated.
--   EXECUTE granted only to service_role (used by the canonical_command Edge Fn).
--   Clients cannot call this function directly.

create or replace function public.execute_canonical_command(
  p_user_id         uuid,
  p_character_id    uuid,
  p_command         text,

  -- BUY_ITEM: price + full item record pre-validated by Edge Fn server catalogue.
  -- Passing the authoritative cost here (not re-reading the catalogue in SQL)
  -- keeps catalogue logic in one place (TypeScript) while the DB enforces
  -- the gold check atomically against the locked balance.
  p_item_id         text    default null,
  p_item_cost       int     default null,
  p_item_record     jsonb   default null,   -- full item object appended to inventory

  -- CHOOSE_SKILL: name/desc pre-validated by Edge Fn class catalogue.
  p_skill_id        text    default null,
  p_skill_name      text    default null,
  p_skill_desc      text    default null,

  -- EDIT_PROFILE: pre-validated, length-capped key/value pairs.
  -- Only keys present in the jsonb are applied; absent keys leave existing values.
  p_profile_updates jsonb   default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_state        public.canonical_state%rowtype;
  v_revision_id  text;
  v_prev_rev_id  text;
  v_new_gold     int;
  v_new_inv      jsonb;
  v_new_skills   jsonb;
  v_skill_count  int;
  v_events       text[];
  v_snapshot     jsonb;
begin
  -- ── Row lock ──────────────────────────────────────────────────────────
  -- Acquire an exclusive row lock on the character's canonical_state row
  -- for the duration of this transaction.
  --
  -- Effect on concurrent calls:
  --   Two simultaneous BUY_ITEM calls for the same character will queue here.
  --   The second call reads the updated gold balance (after the first commits),
  --   so it cannot spend the same gold twice.
  select * into v_state
  from public.canonical_state
  where character_id = p_character_id
    and user_id      = p_user_id
  for update;

  if not found then
    raise exception 'character_not_found' using errcode = 'P0001';
  end if;

  -- UUID-based revision ID generated inside the transaction.
  -- 'cmd_' prefix distinguishes command revisions from gameplay revisions.
  v_revision_id := 'cmd_' || gen_random_uuid()::text;
  v_events      := array[]::text[];

  -- Latest revision for chain linkage; queried inside the transaction (safe).
  select id into v_prev_rev_id
  from public.revisions
  where user_id      = p_user_id
    and character_id = p_character_id
  order by created_at desc
  limit 1;

  -- ── BUY_ITEM ──────────────────────────────────────────────────────────
  if p_command = 'BUY_ITEM' then
    if p_item_id is null or p_item_cost is null or p_item_record is null then
      raise exception 'missing_item_params' using errcode = 'P0002';
    end if;

    -- Gold check against the LOCKED balance: race-safe.
    if v_state.gold < p_item_cost then
      raise exception 'insufficient_gold' using errcode = 'P0003';
    end if;

    v_new_gold := v_state.gold - p_item_cost;
    -- Append item to the existing inventory jsonb array.
    v_new_inv  := v_state.inventory || jsonb_build_array(p_item_record);

    update public.canonical_state
       set gold       = v_new_gold,
           inventory  = v_new_inv,
           updated_at = now()
     where character_id = p_character_id
       and user_id      = p_user_id;

    v_events := array_append(v_events, 'ITEM_PURCHASED:' || p_item_id);

  -- ── CHOOSE_SKILL ──────────────────────────────────────────────────────
  elsif p_command = 'CHOOSE_SKILL' then
    if p_skill_id is null or p_skill_name is null then
      raise exception 'missing_skill_params' using errcode = 'P0002';
    end if;

    -- Already-learned check against LOCKED skills column.
    if (v_state.skills -> p_skill_id) is not null then
      raise exception 'skill_already_learned' using errcode = 'P0004';
    end if;

    -- Slot availability: skill count must be < (level - 1).
    -- Checked against the LOCKED level and skills: race-safe.
    select count(*)::int into v_skill_count
    from jsonb_each(v_state.skills);

    if v_skill_count >= (v_state.level - 1) then
      raise exception 'no_skill_slot_available' using errcode = 'P0005';
    end if;

    v_new_skills := v_state.skills || jsonb_build_object(
      p_skill_id, jsonb_build_object(
        'name',              p_skill_name,
        'desc',              coalesce(p_skill_desc, ''),
        'unlocked_at_level', v_state.level
      )
    );

    update public.canonical_state
       set skills     = v_new_skills,
           updated_at = now()
     where character_id = p_character_id
       and user_id      = p_user_id;

    v_events := array_append(v_events, 'SKILL_LEARNED:' || p_skill_id);

  -- ── EDIT_PROFILE ──────────────────────────────────────────────────────
  elsif p_command = 'EDIT_PROFILE' then
    if p_profile_updates is null or p_profile_updates = '{}'::jsonb then
      raise exception 'no_profile_fields' using errcode = 'P0006';
    end if;

    -- Apply only the keys present in p_profile_updates; absent keys are unchanged.
    -- The ? operator checks key existence in jsonb (not value truthiness).
    update public.canonical_state
       set character_name = case when p_profile_updates ? 'character_name'
                                 then p_profile_updates->>'character_name'
                                 else character_name end,
           origin         = case when p_profile_updates ? 'origin'
                                 then p_profile_updates->>'origin'
                                 else origin end,
           backstory      = case when p_profile_updates ? 'backstory'
                                 then p_profile_updates->>'backstory'
                                 else backstory end,
           updated_at     = now()
     where character_id = p_character_id
       and user_id      = p_user_id;

    v_events := array_append(v_events, 'PROFILE_EDITED');

  else
    raise exception 'unknown_command' using errcode = 'P0007';
  end if;

  -- ── Post-command snapshot ─────────────────────────────────────────────
  -- Re-read the row after mutation so the revision snapshot reflects the actual
  -- committed state (not the pre-command stale read).
  select to_jsonb(cs) into v_snapshot
  from public.canonical_state cs
  where character_id = p_character_id;

  -- ── Insert exactly one revision ───────────────────────────────────────
  -- If this INSERT fails for any reason, the entire transaction (including the
  -- canonical_state UPDATE above) rolls back automatically.
  insert into public.revisions (
    id, user_id, character_id, previous_id, schema_version,
    player_action, route_category, gateway_decision, success_tier,
    state_snapshot, events, autosave_candidate, narration_done, summary_job_queued
  ) values (
    v_revision_id, p_user_id, p_character_id, v_prev_rev_id, 1,
    '[' || p_command || ']', 'UI_ACTION', 'ALLOW', 'NO_ROLL',
    v_snapshot, v_events, false, true, false
  );

  -- ── Insert matching canonical_events ──────────────────────────────────
  -- If this INSERT fails, both the revision INSERT and canonical_state UPDATE
  -- roll back. unnest over an empty array produces zero rows (no-op insert).
  if array_length(v_events, 1) > 0 then
    insert into public.canonical_events (user_id, revision_id, event_type, payload)
    select p_user_id,
           v_revision_id,
           evt,
           jsonb_build_object('command', p_command)
    from unnest(v_events) as evt;
  end if;

  -- ── Success ───────────────────────────────────────────────────────────
  return jsonb_build_object(
    'revision_id', v_revision_id,
    'status',      'OK',
    'events',      to_jsonb(v_events)
  );

-- ── Domain error handlers ─────────────────────────────────────────────
-- When an exception is raised inside the begin…end block, PostgreSQL rolls
-- back all changes made within the block (via implicit savepoint), then runs
-- the matching handler. The outer transaction commits the handler's return.
-- No canonical_state mutation is committed for any domain error below.
exception
  when sqlstate 'P0001' then return jsonb_build_object('error', 'character_not_found',     'status', 404);
  when sqlstate 'P0002' then return jsonb_build_object('error', 'missing_params',          'status', 400);
  when sqlstate 'P0003' then return jsonb_build_object('error', 'insufficient_gold',       'status', 422);
  when sqlstate 'P0004' then return jsonb_build_object('error', 'skill_already_learned',   'status', 422);
  when sqlstate 'P0005' then return jsonb_build_object('error', 'no_skill_slot_available', 'status', 422);
  when sqlstate 'P0006' then return jsonb_build_object('error', 'no_profile_fields',       'status', 400);
  when sqlstate 'P0007' then return jsonb_build_object('error', 'unknown_command',         'status', 400);
  -- Unexpected DB errors (constraint violations, etc.) propagate to the caller
  -- so PostgREST rolls back the entire transaction.
end;
$$;

-- ── Security grants ───────────────────────────────────────────────────────
-- Revoke default public execute, then grant only to service_role.
-- The canonical_command Edge Function uses SVC_ROLE_KEY → service_role.
-- Clients calling with anon key or user JWT cannot invoke this function.
revoke all     on function public.execute_canonical_command from public;
revoke execute on function public.execute_canonical_command from anon;
revoke execute on function public.execute_canonical_command from authenticated;
grant  execute on function public.execute_canonical_command to service_role;
