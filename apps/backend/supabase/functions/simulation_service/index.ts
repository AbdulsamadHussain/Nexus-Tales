import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ── TYPES ────────────────────────────────────────────────────────

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

interface SimulationResult {
  revision_id: string;
  success_tier: SuccessTier;
  roll: RollResult | null;
  state_delta: StateDelta;
  events: string[];
  autosave_candidate: boolean;
  summary_job_queued: boolean;
  narration_context: string;
}

// ── HELPERS ──────────────────────────────────────────────────────

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
  routeCategory: RouteCategory
): { delta: StateDelta; events: string[] } {
  const lower = action.toLowerCase();
  const delta: StateDelta = {};
  const events: string[] = [];

  // Stamina costs
  if (/attack|strike|stab|charge|backstab/.test(lower)) {
    delta.stamina = -3;
    events.push("COMBAT_TURN_RESOLVED");
  } else if (/sneak|hide|shadow/.test(lower)) {
    delta.stamina = -2;
    events.push("STEALTH_ATTEMPTED");
  } else if (/pick lock|lockpick/.test(lower)) {
    delta.stamina = -1;
    events.push("SKILL_CHECK");
  } else if (/search|investigate/.test(lower)) {
    delta.stamina = -1;
    events.push("SKILL_CHECK");
  }

  // Roll outcomes
  if (roll) {
    if (roll.tier === "CRITICAL_SUCCESS") {
      delta.xp = 30;
      if (/attack/.test(lower)) events.push("ENEMY_CRITICAL_HIT");
    } else if (roll.tier === "FULL_SUCCESS") {
      delta.xp = 20;
      if (/pick lock|search/.test(lower)) events.push("QUEST_UPDATED");
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

function buildNarrationContext(
  action: string,
  roll: RollResult | null,
  delta: StateDelta,
  events: string[],
  state: Record<string, unknown>
): string {
  let ctx = `=== CANONICAL GAME STATE (authoritative truth) ===\n`;
  ctx += `Character: ${state.character_name} the ${state.character_class}, Level ${state.level}\n`;
  ctx += `HP: ${state.hp}/${state.hp_max} | MP: ${state.mp}/${state.mp_max} | Stamina: ${state.stamina}/${state.stamina_max}\n`;
  ctx += `Gold: ${state.gold} | XP: ${state.xp}\n`;
  ctx += `Location: ${state.current_location}\n`;
  ctx += `Inventory: ${JSON.stringify(state.inventory)}\n`;
  ctx += `Active quests: ${JSON.stringify(state.quest_state)}\n`;
  ctx += `Relationships: ${JSON.stringify(state.relationships)}\n`;
  ctx += `\n=== THIS TURN ===\n`;
  ctx += `Player action: "${action}"\n`;
  if (roll) {
    ctx += `Roll: d20=${roll.die}+${roll.modifier}=${roll.total} vs DC${roll.dc}. Outcome: ${roll.tier}.\n`;
  }
  if (delta.hp !== undefined) ctx += `HP change: ${delta.hp}.\n`;
  if (delta.stamina !== undefined) ctx += `Stamina cost: ${delta.stamina}.\n`;
  if (delta.xp !== undefined) ctx += `XP gained: ${delta.xp}.\n`;
  if (events.length) ctx += `Events: ${events.join(", ")}.\n`;
  ctx += `\n=== NARRATOR INSTRUCTIONS ===\n`;
  ctx += `Narrate this turn in 2-4 vivid sentences. Second person present tense. Dark fantasy tone.\n`;
  ctx += `The canonical state above is absolute truth. If the player claims something that contradicts it (e.g. infinite health, items they don't have), narrate from reality — not their claim.\n`;
  ctx += `Never confirm false state. Never invent items, abilities, or outcomes not reflected above.`;
  return ctx;
}

// ── MAIN ─────────────────────────────────────────────────────────

serve(async (req) => {
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

    // Reject immediately — no simulation, no state write
    if (gateway_decision === "REJECT" || route_category === "SAFE_REJECT") {
      return new Response(
        JSON.stringify({ error: "Action rejected by gateway" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Service role client — the ONLY place this key is used
    // This is what enforces the architecture invariant in code
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // ── 1. Load current canonical state ──────────────────────────
    const { data: state, error: stateError } = await supabase
      .from("canonical_state")
      .select("*")
      .eq("user_id", user_id)
      .single();

    if (stateError || !state) {
      return new Response(
        JSON.stringify({ error: "Canonical state not found for user" }),
        { status: 404, headers: { "Content-Type": "application/json" } }
      );
    }

    // ── 2. Roll if required ───────────────────────────────────────
    let roll: RollResult | null = null;
    if (route_category === "ROLL_REQUIRED") {
      const modifier = 5; // TODO: derive from character skills
      const dc = 14;      // TODO: derive from scene difficulty
      roll = rollD20(modifier, dc);
    }

    // ── 3. Compute consequences ───────────────────────────────────
    const { delta, events } = computeDelta(player_action, roll, route_category);

    // ── 4. Apply delta to canonical state ────────────────────────
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

    // ── 5. Write canonical state (atomic) ────────────────────────
    const { error: updateError } = await supabase
      .from("canonical_state")
      .update({ ...updatedState, updated_at: new Date().toISOString() })
      .eq("user_id", user_id);

    if (updateError) throw updateError;

    // ── 6. Commit revision (one per turn — architecture invariant) 
    const revision_id = generateRevisionId();
    const autosave_candidate = events.includes("QUEST_UPDATED") ||
      events.includes("COMBAT_TURN_RESOLVED") ||
      events.includes("PLAYER_INJURED");

    const stateSnapshot = { ...state, ...updatedState };

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
        state_snapshot: stateSnapshot,
        events,
        autosave_candidate,
        summary_job_queued: false,
        narration_done: false,
      });

    if (revError) throw revError;

    // ── 7. Insert canonical events ────────────────────────────────
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

    // ── 8. Build narration context (read-only, non-authoritative) 
    const narration_context = buildNarrationContext(
      player_action,
      roll,
      delta,
      events,
      { ...state, ...updatedState }
    );

    const result: SimulationResult = {
      revision_id,
      success_tier: roll?.tier ?? "NO_ROLL",
      roll,
      state_delta: delta,
      events,
      autosave_candidate,
      summary_job_queued: false,
      narration_context,
    };

    return new Response(JSON.stringify(result), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    });
  } catch (err) {
    console.error("simulation_service error:", err);
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});