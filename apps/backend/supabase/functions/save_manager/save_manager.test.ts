import { assertEquals, assertExists } from "https://deno.land/std@0.168.0/testing/asserts.ts";
import { SCHEMA_DESCRIPTORS } from "./index.ts";

// ── Schema descriptor completeness (§12.1 / Appendix C) ──────────

const REQUIRED_CANONICAL_FIELDS = [
  "hp", "hp_max", "mp", "mp_max", "stamina", "stamina_max",
  "gold", "xp", "level", "character_name", "character_class",
  "campaign_id", "current_location", "inventory", "quest_state",
  "relationships", "factions", "known_lore", "skills", "schema_version",
];

Deno.test("schema descriptor v1 exists", () => {
  assertExists(SCHEMA_DESCRIPTORS[1]);
});

Deno.test("schema descriptor v1 contains all required canonical_state fields", () => {
  const descriptor = SCHEMA_DESCRIPTORS[1];
  for (const field of REQUIRED_CANONICAL_FIELDS) {
    assertEquals(
      field in descriptor,
      true,
      `Missing field in schema descriptor: ${field}`,
    );
  }
});

Deno.test("schema descriptor v1 field values are non-empty strings", () => {
  const descriptor = SCHEMA_DESCRIPTORS[1];
  for (const [key, value] of Object.entries(descriptor)) {
    assertEquals(
      typeof value === "string" && value.length > 0,
      true,
      `Descriptor field '${key}' must be a non-empty string`,
    );
  }
});

// ── Export bundle structure (§16.10 / Appendix C) ─────────────────
// Cross-user isolation and rollback correctness require a live Supabase instance.
// Those cases are covered in supabase/tests/integration.test.ts.
// Here we document the required top-level fields as a contract.

const REQUIRED_EXPORT_FIELDS = [
  "export_format",
  "exported_at",
  "save_metadata",
  "schema_descriptor",
  "revision_context",
  "canonical_state",
  "campaign_state",
  "migration_notes",
];

Deno.test("export bundle field contract is documented", () => {
  // If this list changes, the EXPORT handler must be updated to match.
  assertEquals(REQUIRED_EXPORT_FIELDS.length, 8);
  assertEquals(REQUIRED_EXPORT_FIELDS.includes("schema_descriptor"), true);
  assertEquals(REQUIRED_EXPORT_FIELDS.includes("revision_context"), true);
  assertEquals(REQUIRED_EXPORT_FIELDS.includes("migration_notes"), true);
});

Deno.test("save_metadata required sub-fields are documented", () => {
  const required = ["save_id", "save_name", "created_at", "revision_id", "campaign_id", "schema_version"];
  assertEquals(required.length, 6);
  assertEquals(required.includes("schema_version"), true);
});
