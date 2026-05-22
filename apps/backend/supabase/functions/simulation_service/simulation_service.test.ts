import { assertEquals, assertExists, assertNotEquals } from "https://deno.land/std@0.168.0/testing/asserts.ts";
import {
  rollD20,
  computeDelta,
  getNpcCounterDamage,
  findTargetNpc,
  getNpcHp,
  getRelationshipTier,
  evaluateSummaryTrigger,
  generateRevisionId,
} from "./index.ts";

// ── Roll math (§7.2) ─────────────────────────────────────────────

Deno.test("roll: nat 20 → CRITICAL_SUCCESS regardless of modifier", () => {
  const orig = Math.random;
  try {
    Math.random = () => 19 / 20; // die = floor(19/20 * 20) + 1 = 20
    const r = rollD20(0, 14);
    assertEquals(r.die, 20);
    assertEquals(r.tier, "CRITICAL_SUCCESS");
  } finally {
    Math.random = orig;
  }
});

Deno.test("roll: nat 1 → CRITICAL_FAILURE regardless of modifier", () => {
  const orig = Math.random;
  try {
    Math.random = () => 0; // die = 1
    const r = rollD20(10, 14); // high modifier — still CRITICAL_FAILURE due to nat 1 priority
    assertEquals(r.die, 1);
    assertEquals(r.tier, "CRITICAL_FAILURE");
  } finally {
    Math.random = orig;
  }
});

Deno.test("roll: total ≥ dc+6 → CRITICAL_SUCCESS", () => {
  // die=15, modifier=5, total=20, dc=14 → total ≥ 20 → CRITICAL_SUCCESS
  const orig = Math.random;
  Math.random = () => 14 / 20; // die=15
  const r = rollD20(5, 14);
  assertEquals(r.total >= r.dc + 6, true);
  assertEquals(r.tier, "CRITICAL_SUCCESS");
  Math.random = orig;
});

Deno.test("roll: total ≥ dc and < dc+6 → FULL_SUCCESS", () => {
  // die=12, modifier=2, total=14, dc=14 → FULL_SUCCESS
  const orig = Math.random;
  Math.random = () => 11 / 20; // die=12
  const r = rollD20(2, 14);
  assertEquals(r.total, 14);
  assertEquals(r.tier, "FULL_SUCCESS");
  Math.random = orig;
});

Deno.test("roll: dc-4 ≤ total < dc → PARTIAL_SUCCESS", () => {
  // die=8, modifier=2, total=10, dc=14 → 10 ≥ 10 → PARTIAL_SUCCESS
  const orig = Math.random;
  Math.random = () => 7 / 20; // die=8
  const r = rollD20(2, 14);
  assertEquals(r.total, 10);
  assertEquals(r.tier, "PARTIAL_SUCCESS");
  Math.random = orig;
});

Deno.test("roll: dc-8 < total < dc-4 → FAILURE", () => {
  // die=5, modifier=2, total=7, dc=14 → 7 < 10 (dc-4) and 7 > 6 (dc-8) → FAILURE
  const orig = Math.random;
  Math.random = () => 4 / 20; // die=5
  const r = rollD20(2, 14);
  assertEquals(r.total, 7);
  assertEquals(r.tier, "FAILURE");
  Math.random = orig;
});

Deno.test("roll: total ≤ dc-8 → CRITICAL_FAILURE", () => {
  // die=2, modifier=2, total=4, dc=14 → 4 ≤ 6 → CRITICAL_FAILURE
  const orig = Math.random;
  Math.random = () => 1 / 20; // die=2
  const r = rollD20(2, 14);
  assertEquals(r.total, 4);
  assertEquals(r.tier, "CRITICAL_FAILURE");
  Math.random = orig;
});

// ── Delta computation (§7.1) ──────────────────────────────────────

const hostile: Record<string, unknown> = {
  id: "npc_bandit",
  name: "Bandit",
  is_hostile: true,
  hp_max: 20,
  attack_damage: 6,
};
const deadHostile: Record<string, unknown> = { ...hostile, id: "npc_dead" };
const npcStatesWithDead: Record<string, unknown> = { npc_dead: { hp: 0, is_dead: true } };
const noNpcs: Record<string, unknown>[] = [];

function makeRoll(tier: string, die = 10): ReturnType<typeof rollD20> {
  return { die, modifier: 3, total: die + 3, dc: 14, tier: tier as never };
}

Deno.test("delta: REST → stamina +8, hp +2, no events except PLAYER_RESTED", () => {
  const { delta, events } = computeDelta("I rest", "REST", null, noNpcs, {}, {});
  assertEquals(delta.stamina, 8);
  assertEquals(delta.hp, 2);
  assertEquals(events.includes("PLAYER_RESTED"), true);
  assertEquals(events.includes("NPC_COUNTER_ATTACKED"), false);
});

