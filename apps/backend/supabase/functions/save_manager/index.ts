import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Schema field descriptors keyed by schema_version.
// Add a new entry whenever a migration introduces breaking field changes.
export const SCHEMA_DESCRIPTORS: Record<number, Record<string, string>> = {
  1: {
    hp: "number -current player hit points",
    hp_max: "number -maximum hit points",
    mp: "number -current mana points",
    mp_max: "number -maximum mana points",
    stamina: "number -current stamina",
    stamina_max: "number -maximum stamina",
    gold: "number -gold held",
    xp: "number -total experience points",
    level: "number -current character level",
    character_name: "string -player character name",
    character_class: "string -character class (e.g. Rogue, Mage)",
    campaign_id: "string -active campaign identifier",
    current_location: "string -current scene/location id",
    inventory: "array -items held (id, name, item_type, effects)",
    quest_state: "object -map of quest_id to { status }",
    relationships: "object -map of npc_id to { name, score, tier }",
    factions: "object -map of faction_id to numeric standing",
    known_lore: "array -codex entries discovered (id, title, category, body)",
    skills: "object -map of skill_name to numeric modifier",
    schema_version: "number -save format version; used for migration",
  },
};

interface SaveRequest {
  action: "SAVE" | "LOAD" | "LIST" | "DELETE" | "EXPORT";
  user_id: string;
  character_id?: string;
  save_name?: string;
  save_id?: string;
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
    const body: SaveRequest = await req.json();
    const { action, user_id, character_id } = body;

    if (!user_id || !action) {
      return jsonResponse({ error: "Missing required fields" }, 400);
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SVC_ROLE_KEY")!,
    );

    // ── SAVE ─────────────────────────────────────────────────────
    if (action === "SAVE") {
      const save_name = body.save_name ?? `Save ${new Date().toLocaleString()}`;

      // Load current canonical state
      const stateQuery = supabase
        .from("canonical_state")
        .select("*")
        .eq("user_id", user_id);
      if (character_id) stateQuery.eq("character_id", character_id);
      const { data: state, error: stateError } = await stateQuery.single();

      if (stateError || !state) {
        return jsonResponse({ error: "Canonical state not found" }, 404);
      }

      // Load current campaign state
      const { data: campaignState } = await supabase
        .from("player_campaign_state")
        .select("*")
        .eq("user_id", user_id)
        .eq("campaign_id", state.campaign_id)
        .maybeSingle();

      // Get latest revision id
      const { data: latestRevision } = await supabase
        .from("revisions")
        .select("id")
        .eq("user_id", user_id)
        .order("created_at", { ascending: false })
        .limit(1)
        .maybeSingle();

      const { data: save, error: saveError } = await supabase
        .from("manual_saves")
        .insert({
          user_id,
          character_id: character_id ?? null,
          revision_id: latestRevision?.id ?? "none",
          save_name,
          campaign_id: state.campaign_id,
          schema_version: state.schema_version ?? 1,
          state_snapshot: {
            canonical_state: state,
            campaign_state: campaignState ?? {},
          },
        })
        .select()
        .single();

      if (saveError) throw saveError;

      return jsonResponse({
        status: "SAVED",
        save_id: save.id,
        save_name: save.save_name,
        created_at: save.created_at,
      });
    }

    // ── LIST ─────────────────────────────────────────────────────
    if (action === "LIST") {
      const listQuery = supabase
        .from("manual_saves")
        .select("id, save_name, campaign_id, created_at, revision_id")
        .eq("user_id", user_id)
        .order("created_at", { ascending: false })
        .limit(20);
      if (character_id) listQuery.eq("character_id", character_id);
      const { data: saves, error } = await listQuery;

      if (error) throw error;

      return jsonResponse({ status: "OK", saves: saves ?? [] });
    }

