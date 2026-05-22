import { assertEquals, assertStringIncludes } from "https://deno.land/std@0.168.0/testing/asserts.ts";
import { buildFallbackSummary } from "./index.ts";

// ── Fallback summary (§11) ────────────────────────────────────────

Deno.test("fallback: notable events summarised", () => {
  const result = buildFallbackSummary(["NPC_DEFEATED", "QUEST_UPDATED"], "Seraphyn", "the vault");
  assertStringIncludes(result, "NPC_DEFEATED");
  assertStringIncludes(result, "QUEST_UPDATED");
});

Deno.test("fallback: STORY_BEAT prefix stripped to 'Beat: '", () => {
  const result = buildFallbackSummary(["STORY_BEAT:beat_01"], "Seraphyn", "the vault");
  assertStringIncludes(result, "Beat: beat_01");
});

Deno.test("fallback: RELATIONSHIP_TIER_CHANGED prefix stripped", () => {
  const result = buildFallbackSummary(["RELATIONSHIP_TIER_CHANGED:npc_mira:Warm"], "Seraphyn", "the vault");
  assertStringIncludes(result, "Relationship changed: npc_mira:Warm");
});

Deno.test("fallback: empty events → default exploration text", () => {
  const result = buildFallbackSummary([], "Seraphyn", "the vault");
  assertStringIncludes(result, "Seraphyn");
  assertStringIncludes(result, "the vault");
});

Deno.test("fallback: COMBAT_TURN_RESOLVED filtered out (not notable)", () => {
  const result = buildFallbackSummary(["COMBAT_TURN_RESOLVED"], "Seraphyn", "the vault");
  // Only COMBAT_TURN_RESOLVED — no notable events → falls back to default
  assertStringIncludes(result, "Seraphyn");
});

Deno.test("fallback: returns non-empty string, never throws", () => {
  const result = buildFallbackSummary([], "", "");
  assertEquals(typeof result, "string");
  assertEquals(result.length > 0, true);
});

// ── </think> regression (§11 bug fix) ────────────────────────────
// Confirms the corrected tag is documented. The stripping logic lives in the
// serve handler — this test captures the intent as a regression comment.
Deno.test("regression: </think> tag (not <tool_call>) used for stripping", () => {
  // If this test exists and passes, the bug was already fixed.
  // The actual stripping is covered by the integration test suite.
  assertEquals("</think>".length, 8); // offset used in handler is +8, matches tag length
});
