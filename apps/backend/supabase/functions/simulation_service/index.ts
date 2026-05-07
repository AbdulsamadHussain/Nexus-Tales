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
  action_type?: string;
  candidate_skill?: string;
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

// ── NPC COUNTER-ATTACK DAMAGE ─────────────────────────────────────
// Reads attack_damage from NPC data, falls back to 5 if not set.
function getNpcCounterDamage(npc: Record<string, unknown>): number {
  return (npc.attack_damage as number) ?? 5;
}

function computeDelta(
  action: string,
  actionType: string | undefined,
  roll: RollResult | null,
  npcsInScene: Record<string, unknown>[],
  npcStates: Record<string, unknown>,
  characterSkills: Record<string, number>,
): {
  delta: StateDelta;
  events: string[];
  npcStateUpdates: Record<string, unknown>;
  combatNarrationHints: string[];
} {
  const lower = action.toLowerCase();
  const delta: StateDelta = {};
  const events: string[] = [];
  const npcStateUpdates: Record<string, unknown> = {};
  const combatNarrationHints: string[] = [];

  const isRest = actionType === "REST" || /\b(rest|sit|breathe|recover|catch my breath|take a moment|take a break|meditate|sleep|wait)\b/.test(lower);
  const isUseItem = actionType === "USE_ITEM" || /\b(use|drink|apply|consume)\b.*(salve|potion|vial|healing|remedy|bandage)/.test(lower) || /\b(healing salve|health potion)\b/.test(lower);
  const isAttack = actionType === "ATTACK" || /attack|strike|stab|charge|backstab|slash|punch|kick/.test(lower);
  const isStealth = actionType === "STEALTH" || /sneak|hide|shadow/.test(lower);
  const isSkillCheck = actionType === "SKILL_CHECK" || /pick lock|lockpick|search|examine|investigate/.test(lower);

  // ── REST / RECOVERY ───────────────────────────────────────────
  if (isRest) {
    delta.stamina = 8;
    delta.hp = 2;
    events.push("PLAYER_RESTED");
    return { delta, events, npcStateUpdates, combatNarrationHints };
  }

  // ── CONSUMABLE USE ────────────────────────────────────────────
  if (isUseItem) {
    events.push("ITEM_USED");
    // Actual item consumption handled in main flow — flag here for routing
    delta.hp = 12;
    return { delta, events, npcStateUpdates, combatNarrationHints };
  }

  // ── STAMINA COSTS ─────────────────────────────────────────────
  if (isAttack) {
    delta.stamina = -3;
    events.push("COMBAT_TURN_RESOLVED");
  } else if (isStealth) {
    delta.stamina = -2;
    events.push("STEALTH_ATTEMPTED");
  } else if (isSkillCheck) {
    delta.stamina = -1;
    events.push("SKILL_CHECK");
  }

  // ── ROLL OUTCOMES ─────────────────────────────────────────────
  if (roll) {
    if (isAttack && delta.stamina === undefined) {
      delta.stamina = -3;
    }

    if (roll.tier === "CRITICAL_SUCCESS") {
      delta.xp = 30;
      if (isAttack) {
        // Deal damage to hostile NPC — no counter on critical success
        const targetNpc = findTargetNpc(lower, npcsInScene);
        if (targetNpc) {
          const npcId = targetNpc.id as string;
          const currentHp = getNpcHp(npcId, targetNpc, npcStates);
          const damage = 15;
          const newHp = Math.max(0, currentHp - damage);
          npcStateUpdates[npcId] = {
            ...(npcStates[npcId] as Record<string, unknown> ?? {}),
            hp: newHp,
            is_dead: newHp <= 0,
          };
          if (newHp <= 0) events.push("NPC_DEFEATED");
          else events.push("ENEMY_CRITICAL_HIT");
        }
      }
    } else if (roll.tier === "FULL_SUCCESS") {
      delta.xp = 20;
      if (isAttack) {
        // Deal damage to hostile NPC — no counter on full success
        const targetNpc = findTargetNpc(lower, npcsInScene);
        if (targetNpc) {
          const npcId = targetNpc.id as string;
          const currentHp = getNpcHp(npcId, targetNpc, npcStates);
          const damage = 9;
          const newHp = Math.max(0, currentHp - damage);
          npcStateUpdates[npcId] = {
            ...(npcStates[npcId] as Record<string, unknown> ?? {}),
            hp: newHp,
            is_dead: newHp <= 0,
          };
          if (newHp <= 0) events.push("NPC_DEFEATED");
        }
      }
      if (isSkillCheck && /pick lock|search|examine/.test(lower)) events.push("QUEST_UPDATED");
    } else if (roll.tier === "PARTIAL_SUCCESS") {
      delta.xp = 10;
      if (isAttack) {
        // Player deals reduced damage to NPC
        const targetNpc = findTargetNpc(lower, npcsInScene);
        if (targetNpc) {
          const npcId = targetNpc.id as string;
          const currentHp = getNpcHp(npcId, targetNpc, npcStates);
          const damage = 4;
          const newHp = Math.max(0, currentHp - damage);
          npcStateUpdates[npcId] = {
            ...(npcStates[npcId] as Record<string, unknown> ?? {}),
            hp: newHp,
            is_dead: newHp <= 0,
          };
          if (newHp <= 0) events.push("NPC_DEFEATED");
        }
        // NPC counter-attacks on partial success
        const hostileNpc = npcsInScene.find(
          (n) =>
            n.is_hostile === true &&
            !(npcStates[n.id as string] as Record<string, unknown>)?.is_dead,
        );
        if (hostileNpc) {
          const counterDamage = getNpcCounterDamage(hostileNpc);
          delta.hp = -counterDamage;
          events.push("NPC_COUNTER_ATTACKED");
          combatNarrationHints.push(
            `NPC_COUNTER_ATTACK:${hostileNpc.name} strikes back for ${counterDamage} damage.`,
          );
        }
      } else {
        // Non-attack partial success — minor setback, no counter
        delta.hp = -3;
      }
    } else if (roll.tier === "FAILURE") {
      delta.xp = 5;
      // NPC counter-attacks on failure — heavier damage
      const hostileNpc = npcsInScene.find(
        (n) =>
          n.is_hostile === true &&
          !(npcStates[n.id as string] as Record<string, unknown>)?.is_dead,
      );
      if (hostileNpc) {
        const counterDamage = Math.round(getNpcCounterDamage(hostileNpc) * 1.5);
        delta.hp = -counterDamage;
        events.push("NPC_COUNTER_ATTACKED");
        combatNarrationHints.push(
          `NPC_COUNTER_ATTACK:${hostileNpc.name} counter-attacks for ${counterDamage} damage.`,
        );
      } else {
        delta.hp = -5;
      }
    } else if (roll.tier === "CRITICAL_FAILURE") {
      delta.xp = 5;
      events.push("PLAYER_INJURED");
      // NPC deals devastating counter damage on critical failure
      const hostileNpc = npcsInScene.find(
        (n) =>
          n.is_hostile === true &&
          !(npcStates[n.id as string] as Record<string, unknown>)?.is_dead,
      );
      if (hostileNpc) {
        const counterDamage = getNpcCounterDamage(hostileNpc) * 2;
        delta.hp = -counterDamage;
        events.push("NPC_COUNTER_ATTACKED");
        combatNarrationHints.push(
          `NPC_COUNTER_ATTACK:${hostileNpc.name} lands a devastating blow for ${counterDamage} damage.`,
        );
      } else {
        delta.hp = -10;
      }
    }
  }

  return { delta, events, npcStateUpdates, combatNarrationHints };
}