Deno.test("delta: USE_ITEM → hp +12, ITEM_USED event, no counter", () => {
  const { delta, events } = computeDelta("I drink the potion", "USE_ITEM", null, noNpcs, {}, {});
  assertEquals(delta.hp, 12);
  assertEquals(events.includes("ITEM_USED"), true);
  assertEquals(events.includes("NPC_COUNTER_ATTACKED"), false);
});

Deno.test("delta: ATTACK + CRITICAL_SUCCESS → NPC takes 15 dmg, no counter, xp +30", () => {
  const roll = makeRoll("CRITICAL_SUCCESS", 20);
  const { delta, events, npcStateUpdates } = computeDelta("I attack the bandit", "ATTACK", roll, [hostile], {}, {});
  assertEquals((npcStateUpdates["npc_bandit"] as Record<string, unknown>)?.hp, 5); // 20 - 15
  assertEquals(events.includes("NPC_COUNTER_ATTACKED"), false);
  assertEquals(delta.xp, 30);
});

Deno.test("delta: ATTACK + FULL_SUCCESS → NPC takes 9 dmg, no counter, xp +20", () => {
  const roll = makeRoll("FULL_SUCCESS", 14);
  const { delta, events, npcStateUpdates } = computeDelta("I attack the bandit", "ATTACK", roll, [hostile], {}, {});
  assertEquals((npcStateUpdates["npc_bandit"] as Record<string, unknown>)?.hp, 11); // 20 - 9
  assertEquals(events.includes("NPC_COUNTER_ATTACKED"), false);
  assertEquals(delta.xp, 20);
});

Deno.test("delta: ATTACK + PARTIAL_SUCCESS → NPC takes 4 dmg, counter fires, xp +10", () => {
  const roll = makeRoll("PARTIAL_SUCCESS", 12);
  const { delta, events, npcStateUpdates } = computeDelta("I attack the bandit", "ATTACK", roll, [hostile], {}, {});
  assertEquals((npcStateUpdates["npc_bandit"] as Record<string, unknown>)?.hp, 16); // 20 - 4
  assertEquals(events.includes("NPC_COUNTER_ATTACKED"), true);
  assertEquals(delta.hp, -6); // attack_damage = 6
  assertEquals(delta.xp, 10);
});

Deno.test("delta: ATTACK + FAILURE → hostile NPC counter at 1.5× damage", () => {
  const roll = makeRoll("FAILURE", 7);
  const { delta, events } = computeDelta("I attack the bandit", "ATTACK", roll, [hostile], {}, {});
  assertEquals(events.includes("NPC_COUNTER_ATTACKED"), true);
  assertEquals(delta.hp, -9); // round(6 * 1.5) = 9
});

Deno.test("delta: ATTACK + CRITICAL_FAILURE → NPC counter at 2× damage, PLAYER_INJURED", () => {
  const roll = makeRoll("CRITICAL_FAILURE", 1);
  const { delta, events } = computeDelta("I attack the bandit", "ATTACK", roll, [hostile], {}, {});
  assertEquals(events.includes("NPC_COUNTER_ATTACKED"), true);
  assertEquals(events.includes("PLAYER_INJURED"), true);
  assertEquals(delta.hp, -12); // 6 * 2
});

Deno.test("delta: dead NPC never counter-attacks", () => {
  const roll = makeRoll("FAILURE", 7);
  const { events } = computeDelta("I attack the dead", "ATTACK", roll, [deadHostile], npcStatesWithDead, {});
  assertEquals(events.includes("NPC_COUNTER_ATTACKED"), false);
});

// ── One-turn-one-revision invariant (§1, §8.1) ────────────────────

Deno.test("invariant: generateRevisionId produces unique ids", () => {
  const ids = new Set(Array.from({ length: 100 }, () => generateRevisionId()));
  // With 100 samples from a 900k range, collisions are astronomically unlikely
  assertEquals(ids.size > 90, true);
});

Deno.test("invariant: revision id format is rev_NNNNNN", () => {
  const id = generateRevisionId();
  assertExists(id.match(/^rev_\d{6}$/));
});

// ── NPC helpers ───────────────────────────────────────────────────

Deno.test("getNpcCounterDamage: returns attack_damage field", () => {
  assertEquals(getNpcCounterDamage({ attack_damage: 8 }), 8);
});

Deno.test("getNpcCounterDamage: falls back to 5 if missing", () => {
  assertEquals(getNpcCounterDamage({}), 5);
});

Deno.test("findTargetNpc: matches by first name in action text", () => {
  const npcs = [hostile, { id: "npc_other", name: "Mira Voss", is_hostile: false, hp_max: 10 }];
  const result = findTargetNpc("I attack mira", npcs as never);
  assertEquals((result as Record<string, unknown>)?.id, "npc_other");
});

