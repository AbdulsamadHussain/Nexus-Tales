/**
 * Unit tests for canonical_command pure exports.
 *
 * Tests ITEM_CATALOGUE structure, CLASS_SKILLS structure, and the
 * buildProfilePatch helper — all pure functions with no I/O.
 *
 * Run: deno test --allow-env supabase/functions/canonical_command/
 *
 * Note: the module also imports @supabase/supabase-js and deno std/http
 * (HTTP handler lives behind `if (import.meta.main)`), so first-run
 * may require --allow-net for Deno to resolve the remote imports.
 */

import {
  assertEquals,
  assertExists,
} from "https://deno.land/std@0.168.0/testing/asserts.ts";
import {
  ITEM_CATALOGUE,
  CLASS_SKILLS,
  buildProfilePatch,
} from "./index.ts";

// ── ITEM_CATALOGUE structure ──────────────────────────────────────────────

Deno.test("ITEM_CATALOGUE: all items have required fields with correct types", () => {
  const items = Object.entries(ITEM_CATALOGUE);
  assertEquals(items.length > 0, true, "catalogue must not be empty");

  for (const [key, item] of items) {
    // id must match the catalogue key (server uses the key, not the id field)
    assertEquals(item.id, key, `${key}: id must match catalogue key`);
    // name is a non-empty string
    assertEquals(typeof item.name, "string", `${key}: name must be string`);
    assertEquals(item.name.length > 0, true, `${key}: name must be non-empty`);
    // desc is a string
    assertEquals(typeof item.desc, "string", `${key}: desc must be string`);
    // cost is a positive integer (never free; free items cannot be trusted from server)
    assertEquals(typeof item.cost, "number", `${key}: cost must be number`);
    assertEquals(item.cost > 0, true, `${key}: cost must be positive`);
    assertEquals(Number.isInteger(item.cost), true, `${key}: cost must be integer`);
    // item_type and rarity must be non-empty strings
    assertEquals(typeof item.item_type, "string", `${key}: item_type must be string`);
    assertEquals(item.item_type.length > 0, true, `${key}: item_type must be non-empty`);
    assertEquals(typeof item.rarity, "string", `${key}: rarity must be string`);
    assertEquals(item.rarity.length > 0, true, `${key}: rarity must be non-empty`);
  }
});

Deno.test("ITEM_CATALOGUE: known items have correct server-authoritative costs", () => {
  // These costs are authoritative; the server never trusts the client's price.
  // Changing a cost here (the only place) automatically propagates to the RPC call.
  assertExists(ITEM_CATALOGUE["item_healing_salve"]);
  assertEquals(ITEM_CATALOGUE["item_healing_salve"].cost, 15);
  assertEquals(ITEM_CATALOGUE["item_healing_salve"].item_type, "consumable");
  assertEquals(ITEM_CATALOGUE["item_healing_salve"].rarity, "common");

  assertExists(ITEM_CATALOGUE["item_mana_tonic"]);
  assertEquals(ITEM_CATALOGUE["item_mana_tonic"].cost, 18);

  assertExists(ITEM_CATALOGUE["item_stamina_draught"]);
  assertEquals(ITEM_CATALOGUE["item_stamina_draught"].cost, 12);

  assertExists(ITEM_CATALOGUE["item_iron_ration"]);
  assertEquals(ITEM_CATALOGUE["item_iron_ration"].cost, 5);  // cheapest item

  assertExists(ITEM_CATALOGUE["item_smoke_bomb"]);
  assertEquals(ITEM_CATALOGUE["item_smoke_bomb"].cost, 25);
  assertEquals(ITEM_CATALOGUE["item_smoke_bomb"].rarity, "rare");

  assertExists(ITEM_CATALOGUE["item_revive_charm"]);
  assertEquals(ITEM_CATALOGUE["item_revive_charm"].cost, 60);
  assertEquals(ITEM_CATALOGUE["item_revive_charm"].rarity, "legendary");
});

// ── CLASS_SKILLS structure ────────────────────────────────────────────────

Deno.test("CLASS_SKILLS: all five classes present", () => {
  const expectedClasses = ["Rogue", "War Mage", "Warden", "Plague Doctor", "Hex Blade"];
  for (const cls of expectedClasses) {
    assertExists(CLASS_SKILLS[cls], `CLASS_SKILLS missing class: "${cls}"`);
  }
});

Deno.test("CLASS_SKILLS: each class has exactly 5 skills with non-empty name and desc", () => {
  for (const [cls, skills] of Object.entries(CLASS_SKILLS)) {
    const skillEntries = Object.entries(skills);
    assertEquals(skillEntries.length, 5, `${cls}: expected exactly 5 skills, got ${skillEntries.length}`);
    for (const [skillId, skill] of skillEntries) {
      assertEquals(typeof skill.name, "string", `${cls}.${skillId}: name must be string`);
      assertEquals(skill.name.length > 0, true, `${cls}.${skillId}: name must be non-empty`);
      assertEquals(typeof skill.desc, "string", `${cls}.${skillId}: desc must be string`);
      assertEquals(skill.desc.length > 0, true, `${cls}.${skillId}: desc must be non-empty`);
    }
  }
});