// ── FIND TARGET NPC ───────────────────────────────────────────────
// Find which NPC the player is targeting based on action text.
function findTargetNpc(
  action: string,
  npcsInScene: Record<string, unknown>[],
): Record<string, unknown> | null {
  // First try to match by name
  for (const npc of npcsInScene) {
    const name = (npc.name as string).toLowerCase();
    if (action.includes(name.split(" ")[0].toLowerCase())) return npc;
  }
  // Default to first hostile NPC
  const hostile = npcsInScene.find((n) => n.is_hostile === true);
  return hostile ?? null;
}

// ── GET NPC HP ────────────────────────────────────────────────────
// Get current NPC HP from npc_states (tracks damage across turns).
function getNpcHp(
  npcId: string,
  npc: Record<string, unknown>,
  npcStates: Record<string, unknown>,
): number {
  const tracked = npcStates[npcId] as Record<string, unknown> | undefined;
  if (tracked?.hp !== undefined) return tracked.hp as number;
  return npc.hp_max as number ?? npc.hp as number ?? 20;
}

// ── RELATIONSHIP SCORING ──────────────────────────────────────────
// Returns which NPC was spoken to and the score delta.
// Tone is inferred from action text — positive, neutral, or hostile.

function computeRelationshipDelta(
  action: string,
  npcsInScene: Record<string, unknown>[],
): { npcId: string; npcName: string; delta: number } | null {
  const lower = action.toLowerCase();

  // Only fire on speak/social actions
  if (
    !/speak|talk|say|tell|ask|greet|thank|apologize|threaten|insult|persuade|intimidate|deceive|offer|promise/
      .test(lower)
  ) {
    return null;
  }

  // Find target NPC
  let targetNpc: Record<string, unknown> | null = null;
  for (const npc of npcsInScene) {
    const name = (npc.name as string).toLowerCase();
    const firstName = name.split(" ")[0];
    if (lower.includes(firstName)) {
      targetNpc = npc;
      break;
    }
  }
  // Default to first non-hostile NPC for general speech
  if (!targetNpc) {
    targetNpc = npcsInScene.find((n) => !n.is_hostile) ?? npcsInScene[0] ??
      null;
  }
  if (!targetNpc) return null;

  // Infer tone → score delta
  let delta = 1; // default: neutral speech is slightly positive
  if (
    /thank|help|ally|friend|trust|honest|kind|grateful|promise|protect/.test(
      lower,
    )
  ) delta = 4;
  if (/agree|cooperate|share|offer|assist|support/.test(lower)) delta = 3;
  if (
    /threaten|insult|betray|lie|deceive|manipulate|demand|accuse/.test(lower)
  ) delta = -4;
  if (/intimidate|coerce|force|attack verbally|mock|humiliate/.test(lower)) {
    delta = -3;
  }

  return {
    npcId: targetNpc.id as string,
    npcName: targetNpc.name as string,
    delta,
  };
}

