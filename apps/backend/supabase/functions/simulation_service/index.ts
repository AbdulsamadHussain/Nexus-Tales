import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type RouteCategory =
  | "NO_ROLL_DETERMINISTIC"
  | "ROLL_REQUIRED"
  | "CLARIFICATION_REQUIRED"
  | "SAFE_REJECT"
  | "UI_ACTION"
  | "SYSTEM_TRANSFORMED_ACTION";

type GatewayDecision =
  | "ALLOW"
  | "ALLOW_WITH_CONSTRAINTS"
  | "TRANSFORM"
  | "REJECT";

type SuccessTier =
  | "CRITICAL_SUCCESS"
  | "FULL_SUCCESS"
  | "PARTIAL_SUCCESS"
  | "FAILURE"
  | "CRITICAL_FAILURE"
  | "NO_ROLL";

interface ActionPacket {
  user_id: string;
  player_action: string;
  route_category: RouteCategory;
  gateway_decision: GatewayDecision;
  narration_constraints: string[];
  previous_revision_id: string | null;
}

interface RollResult {
  die: number;
  modifier: number;
  total: number;
  dc: number;
  tier: SuccessTier;
}

interface StateDelta {
  hp?: number;
  mp?: number;
  stamina?: number;
  xp?: number;
  gold?: number;
}

function generateRevisionId(): string {
  const num = Math.floor(Math.random() * 900000) + 100000;
  return `rev_${num}`;
}

function rollD20(modifier: number, dc: number): RollResult {
  const die = Math.floor(Math.random() * 20) + 1;
  const total = die + modifier;
  let tier: SuccessTier;
  if (die === 20 || total >= dc + 6) tier = "CRITICAL_SUCCESS";
  else if (total >= dc) tier = "FULL_SUCCESS";
  else if (total >= dc - 4) tier = "PARTIAL_SUCCESS";
  else if (die === 1 || total <= dc - 8) tier = "CRITICAL_FAILURE";
  else tier = "FAILURE";
  return { die, modifier, total, dc, tier };
}

function computeDelta(
  action: string,
  roll: RollResult | null,
): { delta: StateDelta; events: string[] } {
  const lower = action.toLowerCase();
  const delta: StateDelta = {};
  const events: string[] = [];

  if (/attack|strike|stab|charge|backstab/.test(lower)) {
    delta.stamina = -3;
    events.push("COMBAT_TURN_RESOLVED");
  } else if (/sneak|hide|shadow/.test(lower)) {
    delta.stamina = -2;
    events.push("STEALTH_ATTEMPTED");
  } else if (/pick lock|lockpick/.test(lower)) {
    delta.stamina = -1;
    events.push("SKILL_CHECK");
  } else if (/search|examine|investigate/.test(lower)) {
    delta.stamina = -1;
    events.push("SKILL_CHECK");
  }

  if (roll) {
    if (roll.tier === "CRITICAL_SUCCESS") {
      delta.xp = 30;
    } else if (roll.tier === "FULL_SUCCESS") {
      delta.xp = 20;
      if (/pick lock|search|examine/.test(lower)) events.push("QUEST_UPDATED");
    } else if (roll.tier === "PARTIAL_SUCCESS") {
      delta.hp = -4;
      delta.xp = 10;
    } else if (roll.tier === "FAILURE") {
      delta.hp = -5;
      delta.xp = 5;
    } else if (roll.tier === "CRITICAL_FAILURE") {
      delta.hp = -10;
      delta.xp = 5;
      events.push("PLAYER_INJURED");
    }
  }

  return { delta, events };
}

// ── CHECK STORY BEATS ─────────────────────────────────────────────
// After every turn, check if any story beat conditions are met.
// If so, apply consequences and return narration hints.