Deno.test("findTargetNpc: falls back to first hostile", () => {
  const result = findTargetNpc("I attack someone", [hostile] as never);
  assertEquals((result as Record<string, unknown>)?.id, "npc_bandit");
});

Deno.test("getNpcHp: uses tracked hp if available", () => {
  assertEquals(getNpcHp("npc_bandit", hostile, { npc_bandit: { hp: 12 } }), 12);
});

Deno.test("getNpcHp: falls back to hp_max from npc data", () => {
  assertEquals(getNpcHp("npc_bandit", hostile, {}), 20);
});

// ── Relationship tiers (§9.2) ─────────────────────────────────────

Deno.test("tier: -100 → Hostile", () => assertEquals(getRelationshipTier(-100), "Hostile"));
Deno.test("tier: -51 → Hostile", () => assertEquals(getRelationshipTier(-51), "Hostile"));
Deno.test("tier: -50 → Distrustful", () => assertEquals(getRelationshipTier(-50), "Distrustful"));
Deno.test("tier: -11 → Distrustful", () => assertEquals(getRelationshipTier(-11), "Distrustful"));
Deno.test("tier: -10 → Neutral", () => assertEquals(getRelationshipTier(-10), "Neutral"));
Deno.test("tier: 0 → Neutral", () => assertEquals(getRelationshipTier(0), "Neutral"));
Deno.test("tier: 10 → Neutral", () => assertEquals(getRelationshipTier(10), "Neutral"));
Deno.test("tier: 11 → Warm", () => assertEquals(getRelationshipTier(11), "Warm"));
Deno.test("tier: 40 → Warm", () => assertEquals(getRelationshipTier(40), "Warm"));
Deno.test("tier: 41 → Loyal", () => assertEquals(getRelationshipTier(41), "Loyal"));
Deno.test("tier: 75 → Loyal", () => assertEquals(getRelationshipTier(75), "Loyal"));
Deno.test("tier: 76 → Devoted", () => assertEquals(getRelationshipTier(76), "Devoted"));
Deno.test("tier: 100 → Devoted", () => assertEquals(getRelationshipTier(100), "Devoted"));

// ── Summary triggers (§9.1) ───────────────────────────────────────
// evaluateSummaryTrigger takes a supabase client (unused in unit path) — pass null.

Deno.test("summary: hard event → shouldQueue true, newCooldown = 3", async () => {
  const result = await evaluateSummaryTrigger(null as never, "u1", ["NPC_DEFEATED"], 0, 0);
  assertEquals(result.shouldQueue, true);
  assertEquals(result.isHard, true);
  assertEquals(result.newCooldown, 3);
  assertEquals(result.newTurnCount, 0);
});

Deno.test("summary: QUEST_UPDATED → hard trigger", async () => {
  const result = await evaluateSummaryTrigger(null as never, "u1", ["QUEST_UPDATED"], 0, 0);
  assertEquals(result.isHard, true);
  assertEquals(result.shouldQueue, true);
});

Deno.test("summary: RELATIONSHIP_TIER_CHANGED: → hard trigger", async () => {
  const result = await evaluateSummaryTrigger(null as never, "u1", ["RELATIONSHIP_TIER_CHANGED:npc_foo:Warm"], 0, 0);
  assertEquals(result.isHard, true);
});

Deno.test("summary: soft trigger fires at turn 7 with no cooldown", async () => {
  const result = await evaluateSummaryTrigger(null as never, "u1", [], 7, 0);
  assertEquals(result.shouldQueue, true);
  assertEquals(result.isHard, false);
  assertEquals(result.newTurnCount, 0);
});

Deno.test("summary: soft suppressed when cooldown > 0", async () => {
  const result = await evaluateSummaryTrigger(null as never, "u1", [], 7, 2);
  assertEquals(result.shouldQueue, false);
  assertEquals(result.newCooldown, 1); // decrements
});

Deno.test("summary: hard never suppressed even when cooldown active", async () => {
  const result = await evaluateSummaryTrigger(null as never, "u1", ["NPC_DEFEATED"], 0, 2);
  assertEquals(result.shouldQueue, true);
  assertEquals(result.isHard, true);
  assertEquals(result.newCooldown, 3); // resets to 3
});

Deno.test("summary: no trigger at turn 6 → counter increments", async () => {
  const result = await evaluateSummaryTrigger(null as never, "u1", [], 6, 0);
  assertEquals(result.shouldQueue, false);
  assertEquals(result.newTurnCount, 7);
});

Deno.test("summary: after queue fires, turn count resets to 0", async () => {
  const result = await evaluateSummaryTrigger(null as never, "u1", ["NPC_DEFEATED"], 5, 0);
  assertEquals(result.shouldQueue, true);
  assertEquals(result.newTurnCount, 0);
});
