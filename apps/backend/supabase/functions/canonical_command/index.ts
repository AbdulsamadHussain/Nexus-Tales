import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ── Server-authoritative item catalogue ───────────────────────────
// Prices and attributes are defined here — never trusted from the client.
export const ITEM_CATALOGUE: Record<string, {
  id: string; name: string; desc: string; cost: number;
  item_type: string; rarity: string;
}> = {
  item_healing_salve:   { id: "item_healing_salve",   name: "Healing Salve",   desc: "Restores 12 HP when used.",                    cost: 15, item_type: "consumable", rarity: "common" },
  item_mana_tonic:      { id: "item_mana_tonic",      name: "Mana Tonic",      desc: "Restores 10 MP when used.",                    cost: 18, item_type: "consumable", rarity: "common" },
  item_stamina_draught: { id: "item_stamina_draught",  name: "Stamina Draught", desc: "Restores 8 stamina when used.",               cost: 12, item_type: "consumable", rarity: "common" },
  item_iron_ration:     { id: "item_iron_ration",     name: "Iron Ration",     desc: "Trail food. Restores 5 HP.",                   cost: 5,  item_type: "consumable", rarity: "common" },
  item_smoke_bomb:      { id: "item_smoke_bomb",      name: "Smoke Bomb",      desc: "Escape any combat without a counter-attack.",  cost: 25, item_type: "consumable", rarity: "rare" },
  item_revive_charm:    { id: "item_revive_charm",    name: "Revive Charm",    desc: "Automatically revive at 10 HP when you fall.", cost: 60, item_type: "consumable", rarity: "legendary" },
};

// ── Server-authoritative skill catalogue ─────────────────────────
// Skill availability is validated server-side — the client only sends a skill_id.
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

interface CommandRequest {
  // user_id intentionally omitted — always derived from the verified JWT
  character_id: string;
  command: "BUY_ITEM" | "CHOOSE_SKILL" | "EDIT_PROFILE";
  // BUY_ITEM
  item_id?: string;
  // CHOOSE_SKILL
  skill_id?: string;
  // EDIT_PROFILE
  character_name?: string;
  origin?: string;
  backstory?: string;
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
  });
}