Deno.test("CLASS_SKILLS: spot-check specific skills across all classes", () => {
  // Rogue
  assertExists(CLASS_SKILLS["Rogue"]["shadow_step"]);
  assertEquals(CLASS_SKILLS["Rogue"]["shadow_step"].name, "Shadow Step");
  assertExists(CLASS_SKILLS["Rogue"]["vanish"]);
  assertExists(CLASS_SKILLS["Rogue"]["blade_dance"]);

  // War Mage
  assertExists(CLASS_SKILLS["War Mage"]["arcane_burst"]);
  assertEquals(CLASS_SKILLS["War Mage"]["arcane_burst"].name, "Arcane Burst");
  assertExists(CLASS_SKILLS["War Mage"]["chain_lightning"]);

  // Warden
  assertExists(CLASS_SKILLS["Warden"]["iron_guard"]);
  assertEquals(CLASS_SKILLS["Warden"]["iron_guard"].name, "Iron Guard");
  assertExists(CLASS_SKILLS["Warden"]["bulwark"]);

  // Plague Doctor
  assertExists(CLASS_SKILLS["Plague Doctor"]["antidote"]);
  assertEquals(CLASS_SKILLS["Plague Doctor"]["antidote"].name, "Antidote");
  assertExists(CLASS_SKILLS["Plague Doctor"]["field_medicine"]);

  // Hex Blade
  assertExists(CLASS_SKILLS["Hex Blade"]["dark_pact"]);
  assertEquals(CLASS_SKILLS["Hex Blade"]["dark_pact"].name, "Dark Pact");
  assertExists(CLASS_SKILLS["Hex Blade"]["curse"]);
});

Deno.test("CLASS_SKILLS: no skill_id appears in more than one class (no cross-class pollution)", () => {
  const allSkillIds: Map<string, string> = new Map(); // skillId → className
  for (const [cls, skills] of Object.entries(CLASS_SKILLS)) {
    for (const skillId of Object.keys(skills)) {
      const seenIn = allSkillIds.get(skillId);
      assertEquals(seenIn, undefined, `Skill "${skillId}" appears in both "${seenIn}" and "${cls}"`);
      allSkillIds.set(skillId, cls);
    }
  }
});

// ── buildProfilePatch ─────────────────────────────────────────────────────

Deno.test("buildProfilePatch: empty body → empty patch object", () => {
  const patch = buildProfilePatch({});
  assertEquals(Object.keys(patch).length, 0);
});

Deno.test("buildProfilePatch: undefined fields → not included in patch", () => {
  // Only fields explicitly provided should appear in the patch.
  const patch = buildProfilePatch({ character_name: "Arath" });
  assertEquals("origin" in patch, false, "origin must not appear when undefined");
  assertEquals("backstory" in patch, false, "backstory must not appear when undefined");
});

Deno.test("buildProfilePatch: whitespace-only character_name → excluded (empty after trim)", () => {
  const patch = buildProfilePatch({ character_name: "   " });
  assertEquals("character_name" in patch, false, "blank character_name must be excluded");
});

Deno.test("buildProfilePatch: valid character_name → included and trimmed", () => {
  const patch = buildProfilePatch({ character_name: "  Arath  " });
  assertEquals(patch.character_name, "Arath");
});

Deno.test("buildProfilePatch: character_name sliced to 80 chars", () => {
  const longName = "A".repeat(100);
  const patch = buildProfilePatch({ character_name: longName });
  assertExists(patch.character_name);
  assertEquals(patch.character_name.length, 80);
});

Deno.test("buildProfilePatch: origin explicitly empty string → included (intentional field clear)", () => {
  // Empty origin is a valid intentional clear — the player is resetting the field.
  const patch = buildProfilePatch({ origin: "" });
  assertEquals("origin" in patch, true, "explicit empty origin must be included");
  assertEquals(patch.origin, "");
});

Deno.test("buildProfilePatch: origin sliced to 200 chars", () => {
  const patch = buildProfilePatch({ origin: "X".repeat(300) });
  assertExists(patch.origin);
  assertEquals(patch.origin.length, 200);
});

Deno.test("buildProfilePatch: backstory explicitly empty string → included (intentional field clear)", () => {
  const patch = buildProfilePatch({ backstory: "" });
  assertEquals("backstory" in patch, true, "explicit empty backstory must be included");
  assertEquals(patch.backstory, "");
});

Deno.test("buildProfilePatch: backstory sliced to 2000 chars", () => {
  const patch = buildProfilePatch({ backstory: "Z".repeat(3000) });
  assertExists(patch.backstory);
  assertEquals(patch.backstory.length, 2000);
});

Deno.test("buildProfilePatch: all three fields together — correct values and count", () => {
  const patch = buildProfilePatch({
    character_name: "Arath",
    origin: "A wandering swordsman",
    backstory: "Born in a small village under twin moons.",
  });
  assertEquals(patch.character_name, "Arath");
  assertEquals(patch.origin, "A wandering swordsman");
  assertEquals(patch.backstory, "Born in a small village under twin moons.");
  assertEquals(Object.keys(patch).length, 3);
});

Deno.test("buildProfilePatch: origin and backstory trimmed before slicing", () => {
  const patch = buildProfilePatch({
    origin: "  hello  ",
    backstory: "  world  ",
  });
  assertEquals(patch.origin, "hello");
  assertEquals(patch.backstory, "world");
});

Deno.test("buildProfilePatch: character_name trim then slice — only non-blank chars count toward 80 limit", () => {
  // "  " + 79 "A" chars + "  " — after trim = 79 "A"s; all fit within 80 limit
  const padded = "  " + "A".repeat(79) + "  ";
  const patch = buildProfilePatch({ character_name: padded });
  assertExists(patch.character_name);
  assertEquals(patch.character_name, "A".repeat(79));
});
