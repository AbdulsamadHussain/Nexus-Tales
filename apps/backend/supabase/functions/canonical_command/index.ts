import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ── Server-authoritative item catalogue ───────────────────────────────────
// Prices and attributes are defined here — never trusted from the client.
// The Edge Function looks up the item and passes the authoritative cost + record
// to the DB RPC, which re-validates the gold balance against the locked row.
export const ITEM_CATALOGUE: Record<string, {
  id: string; name: string; desc: string; cost: number;
  item_type: string; rarity: string;
}> = {
  item_healing_salve:   { id: "item_healing_salve",   name: "Healing Salve",   desc: "Restores 12 HP when used.",                    cost: 15, item_type: "consumable", rarity: "common"    },
  item_mana_tonic:      { id: "item_mana_tonic",      name: "Mana Tonic",      desc: "Restores 10 MP when used.",                    cost: 18, item_type: "consumable", rarity: "common"    },
  item_stamina_draught: { id: "item_stamina_draught",  name: "Stamina Draught", desc: "Restores 8 stamina when used.",               cost: 12, item_type: "consumable", rarity: "common"    },
  item_iron_ration:     { id: "item_iron_ration",     name: "Iron Ration",     desc: "Trail food. Restores 5 HP.",                   cost: 5,  item_type: "consumable", rarity: "common"    },
  item_smoke_bomb:      { id: "item_smoke_bomb",      name: "Smoke Bomb",      desc: "Escape any combat without a counter-attack.",  cost: 25, item_type: "consumable", rarity: "rare"      },
  item_revive_charm:    { id: "item_revive_charm",    name: "Revive Charm",    desc: "Automatically revive at 10 HP when you fall.", cost: 60, item_type: "consumable", rarity: "legendary" },
};

// ── Server-authoritative skill catalogue ──────────────────────────────────
// Class membership is validated here; slot availability is validated inside the
// atomic RPC against the locked canonical_state row (race-safe).
export const CLASS_SKILLS: Record<string, Record<string, { name: string; desc: string }>> = {
  Rogue: {
    shadow_step:  { name: "Shadow Step",  desc: "+2 to stealth and evasion rolls." },
    pick_lock:    { name: "Pick Lock",    desc: "+3 to skill checks involving locks, traps, and secrets." },
    vanish:       { name: "Vanish",       desc: "Escape combat without a counter-attack once per scene." },
    blade_dance:  { name: "Blade Dance",  desc: "Attack twice in one turn. Second hit at half damage." },
    poison_craft: { name: "Poison Craft", desc: "Attacks can inflict Poison status (3 HP per turn)." },
  },
  "War Mage": {
    arcane_burst:    { name: "Arcane Burst",    desc: "+3 to attack rolls, costs 8 MP." },
    mana_shield:     { name: "Mana Shield",     desc: "Absorb the next hit with MP instead of HP." },
    time_echo:       { name: "Time Echo",       desc: "Reroll one failed check per scene." },
    chain_lightning: { name: "Chain Lightning", desc: "Hit up to 3 enemies in one turn. 10 MP cost." },
    spell_haste:     { name: "Spell Haste",     desc: "Reduce MP cost of all spells by 2." },
  },
  Warden: {
    iron_guard:  { name: "Iron Guard",  desc: "+10 max HP permanently." },
    shield_bash: { name: "Shield Bash", desc: "Stagger enemy, skipping their counter-attack." },
    rally:       { name: "Rally",       desc: "Restore 15 stamina as a free action once per scene." },
    bulwark:     { name: "Bulwark",     desc: "Reduce all incoming damage by 2." },
    taunt:       { name: "Taunt",       desc: "Force all hostile NPCs to target you for 2 turns." },
  },
  "Plague Doctor": {
    toxin_expertise: { name: "Toxin Expertise", desc: "All potions and salves heal 5 extra HP." },
    mercy_stroke:    { name: "Mercy Stroke",    desc: "+2 to attacks against injured (< 50% HP) enemies." },
    field_medicine:  { name: "Field Medicine",  desc: "Stabilise allies at 0 HP; they survive at 1 HP." },
    plague_cloud:    { name: "Plague Cloud",    desc: "Infect all enemies in scene with Poison status." },
    antidote:        { name: "Antidote",        desc: "Cure any status effect on yourself as a free action." },
  },
  "Hex Blade": {
    curse:          { name: "Curse",          desc: "Enemy takes -2 to all rolls for 3 turns. 6 MP cost." },
    dark_pact:      { name: "Dark Pact",      desc: "Trade 10 HP for 15 MP once per scene." },
    soul_leech:     { name: "Soul Leech",     desc: "Restore 5 HP on every NPC kill." },
    hex_bolt:       { name: "Hex Bolt",       desc: "Ranged hex attack; no counter-attack possible." },
    eldritch_armor: { name: "Eldritch Armor", desc: "Gain 3 temporary HP per turn in combat." },
  },
};

// ── Exported pure helpers (used by unit tests) ────────────────────────────

/** Build and validate profile update patch. Returns an empty object when nothing changed. */
export function buildProfilePatch(body: {
  character_name?: string;
  origin?: string;
  backstory?: string;
}): Record<string, string> {
  const updates: Record<string, string> = {};
  const name = ((body.character_name ?? "") as string).trim();
  const origin = ((body.origin ?? "") as string).trim();
  const backstory = ((body.backstory ?? "") as string).trim();

  if (name) updates.character_name = name.slice(0, 80);
  // origin and backstory: include even when empty (intentional clearing).
  if (body.origin !== undefined) updates.origin = origin.slice(0, 200);
  if (body.backstory !== undefined) updates.backstory = backstory.slice(0, 2000);
  return updates;
}