function generateRevisionId(): string {
  const num = Math.floor(Math.random() * 900000) + 100000;
  return `cmd_${num}`;
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
    // ── Identity: derive user_id from the verified JWT ────────────
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

    const validCommands = ["BUY_ITEM", "CHOOSE_SKILL", "EDIT_PROFILE"];
    if (!validCommands.includes(command)) {
      return jsonResponse({ error: "Unknown command" }, 400);
    }

    // Service-role client for all DB operations after JWT validation
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SVC_ROLE_KEY")!,
    );

    // ── Ownership gate: verify character belongs to this user ─────
    const { data: state, error: stateError } = await supabase
      .from("canonical_state")
      .select("*")
      .eq("user_id", user_id)
      .eq("character_id", character_id)
      .single();

    if (stateError || !state) {
      return jsonResponse({ error: "Character not found" }, 404);
    }

    // ── Get latest revision for chain linkage ─────────────────────
    const { data: latestRev } = await supabase
      .from("revisions")
      .select("id")
      .eq("user_id", user_id)
      .eq("character_id", character_id)
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    const revision_id = generateRevisionId();
    const events: string[] = [];
    const stateDelta: Record<string, unknown> = {};

    // ── BUY_ITEM ──────────────────────────────────────────────────
    if (command === "BUY_ITEM") {
      const { item_id } = body;
      if (!item_id) return jsonResponse({ error: "item_id required for BUY_ITEM" }, 400);

      const catalogItem = ITEM_CATALOGUE[item_id];
      if (!catalogItem) return jsonResponse({ error: "Unknown item" }, 400);

      const currentGold = (state.gold as number) ?? 0;
      if (currentGold < catalogItem.cost) {
        return jsonResponse({ error: "Insufficient gold" }, 422);
      }

      const newGold = currentGold - catalogItem.cost;
      const inventory = [
        ...(Array.isArray(state.inventory)
          ? (state.inventory as Record<string, unknown>[])
          : []),
        { ...catalogItem, quantity: 1 },
      ];

      const { error: updateErr } = await supabase
        .from("canonical_state")
        .update({ gold: newGold, inventory })
        .eq("user_id", user_id)
        .eq("character_id", character_id);

      if (updateErr) throw updateErr;

      stateDelta.gold = -catalogItem.cost;
      events.push(`ITEM_PURCHASED:${item_id}`);
    }

    // ── CHOOSE_SKILL ──────────────────────────────────────────────
    else if (command === "CHOOSE_SKILL") {
      const { skill_id } = body;
      if (!skill_id) return jsonResponse({ error: "skill_id required for CHOOSE_SKILL" }, 400);

      const charClass = (state.character_class as string) ?? "Rogue";
      const classSkills = CLASS_SKILLS[charClass] ?? CLASS_SKILLS["Rogue"];
      const skillDef = classSkills[skill_id];
      if (!skillDef) {
        return jsonResponse({ error: "Skill not available for this class" }, 422);
      }

      const existingSkills = (state.skills as Record<string, unknown>) ?? {};
      if (existingSkills[skill_id]) {
        return jsonResponse({ error: "Skill already learned" }, 422);
      }

      // Level-up choice is available when skill count < (level - 1).
      // e.g. level 2 → 1 available slot, must have 0 skills; level 3 → 2 slots, etc.
      const skillCount = Object.keys(existingSkills).length;
      const currentLevel = (state.level as number) ?? 1;
      if (skillCount >= currentLevel - 1) {
        return jsonResponse({ error: "No level-up skill choice available" }, 422);
      }

      const updatedSkills = {
        ...existingSkills,
        [skill_id]: {
          name: skillDef.name,
          desc: skillDef.desc,
          unlocked_at_level: currentLevel,
        },
      };

      const { error: updateErr } = await supabase
        .from("canonical_state")
        .update({ skills: updatedSkills })
        .eq("user_id", user_id)
        .eq("character_id", character_id);

      if (updateErr) throw updateErr;

      events.push(`SKILL_LEARNED:${skill_id}`);
    }

    // ── EDIT_PROFILE ──────────────────────────────────────────────
    else if (command === "EDIT_PROFILE") {
      const updates: Record<string, string> = {};

      const name = ((body.character_name ?? "") as string).trim();
      const origin = ((body.origin ?? "") as string).trim();
      const backstory = ((body.backstory ?? "") as string).trim();

      // Only apply non-empty values; slice to sane maximums
      if (name) updates.character_name = name.slice(0, 80);
      // origin and backstory may be intentionally cleared → always include if provided
      if (body.origin !== undefined) updates.origin = origin.slice(0, 200);
      if (body.backstory !== undefined) updates.backstory = backstory.slice(0, 2000);

      if (Object.keys(updates).length === 0) {
        return jsonResponse({ error: "No fields to update" }, 400);
      }

      const { error: updateErr } = await supabase
        .from("canonical_state")
        .update(updates)
        .eq("user_id", user_id)
        .eq("character_id", character_id);

      if (updateErr) throw updateErr;

      events.push("PROFILE_EDITED");
    }

    // ── Commit revision row (UI commands create their own trail) ──
    const { error: revErr } = await supabase
      .from("revisions")
      .insert({
        id: revision_id,
        user_id,
        character_id,
        previous_id: latestRev?.id ?? null,
        schema_version: 1,
        player_action: `[${command}]`,
        route_category: "UI_ACTION",
        gateway_decision: "ALLOW",
        success_tier: "NO_ROLL",
        state_snapshot: state,
        events,
        autosave_candidate: false,
        narration_done: true,
        summary_job_queued: false,
      });

    if (revErr) throw revErr;

    // ── Commit canonical_events ───────────────────────────────────
    if (events.length > 0) {
      await supabase.from("canonical_events").insert(
        events.map((event_type) => ({
          user_id,
          revision_id,
          event_type,
          payload: { command, delta: stateDelta },
        })),
      );
    }

    return jsonResponse({ status: "OK", revision_id, events, state_delta: stateDelta });
  } catch (err) {
    console.error("canonical_command error:", err);
    return jsonResponse({ error: String(err) }, 500);
  }
});