async function checkStoryBeats(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  campaignId: string,
  events: string[],
  state: Record<string, unknown>,
  campaignState: Record<string, unknown>,
): Promise<{ fired: string[]; narrationHints: string[] }> {
  const fired: string[] = [];
  const narrationHints: string[] = [];

  const { data: beats } = await supabase
    .from("story_beats")
    .select("*")
    .eq("campaign_id", campaignId)
    .order("priority", { ascending: false });

  if (!beats) return { fired, narrationHints };

  const beatenBeats = (campaignState.beaten_beats as string[]) || [];

  for (const beat of beats) {
    if (beatenBeats.includes(beat.id) && !beat.is_repeatable) continue;

    let triggered = false;
    const triggerData = beat.trigger_data as Record<string, unknown>;
    const npcStates = (campaignState.npc_states as Record<string, unknown>) || {};

    if (beat.trigger_type === "NPC_DEFEATED") {
      const npcId = triggerData.npc_id as string;
      const npcState = npcStates[npcId] as Record<string, unknown> | undefined;
      if (npcState?.is_dead) triggered = true;
    }

    if (beat.trigger_type === "EVENT" && events.includes(triggerData.event as string)) {
      triggered = true;
    }

    if (beat.trigger_type === "ITEM_ACQUIRED") {
      const inventory = (state.inventory as unknown[]) || [];
      const hasItem = inventory.some(
        (i) => (i as Record<string, unknown>).item_id === triggerData.item_id
      );
      if (hasItem) triggered = true;
    }

    if (triggered) {
      fired.push(beat.id);
      const consequences = beat.consequences as Record<string, unknown>;
      if (consequences.narration_hint) {
        narrationHints.push(consequences.narration_hint as string);
      }
    }
  }

  // Mark beats as fired
  if (fired.length > 0) {
    await supabase
      .from("player_campaign_state")
      .update({
        beaten_beats: [...beatenBeats, ...fired],
        last_played_at: new Date().toISOString(),
      })
      .eq("user_id", userId)
      .eq("campaign_id", campaignId);
  }

  return { fired, narrationHints };
}

// ── BUILD NARRATION CONTEXT ───────────────────────────────────────

function buildNarrationContext(
  action: string,
  roll: RollResult | null,
  delta: StateDelta,
  events: string[],
  state: Record<string, unknown>,
  scene: Record<string, unknown> | null,
  npcsInScene: Record<string, unknown>[],
  narrationHints: string[],
): string {
  let ctx = `=== CANONICAL GAME STATE ===\n`;
  ctx += `Character: ${state.character_name} the ${state.character_class}\n`;
  ctx += `HP: ${state.hp}/${state.hp_max} | MP: ${state.mp}/${state.mp_max} | Stamina: ${state.stamina}/${state.stamina_max}\n`;
  ctx += `Location: ${state.current_location}\n`;

  if (scene) {
    ctx += `\n=== CURRENT SCENE ===\n`;
    ctx += `${scene.title}: ${scene.description}\n`;
    ctx += `Atmosphere: ${scene.atmosphere}\n`;
  }

  if (npcsInScene.length > 0) {
    ctx += `\n=== NPCS PRESENT ===\n`;
    for (const npc of npcsInScene) {
      ctx += `${npc.name}: ${npc.description}. ${npc.personality}\n`;
    }
  }

  ctx += `\n=== THIS TURN ===\n`;
  ctx += `Player action: "${action}"\n`;
  if (roll) {
    ctx += `Roll: d20=${roll.die}+${roll.modifier}=${roll.total} vs DC${roll.dc}. Outcome: ${roll.tier}.\n`;
  }
  if (delta.hp !== undefined) ctx += `HP change: ${delta.hp}.\n`;
  if (delta.stamina !== undefined) ctx += `Stamina cost: ${delta.stamina}.\n`;
  if (delta.xp !== undefined) ctx += `XP gained: ${delta.xp}.\n`;
  if (events.length) ctx += `Events: ${events.join(", ")}.\n`;

  if (narrationHints.length > 0) {
    ctx += `\n=== STORY BEAT TRIGGERED ===\n`;
    ctx += narrationHints.join("\n") + "\n";
  }

  ctx += `\n=== NARRATOR INSTRUCTIONS ===\n`;
  ctx += `Narrate this turn in 2-4 vivid sentences. Second person present tense. Dark fantasy tone.\n`;
  ctx += `Use the scene description and NPC personalities to ground the narration.\n`;
  ctx += `The canonical state above is absolute truth. Never invent items, abilities, or outcomes not shown above.\n`;
  ctx += `If a story beat was triggered, incorporate its hint dramatically into the narration.`;

  return ctx;
}

