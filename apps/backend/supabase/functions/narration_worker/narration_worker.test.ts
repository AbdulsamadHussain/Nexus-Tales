import { assertEquals, assertStringIncludes } from "https://deno.land/std@0.168.0/testing/asserts.ts";
import { buildFallbackNarration } from "./index.ts";

// ── Fallback narration (§11.1) ────────────────────────────────────

function ctx(action: string, roll = "", hp = ""): string {
  return [
    `Player action: "${action}"`,
    roll ? `Roll: ${roll}` : "",
    hp ? `HP change: ${hp}` : "",
  ].filter(Boolean).join("\n");
}

Deno.test("fallback: action line extracted into prose", () => {
  const result = buildFallbackNarration(ctx("attack the bandit"));
  assertStringIncludes(result.toLowerCase(), "attack the bandit");
});

Deno.test("fallback: FULL_SUCCESS roll → ' The attempt succeeds.'", () => {
  const result = buildFallbackNarration(ctx("strike", "FULL_SUCCESS"));
  assertStringIncludes(result, "The attempt succeeds");
});

Deno.test("fallback: CRITICAL_SUCCESS roll → ' The attempt succeeds.'", () => {
  const result = buildFallbackNarration(ctx("charge", "CRITICAL_SUCCESS"));
  assertStringIncludes(result, "The attempt succeeds");
});

Deno.test("fallback: FAILURE roll → ' The attempt fails.'", () => {
  const result = buildFallbackNarration(ctx("sneak", "FAILURE"));
  assertStringIncludes(result, "The attempt fails");
});

Deno.test("fallback: hp loss → ' You take damage.'", () => {
  const result = buildFallbackNarration(ctx("attack", "", "-8"));
  assertStringIncludes(result, "You take damage");
});

Deno.test("fallback: no roll, no hp change → minimal prose returned", () => {
  const result = buildFallbackNarration(ctx("I look around"));
  assertEquals(result.trim().length > 0, true);
});

// ── </think> stripping regression ────────────────────────────────
// Documents that the worker uses </think>, not <tool_call> (fixed bug).
// We test buildFallbackNarration is still called when Ollama is unavailable —
// the stripping logic lives in the serve handler and is covered by integration tests.

Deno.test("fallback: returns string, never throws", () => {
  const result = buildFallbackNarration("Player action: \"do something\"\nRoll: PARTIAL_SUCCESS\nHP change: -3");
  assertEquals(typeof result, "string");
  assertEquals(result.length > 0, true);
});