interface CommandRequest {
  character_id: string;
  command: "BUY_ITEM" | "CHOOSE_SKILL" | "EDIT_PROFILE";
  item_id?: string;
  skill_id?: string;
  character_name?: string;
  origin?: string;
  backstory?: string;
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
  });
}

if (import.meta.main) serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
      },
    });
  }

  try {
    // ── Identity: derive user_id from the verified JWT ────────────────────
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return jsonResponse({ error: "No auth header" }, 401);

    const userClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: { user }, error: userError } = await userClient.auth.getUser();
    if (userError || !user) return jsonResponse({ error: "Invalid token" }, 401);
    const user_id = user.id;

    const body: CommandRequest = await req.json();
    const { character_id, command } = body;

    if (!character_id || !command) {
      return jsonResponse({ error: "character_id and command are required" }, 400);
    }
    if (!["BUY_ITEM", "CHOOSE_SKILL", "EDIT_PROFILE"].includes(command)) {
      return jsonResponse({ error: "Unknown command" }, 400);
    }

    // Service-role client: used for the atomic RPC and, in CHOOSE_SKILL, a
    // minimal pre-read to get character_class for server-side catalogue validation.
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SVC_ROLE_KEY")!,
    );

    // ── Resolve command-specific params ───────────────────────────────────
    // Catalogue validation happens here (Edge Function, server-side).
    // Slot / balance checks happen inside the atomic RPC (DB, locked row).

    if (command === "BUY_ITEM") {
      const { item_id } = body;
      if (!item_id) return jsonResponse({ error: "item_id required for BUY_ITEM" }, 400);

      const catalogItem = ITEM_CATALOGUE[item_id];
      if (!catalogItem) return jsonResponse({ error: "Unknown item" }, 400);

      // ── Atomic RPC call ───────────────────────────────────────────────
      // execute_canonical_command:
      //   1. SELECT canonical_state WHERE character_id + user_id FOR UPDATE
      //   2. Validates gold >= p_item_cost against the locked row (race-safe)
      //   3. UPDATE canonical_state
      //   4. INSERT revisions  (rolls back step 3 on failure)
      //   5. INSERT canonical_events (rolls back steps 3-4 on failure)
      const { data: result, error: rpcErr } = await supabase.rpc(
        "execute_canonical_command",
        {
          p_user_id:     user_id,
          p_character_id: character_id,
          p_command:     "BUY_ITEM",
          p_item_id:     item_id,
          p_item_cost:   catalogItem.cost,
          p_item_record: { ...catalogItem, quantity: 1 },
        },
      );

      if (rpcErr) throw rpcErr;
      const r = result as Record<string, unknown>;
      if (r.error) return jsonResponse({ error: r.error }, (r.status as number) ?? 500);
      return jsonResponse({
        status: "OK",
        revision_id: r.revision_id,
        events: r.events,
        state_delta: { gold: -catalogItem.cost },
      });
    }

    if (command === "CHOOSE_SKILL") {
      const { skill_id } = body;
      if (!skill_id) return jsonResponse({ error: "skill_id required for CHOOSE_SKILL" }, 400);

      // Read character_class for class-catalogue validation.
      // character_class never changes after creation, so a pre-lock read is safe here.
      const { data: charInfo, error: charErr } = await supabase
        .from("canonical_state")
        .select("character_class")
        .eq("user_id", user_id)
        .eq("character_id", character_id)
        .maybeSingle();

      if (charErr || !charInfo) return jsonResponse({ error: "Character not found" }, 404);

      const charClass = (charInfo.character_class as string) ?? "Rogue";
      const classSkills = CLASS_SKILLS[charClass] ?? CLASS_SKILLS["Rogue"];
      const skillDef = classSkills[skill_id];
      if (!skillDef) return jsonResponse({ error: "Skill not available for this class" }, 422);

      // ── Atomic RPC call ───────────────────────────────────────────────
      // Slot availability is validated inside the RPC against the locked row.
      const { data: result, error: rpcErr } = await supabase.rpc(
        "execute_canonical_command",
        {
          p_user_id:      user_id,
          p_character_id: character_id,
          p_command:      "CHOOSE_SKILL",
          p_skill_id:     skill_id,
          p_skill_name:   skillDef.name,
          p_skill_desc:   skillDef.desc,
        },
      );

      if (rpcErr) throw rpcErr;
      const r = result as Record<string, unknown>;
      if (r.error) return jsonResponse({ error: r.error }, (r.status as number) ?? 500);
      return jsonResponse({
        status: "OK",
        revision_id: r.revision_id,
        events: r.events,
        state_delta: {},
      });
    }

    if (command === "EDIT_PROFILE") {
      const profilePatch = buildProfilePatch(body);
      if (Object.keys(profilePatch).length === 0) {
        return jsonResponse({ error: "No fields to update" }, 400);
      }

      // ── Atomic RPC call ───────────────────────────────────────────────
      const { data: result, error: rpcErr } = await supabase.rpc(
        "execute_canonical_command",
        {
          p_user_id:         user_id,
          p_character_id:    character_id,
          p_command:         "EDIT_PROFILE",
          p_profile_updates: profilePatch,
        },
      );

      if (rpcErr) throw rpcErr;
      const r = result as Record<string, unknown>;
      if (r.error) return jsonResponse({ error: r.error }, (r.status as number) ?? 500);
      return jsonResponse({
        status: "OK",
        revision_id: r.revision_id,
        events: r.events,
        state_delta: {},
      });
    }

    return jsonResponse({ error: "Unknown command" }, 400);

  } catch (err) {
    console.error("canonical_command error:", err);
    return jsonResponse({ error: String(err) }, 500);
  }
});