// ── MAIN ─────────────────────────────────────────────────────────

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  try {
    const packet: ActionPacket = await req.json();
    const { user_id, player_action, route_category, gateway_decision, previous_revision_id } = packet;

    if (gateway_decision === "REJECT" || route_category === "SAFE_REJECT") {
      return new Response(
        JSON.stringify({ error: "Action rejected by gateway" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SVC_ROLE_KEY")!
    );

    // ── 1. Load canonical state ───────────────────────────────────
    const { data: state, error: stateError } = await supabase
      .from("canonical_state")
      .select("*")
      .eq("user_id", user_id)
      .single();

    if (stateError || !state) {
      return new Response(
        JSON.stringify({ error: "Canonical state not found" }),
        { status: 404, headers: { "Content-Type": "application/json" } }
      );
    }

    // ── 2. Load scene + NPCs ──────────────────────────────────────
    const { data: scene } = await supabase
      .from("scenes")
      .select("*")
      .eq("id", state.current_location)
      .maybeSingle();

    const { data: sceneNpcs } = await supabase
      .from("scene_npcs")
      .select("npc_id")
      .eq("scene_id", state.current_location);

    let npcsInScene: Record<string, unknown>[] = [];
    if (sceneNpcs && sceneNpcs.length > 0) {
      const npcIds = sceneNpcs.map((sn) => sn.npc_id);
      const { data: npcs } = await supabase
        .from("npcs")
        .select("*")
        .in("id", npcIds);
      npcsInScene = npcs || [];
    }

    // ── 3. Load or create player campaign state ───────────────────
    let { data: campaignState } = await supabase
      .from("player_campaign_state")
      .select("*")
      .eq("user_id", user_id)
      .eq("campaign_id", state.campaign_id)
      .maybeSingle();

    if (!campaignState) {
      const { data: newCampaignState } = await supabase
        .from("player_campaign_state")
        .insert({
          user_id,
          campaign_id: state.campaign_id,
          current_scene: state.current_location,
          beaten_beats: [],
          npc_states: {},
          scene_item_states: {},
        })
        .select()
        .single();
      campaignState = newCampaignState;
    }

    // ── 4. Roll if required ───────────────────────────────────────
    let roll: RollResult | null = null;
    if (route_category === "ROLL_REQUIRED") {
      const modifier = 5;
      const dc = 14;
      roll = rollD20(modifier, dc);
    }

    // ── 5. Compute consequences ───────────────────────────────────
    const { delta, events } = computeDelta(player_action, roll);

    // ── 6. Apply delta to canonical state ─────────────────────────
    const updatedState: Record<string, number> = {};
    if (delta.hp !== undefined) {
      updatedState.hp = Math.max(0, Math.min(state.hp_max, state.hp + delta.hp));
    }
    if (delta.stamina !== undefined) {
      updatedState.stamina = Math.max(0, Math.min(state.stamina_max, state.stamina + delta.stamina));
    }
    if (delta.mp !== undefined) {
      updatedState.mp = Math.max(0, Math.min(state.mp_max, state.mp + delta.mp));
    }
    if (delta.xp !== undefined) {
      updatedState.xp = state.xp + delta.xp;
    }
    if (delta.gold !== undefined) {
      updatedState.gold = state.gold + delta.gold;
    }

    // ── 7. Write canonical state ──────────────────────────────────
    const { error: updateError } = await supabase
      .from("canonical_state")
      .update({ ...updatedState, updated_at: new Date().toISOString() })
      .eq("user_id", user_id);

    if (updateError) throw updateError;

    // ── 8. Check story beats ──────────────────────────────────────
    const { fired: beatsFired, narrationHints } = await checkStoryBeats(
      supabase,
      user_id,
      state.campaign_id,
      events,
      { ...state, ...updatedState },
      campaignState || {},
    );

    if (beatsFired.length > 0) {
      events.push(...beatsFired.map((id) => `STORY_BEAT:${id}`));
    }

    // ── 9. Commit revision ────────────────────────────────────────
    const revision_id = generateRevisionId();
    const autosave_candidate =
      events.some((e) => e.startsWith("STORY_BEAT")) ||
      events.includes("QUEST_UPDATED") ||
      events.includes("COMBAT_TURN_RESOLVED") ||
      events.includes("PLAYER_INJURED");

    const { error: revError } = await supabase
      .from("revisions")
      .insert({
        id: revision_id,
        user_id,
        previous_id: previous_revision_id,
        schema_version: 1,
        player_action,
        route_category,
        gateway_decision,
        success_tier: roll?.tier ?? "NO_ROLL",
        roll_die: roll?.die ?? null,
        roll_modifier: roll?.modifier ?? null,
        roll_total: roll?.total ?? null,
        roll_dc: roll?.dc ?? null,
        state_snapshot: { ...state, ...updatedState },
        events,
        autosave_candidate,
        narration_done: false,
      });

    if (revError) throw revError;

    // ── 10. Insert canonical events ───────────────────────────────
    if (events.length > 0) {
      await supabase.from("canonical_events").insert(
        events.map((event_type) => ({
          user_id,
          revision_id,
          event_type,
          payload: { roll, delta },
        }))
      );
    }

    // ── 11. Build narration context ───────────────────────────────
    const narration_context = buildNarrationContext(
      player_action,
      roll,
      delta,
      events,
      { ...state, ...updatedState },
      scene,
      npcsInScene,
      narrationHints,
    );

    return new Response(
      JSON.stringify({
        revision_id,
        success_tier: roll?.tier ?? "NO_ROLL",
        roll,
        state_delta: delta,
        events,
        autosave_candidate,
        summary_job_queued: false,
        narration_context,
      }),
      {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  } catch (err) {
    console.error("simulation_service error:", err);
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } }
    );
  }
});