// ── RELATIONSHIP TIER ─────────────────────────────────────────────
function getRelationshipTier(score: number): string {
  if (score <= -51) return "Hostile";
  if (score <= -11) return "Distrustful";
  if (score <= 10) return "Neutral";
  if (score <= 40) return "Warm";
  if (score <= 75) return "Loyal";
  return "Devoted";
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
    const npcStates = (campaignState.npc_states as Record<string, unknown>) ||
      {};

    if (beat.trigger_type === "NPC_DEFEATED") {
      const npcId = triggerData.npc_id as string;
      const npcState = npcStates[npcId] as Record<string, unknown> | undefined;
      if (npcState?.is_dead) triggered = true;
    }

    if (
      beat.trigger_type === "EVENT" &&
      events.includes(triggerData.event as string)
    ) {
      triggered = true;
    }

    if (beat.trigger_type === "ITEM_ACQUIRED") {
      const inventory = (state.inventory as unknown[]) || [];
      const hasItem = inventory.some(
        (i) => (i as Record<string, unknown>).item_id === triggerData.item_id,
      );
      if (hasItem) triggered = true;
    }

    if (triggered) {
      fired.push(beat.id);
      const consequences = beat.consequences as Record<string, unknown>;
      if (consequences.narration_hint) {
        narrationHints.push(consequences.narration_hint as string);
      }

      // Grant items from loot
      if (consequences.grant_items && Array.isArray(consequences.grant_items)) {
        const items = consequences.grant_items as string[];
        console.log("Granting items:", items);

        const { data: itemData, error: itemError } = await supabase
          .from("items")
          .select("id, name, description, rarity, item_type, effects")
          .in("id", items);

        console.log("Item data:", JSON.stringify(itemData));
        console.log("Item error:", JSON.stringify(itemError));

        if (itemData && itemData.length > 0) {
          const { data: currentState, error: stateError } = await supabase
            .from("canonical_state")
            .select("inventory")
            .eq("user_id", userId)
            .single();

          console.log(
            "Current inventory:",
            JSON.stringify(currentState?.inventory),
          );
          console.log("State error:", JSON.stringify(stateError));

          const currentInventory = (currentState?.inventory as unknown[]) ?? [];
          const newInventory = [...currentInventory, ...itemData];

          const { error: updateError } = await supabase
            .from("canonical_state")
            .update({ inventory: newInventory })
            .eq("user_id", userId);

          console.log("Inventory update error:", JSON.stringify(updateError));
        }
      }

      // Handle scene transition
      if (consequences.scene_transition) {
        const newScene = consequences.scene_transition as string;
        await supabase
          .from("canonical_state")
          .update({ current_location: newScene })
          .eq("user_id", userId);

        await supabase
          .from("player_campaign_state")
          .update({ current_scene: newScene })
          .eq("user_id", userId)
          .eq("campaign_id", campaignId);

        narrationHints.push(`SCENE_TRANSITION:${newScene}`);
      }

      // Handle quest completion
      if (consequences.quest_complete) {
        const questId = consequences.quest_complete as string;
        const { data: currentState } = await supabase
          .from("canonical_state")
          .select("quest_state")
          .eq("user_id", userId)
          .single();

        const questState =
          (currentState?.quest_state as Record<string, unknown>) ?? {};
        questState[questId] = { status: "completed" };

        await supabase
          .from("canonical_state")
          .update({ quest_state: questState })
          .eq("user_id", userId);
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
  npcStateUpdates: Record<string, unknown>,
): string {
  let ctx = `=== CANONICAL GAME STATE ===\n`;
  ctx += `Character: ${state.character_name} the ${state.character_class}\n`;
  ctx +=
    `HP: ${state.hp}/${state.hp_max} | MP: ${state.mp}/${state.mp_max} | Stamina: ${state.stamina}/${state.stamina_max}\n`;
  ctx += `Location: ${state.current_location}\n`;

  if (scene) {
    ctx += `\n=== CURRENT SCENE ===\n`;
    ctx += `${scene.title}: ${scene.description}\n`;
    ctx += `Atmosphere: ${scene.atmosphere}\n`;
  }

  if (npcsInScene.length > 0) {
    ctx += `\n=== NPCS PRESENT ===\n`;
    const relationships = (state.relationships as Record<string, unknown>) ??
      {};
    for (const npc of npcsInScene) {
      const rel = relationships[npc.id as string] as
        | Record<string, unknown>
        | undefined;
      const relInfo = rel ? ` | Relationship: ${rel.tier} (${rel.score})` : "";
      const npcId = npc.id as string;
      const trackedState =
        (npcStateUpdates as Record<string, unknown>)[npcId] as
        | Record<string, unknown>
        | undefined;
      const currentHp = trackedState?.hp ?? npc.hp_max ?? npc.hp;
      const isDead = trackedState?.is_dead ?? false;
      const status = isDead ? "DEFEATED" : `HP: ${currentHp}/${npc.hp_max}`;
      ctx +=
        `${npc.name} [${status}${relInfo}]: ${npc.description}. ${npc.personality}\n`;
    }
  }

  ctx += `\n=== THIS TURN ===\n`;
  ctx += `Player action: "${action}"\n`;
  if (roll) {
    ctx +=
      `Roll: d20=${roll.die}+${roll.modifier}=${roll.total} vs DC${roll.dc}. Outcome: ${roll.tier}.\n`;
  }
  if (delta.hp !== undefined) ctx += `HP change: ${delta.hp}.\n`;
  if (delta.stamina !== undefined) ctx += `Stamina cost: ${delta.stamina}.\n`;
  if (delta.xp !== undefined) ctx += `XP gained: ${delta.xp}.\n`;
  if (events.length) ctx += `Events: ${events.join(", ")}.\n`;

  if (narrationHints.length > 0) {
    const sceneTransitions = narrationHints.filter((h) =>
      h.startsWith("SCENE_TRANSITION:")
    );
    const counterAttacks = narrationHints.filter((h) =>
      h.startsWith("NPC_COUNTER_ATTACK:")
    );
    const storyHints = narrationHints.filter(
      (h) =>
        !h.startsWith("SCENE_TRANSITION:") &&
        !h.startsWith("NPC_COUNTER_ATTACK:"),
    );

    if (sceneTransitions.length > 0) {
      const newScene = sceneTransitions[0].replace("SCENE_TRANSITION:", "");
      ctx += `\n=== SCENE TRANSITION ===\n`;
      ctx += `The player has moved to: ${newScene.replaceAll("_", " ")}.\n`;
      ctx +=
        `Narrate the transition dramatically — describe leaving the old location and arriving somewhere new.\n`;
    }

    if (counterAttacks.length > 0) {
      ctx += `\n=== NPC COUNTER-ATTACK ===\n`;
      ctx += counterAttacks
        .map((h) => h.replace("NPC_COUNTER_ATTACK:", ""))
        .join("\n") + "\n";
      ctx +=
        `Narrate the NPC's counter-attack vividly — the player took this damage.\n`;
    }

    if (storyHints.length > 0) {
      ctx += `\n=== STORY BEAT TRIGGERED ===\n`;
      ctx += storyHints.join("\n") + "\n";
    }
  }

  ctx += `\n=== NARRATOR INSTRUCTIONS ===\n`;
  ctx +=
    `Narrate this turn in 2-4 vivid sentences. Second person present tense. Dark fantasy tone.\n`;
  ctx +=
    `Use the scene description and NPC personalities to ground the narration.\n`;
  ctx +=
    `The canonical state above is absolute truth. Never invent items, abilities, or outcomes not shown above.\n`;
  ctx +=
    `If a story beat was triggered, incorporate its hint dramatically into the narration.`;

  return ctx;
}

// ── SUMMARY TRIGGER EVALUATION ────────────────────────────────────
// Returns whether a summary job should be queued this turn,
// and updates the turn counter + cooldown on canonical_state.

async function evaluateSummaryTrigger(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  events: string[],
  currentTurnsSinceSummary: number,
  hardCooldown: number,
): Promise<
  {
    shouldQueue: boolean;
    isHard: boolean;
    newTurnCount: number;
    newCooldown: number;
  }
> {
  const hardTriggerPatterns = [
    "NPC_DEFEATED",
    "QUEST_UPDATED",
    "STORY_BEAT:",
    "RELATIONSHIP_TIER_CHANGED:",
    "PLAYER_INJURED",
    "LOCATION_CHANGED",
  ];

  const isHard = events.some((e) =>
    hardTriggerPatterns.some((p) => e.startsWith(p))
  );

  // Soft trigger: 8 turns since last summary, not suppressed by hard cooldown
  const softSuppressed = hardCooldown > 0;
  const isSoft = !softSuppressed && currentTurnsSinceSummary >= 7;

  const shouldQueue = isHard || isSoft;

  // Update counters
  const newTurnCount = shouldQueue ? 0 : currentTurnsSinceSummary + 1;
  const newCooldown = isHard ? 3 : Math.max(0, hardCooldown - 1);

  return { shouldQueue, isHard, newTurnCount, newCooldown };
}

// ── CODEX ──────────────────────────────────────────────────
// Writes lore entries to known_lore on real discovery events.
// Only writes entries the player doesn't already have (deduped by id).

async function updateCodex(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  events: string[],
  npcsInScene: Record<string, unknown>[],
  scene: Record<string, unknown> | null,
  currentKnownLore: unknown[],
  revisionId: string,
  npcStateUpdates: Record<string, unknown>,
  roll: RollResult | null,
  playerAction: string,
): Promise<void> {
  const existingIds = new Set(
    (currentKnownLore as Record<string, unknown>[]).map((e) => e.id as string),
  );
  const newEntries: Record<string, unknown>[] = [];

  // NPC first encounter
  for (const npc of npcsInScene) {
    const npcId = npc.id as string;
    const isDead =
      (npcStateUpdates[npcId] as Record<string, unknown>)?.is_dead ?? false;
    if (!existingIds.has(npcId) && !isDead) {
      newEntries.push({
        id: npcId,
        title: npc.name,
        category: "NPC",
        body: `${npc.description} ${npc.personality}`,
        discovered_at: revisionId,
      });
      existingIds.add(npcId);
    }
  }

  // Location first visit
  if (scene) {
    const sceneId = scene.id as string;
    if (!existingIds.has(sceneId)) {
      newEntries.push({
        id: sceneId,
        title: scene.title,
        category: "LOCATION",
        body: scene.description as string,
        discovered_at: revisionId,
      });
      existingIds.add(sceneId);
    }
  }

  // Successful search or investigate
  const lower = playerAction.toLowerCase();
  if (
    /search|investigate|examine/.test(lower) &&
    roll &&
    (roll.tier === "FULL_SUCCESS" || roll.tier === "CRITICAL_SUCCESS")
  ) {
    const sceneId = scene ? scene.id as string : "unknown_area";
    const loreId = `lore_search_${sceneId}`;
    if (!existingIds.has(loreId)) {
      newEntries.push({
        id: loreId,
        title: "Discovery",
        category: "LORE",
        body: `A successful search in ${scene?.title ?? "the area"} revealed hidden details.`,
        discovered_at: revisionId,
      });
      existingIds.add(loreId);
    }
  }

  if (newEntries.length === 0) return;

  const updatedLore = [...(currentKnownLore as unknown[]), ...newEntries];
  await supabase
    .from("canonical_state")
    .update({ known_lore: updatedLore })
    .eq("user_id", userId);
}


// ── MAIN ─────────────────────────────────────────────────────────

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers":
          "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  try {
    const packet: ActionPacket = await req.json();
    const {
      user_id,
      player_action,
      route_category,
      action_type,
      candidate_skill,
      gateway_decision,
      previous_revision_id,
    } = packet;

    if (gateway_decision === "REJECT" || route_category === "SAFE_REJECT") {
      return new Response(
        JSON.stringify({ error: "Action rejected by gateway" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SVC_ROLE_KEY")!,
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
        { status: 404, headers: { "Content-Type": "application/json" } },
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
      const skills = (state.skills as Record<string, number>) ?? {};
      const lower = player_action.toLowerCase();

      let modifier = 3; // base
      if (candidate_skill && skills[candidate_skill] !== undefined) {
        modifier = skills[candidate_skill];
      } else {
        if (action_type === "ATTACK" || /attack|strike|stab|slash|backstab/.test(lower)) {
          modifier = skills.dagger ?? skills.melee ?? skills.strength ?? 3;
        } else if (action_type === "STEALTH" || /sneak|hide|shadow/.test(lower)) {
          modifier = skills.stealth ?? 3;
        } else if (action_type === "SKILL_CHECK") {
          if (/pick lock|lockpick/.test(lower)) modifier = skills.lockpick ?? 3;
          else if (/persuade|intimidate|deceive|bluff/.test(lower)) modifier = skills.persuasion ?? skills.intimidate ?? 3;
          else if (/search|investigate/.test(lower)) modifier = skills.perception ?? 3;
          else modifier = 3;
        }
      }

      const dc = 14;
      roll = rollD20(modifier, dc);
    }

    const npcStates = (campaignState?.npc_states as Record<string, unknown>) ??
      {};
    const characterSkills = (state.skills as Record<string, number>) ?? {};
    const { delta, events, npcStateUpdates, combatNarrationHints } =
      computeDelta(
        player_action,
        action_type,
        roll,
        npcsInScene,
        npcStates,
        characterSkills,
      );

    // ── 6. Apply delta to canonical state ─────────────────────────
    const updatedState: Record<string, number> = {};
    if (delta.hp !== undefined) {
      updatedState.hp = Math.max(
        0,
        Math.min(state.hp_max, state.hp + delta.hp),
      );
    }
    if (delta.stamina !== undefined) {
      updatedState.stamina = Math.max(
        0,
        Math.min(state.stamina_max, state.stamina + delta.stamina),
      );
    }
    if (delta.mp !== undefined) {
      updatedState.mp = Math.max(
        0,
        Math.min(state.mp_max, state.mp + delta.mp),
      );
    }
    if (delta.xp !== undefined) {
      updatedState.xp = state.xp + delta.xp;
    }
    if (delta.gold !== undefined) {
      updatedState.gold = state.gold + delta.gold;
    }

    // ── 6b. Save NPC state updates ────────────────────────────────
    const mergedNpcStates = { ...npcStates, ...npcStateUpdates };
    if (Object.keys(npcStateUpdates).length > 0) {
      await supabase
        .from("player_campaign_state")
        .update({
          npc_states: mergedNpcStates,
          last_played_at: new Date().toISOString(),
        })
        .eq("user_id", user_id)
        .eq("campaign_id", state.campaign_id);
    }

    // ── 6c. Handle item consumption ───────────────────────────────
    if (events.includes("ITEM_USED")) {
      const lower = player_action.toLowerCase();
      const inventory = (state.inventory as Record<string, unknown>[]) ?? [];

      // Find which consumable was used
      const consumablePatterns: Record<string, string> = {
        "item_healing_salve": /salve|healing salve/.source,
      };

      let usedItemId: string | null = null;
      for (const [itemId, pattern] of Object.entries(consumablePatterns)) {
        if (new RegExp(pattern).test(lower)) {
          usedItemId = itemId;
          break;
        }
      }

      // Default to first consumable if pattern didn't match
      if (!usedItemId) {
        const consumable = inventory.find(
          (i) => i.item_type === "consumable",
        );
        if (consumable) usedItemId = consumable.id as string;
      }

      if (usedItemId) {
        const hasItem = inventory.some((i) => i.id === usedItemId);
        if (hasItem) {
          // Remove one instance of the item
          const itemIndex = inventory.findIndex((i) => i.id === usedItemId);
          const newInventory = [
            ...inventory.slice(0, itemIndex),
            ...inventory.slice(itemIndex + 1),
          ];
          await supabase
            .from("canonical_state")
            .update({ inventory: newInventory })
            .eq("user_id", user_id);

          events.push("ITEM_CONSUMED");
        } else {
          // Player doesn't have the item — remove the HP delta
          delta.hp = undefined;
          events.push("ITEM_NOT_FOUND");
        }
      }
    }

    // ── 6d. Update relationship scores ───────────────────────────
    const relationshipDelta = computeRelationshipDelta(
      player_action,
      npcsInScene,
    );
    if (relationshipDelta) {
      const relationships = (state.relationships as Record<string, unknown>) ??
        {};
      const current = relationships[relationshipDelta.npcId] as
        | Record<string, unknown>
        | undefined;
      const currentScore = (current?.score as number) ?? 0;
      const newScore = Math.max(
        -100,
        Math.min(100, currentScore + relationshipDelta.delta),
      );
      const oldTier = getRelationshipTier(currentScore);
      const newTier = getRelationshipTier(newScore);

      relationships[relationshipDelta.npcId] = {
        name: relationshipDelta.npcName,
        score: newScore,
        tier: newTier,
      };

      await supabase
        .from("canonical_state")
        .update({ relationships })
        .eq("user_id", user_id);

      // Emit tier change event if threshold crossed
      if (oldTier !== newTier) {
        events.push(
          `RELATIONSHIP_TIER_CHANGED:${relationshipDelta.npcId}:${newTier}`,
        );
      }
    }

    // ── 7. Write canonical state ──────────────────────────────────
    const revision_id = generateRevisionId();
    const { error: updateError } = await supabase
      .from("canonical_state")
      .update({ ...updatedState, updated_at: new Date().toISOString() })
      .eq("user_id", user_id);

    if (updateError) throw updateError;

    // ── 7b. Update codex on discovery events ─────────────────────
    await updateCodex(
      supabase,
      user_id,
      events,
      npcsInScene,
      scene,
      (state.known_lore as unknown[]) ?? [],
      revision_id,
      npcStateUpdates,
      roll,
      player_action,
    );

    // ── 8. Check story beats ──────────────────────────────────────
    const { fired: beatsFired, narrationHints: beatNarrationHints } =
      await checkStoryBeats(
        supabase,
        user_id,
        state.campaign_id,
        events,
        { ...state, ...updatedState },
        {
          ...(campaignState || {}),
          npc_states: mergedNpcStates,
        },
      );

    if (beatsFired.length > 0) {
      events.push(...beatsFired.map((id) => `STORY_BEAT:${id}`));
    }

    // Merge story beat hints with combat counter-attack hints
    const narrationHints = [...beatNarrationHints, ...combatNarrationHints];

    // ── 8b. Evaluate summary trigger ─────────────────────────────
    const turnsSinceSummary = (state.turns_since_last_summary as number) ?? 0;
    const hardCooldown = (state.hard_summary_cooldown as number) ?? 0;

    const { shouldQueue, isHard, newTurnCount, newCooldown } =
      await evaluateSummaryTrigger(
        supabase,
        user_id,
        events,
        turnsSinceSummary,
        hardCooldown,
      );

    // Update summary tracking fields on canonical_state
    await supabase
      .from("canonical_state")
      .update({
        turns_since_last_summary: newTurnCount,
        hard_summary_cooldown: newCooldown,
        last_summary_type: shouldQueue
          ? (isHard ? "hard" : "soft")
          : state.last_summary_type,
      })
      .eq("user_id", user_id);

    // ── 9. Commit revision ────────────────────────────────────────
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
        summary_job_queued: shouldQueue,
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
        })),
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
      npcStateUpdates,
    );

    return new Response(
      JSON.stringify({
        revision_id,
        success_tier: roll?.tier ?? "NO_ROLL",
        roll,
        state_delta: delta,
        events,
        autosave_candidate,
        summary_job_queued: shouldQueue,
        narration_context,
        npc_states: { ...npcStates, ...npcStateUpdates },
        npcs_in_scene: npcsInScene.map((npc) => ({
          id: npc.id,
          name: npc.name,
          hp_max: npc.hp_max,
          is_hostile: npc.is_hostile,
        })),
      }),
      {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      },
    );
  } catch (err) {
    console.error("simulation_service error:", err);
    return new Response(
      JSON.stringify({ error: String(err) }),
      {
        status: 500,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      },
    );
  }
});