    // ── LOAD ─────────────────────────────────────────────────────
    if (action === "LOAD") {
      if (!body.save_id) {
        return jsonResponse({ error: "save_id required for LOAD" }, 400);
      }

      const { data: save, error: saveError } = await supabase
        .from("manual_saves")
        .select("*")
        .eq("id", body.save_id)
        .eq("user_id", user_id)
        .single();

      if (saveError || !save) {
        return jsonResponse({ error: "Save not found" }, 404);
      }

      const snapshot = save.state_snapshot as Record<string, unknown>;
      const canonicalState = snapshot.canonical_state as Record<string, unknown>;
      const campaignState = snapshot.campaign_state as Record<string, unknown>;

      // Restore canonical state
      const restoreCharacterId = (canonicalState.character_id as string | undefined) ?? character_id;
      const restoreQuery = supabase
        .from("canonical_state")
        .update({
          hp: canonicalState.hp,
          hp_max: canonicalState.hp_max,
          mp: canonicalState.mp,
          mp_max: canonicalState.mp_max,
          stamina: canonicalState.stamina,
          stamina_max: canonicalState.stamina_max,
          gold: canonicalState.gold,
          xp: canonicalState.xp,
          level: canonicalState.level,
          current_location: canonicalState.current_location,
          inventory: canonicalState.inventory,
          quest_state: canonicalState.quest_state,
          relationships: canonicalState.relationships,
          factions: canonicalState.factions,
          known_lore: canonicalState.known_lore,
          skills: canonicalState.skills,
          updated_at: new Date().toISOString(),
        })
        .eq("user_id", user_id);
      if (restoreCharacterId) restoreQuery.eq("character_id", restoreCharacterId);
      const { error: restoreError } = await restoreQuery;

      if (restoreError) throw restoreError;

      // Restore campaign state
      if (campaignState && campaignState.campaign_id) {
        await supabase
          .from("player_campaign_state")
          .update({
            current_scene: campaignState.current_scene,
            npc_states: campaignState.npc_states,
            beaten_beats: campaignState.beaten_beats,
            scene_item_states: campaignState.scene_item_states,
          })
          .eq("user_id", user_id)
          .eq("campaign_id", campaignState.campaign_id);
      }

      return jsonResponse({
        status: "LOADED",
        save_name: save.save_name,
        restored_location: canonicalState.current_location,
      });
    }

    // ── DELETE ───────────────────────────────────────────────────
    if (action === "DELETE") {
      if (!body.save_id) {
        return jsonResponse({ error: "save_id required for DELETE" }, 400);
      }

      const deleteQuery = supabase
        .from("manual_saves")
        .delete()
        .eq("id", body.save_id)
        .eq("user_id", user_id);
      if (character_id) deleteQuery.eq("character_id", character_id);
      const { error } = await deleteQuery;

      if (error) throw error;

      return jsonResponse({ status: "DELETED" });
    }

    // ── EXPORT ───────────────────────────────────────────────────
    // §16.10 / Appendix C -human-readable debug bundle for support
    // and migration failure triage. Never overwrites the original save.
    if (action === "EXPORT") {
      if (!body.save_id) {
        return jsonResponse({ error: "save_id required for EXPORT" }, 400);
      }

      const { data: save, error: saveError } = await supabase
        .from("manual_saves")
        .select("*")
        .eq("id", body.save_id)
        .eq("user_id", user_id)
        .single();

      if (saveError || !save) {
        return jsonResponse({ error: "Save not found" }, 404);
      }

      const schemaVersion = (save.schema_version as number) ?? 1;
      const descriptor = SCHEMA_DESCRIPTORS[schemaVersion] ?? SCHEMA_DESCRIPTORS[1];

      const snapshot = save.state_snapshot as Record<string, unknown>;

      // Load the linked revision for full reproduction context
      const { data: revision } = await supabase
        .from("revisions")
        .select("id, previous_id, player_action, route_category, success_tier, events, created_at")
        .eq("id", save.revision_id)
        .eq("user_id", user_id)
        .maybeSingle();

      return jsonResponse({
        export_format: "nexus_tales_save_debug_v1",
        exported_at: new Date().toISOString(),
        save_metadata: {
          save_id: save.id,
          save_name: save.save_name,
          created_at: save.created_at,
          revision_id: save.revision_id,
          campaign_id: save.campaign_id,
          schema_version: schemaVersion,
        },
        schema_descriptor: {
          version: schemaVersion,
          fields: descriptor,
        },
        revision_context: revision ?? null,
        canonical_state: snapshot.canonical_state ?? null,
        campaign_state: snapshot.campaign_state ?? null,
        migration_notes: "No migration errors recorded.",
      });
    }

    return jsonResponse({ error: "Unknown action" }, 400);

  } catch (err) {
    console.error("save_manager error:", err);
    return jsonResponse({ error: String(err) }, 500);
  }
});