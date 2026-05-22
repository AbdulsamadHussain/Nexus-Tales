import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "No auth header" }), {
        status: 401,
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    // User-scoped client to verify the JWT (works for all account types)
    const userClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: { user }, error: userError } = await userClient.auth.getUser();

    if (userError || !user) {
      return new Response(JSON.stringify({ error: "Invalid token" }), {
        status: 401,
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    // Service-role client for all DB writes (bypasses RLS where needed)
    const serviceClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SVC_ROLE_KEY")!,
    );

    const body = await req.json();

    // ── Resolve campaign ──────────────────────────────────────────
    // If the caller passes a `custom_campaign` object, create a new campaign row.
    // Otherwise fall back to the curated campaign_01.
    let campaignId = "campaign_01";
    let startLocation = "vault_of_the_plague_warden";

    if (body.custom_campaign) {
      const cc = body.custom_campaign as {
        title: string;
        world_description: string;
        narrator_tone: string;
        starting_scene_title: string;
        starting_scene_description: string;
        starting_scene_atmosphere: string;
        is_public?: boolean;
      };

      // Generate a unique campaign id for this user
      const slug = cc.title
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, "_")
        .replace(/^_|_$/g, "")
        .slice(0, 40);
      const uniqueSuffix = Date.now().toString(36).slice(-4);
      campaignId = `custom_${user.id.slice(0, 8)}_${slug}_${uniqueSuffix}`;
      startLocation = `scene_${campaignId}_start`;

      // Insert campaign
      const { error: campaignErr } = await serviceClient
        .from("campaigns")
        .insert({
          id: campaignId,
          user_id: user.id,
          title: cc.title,
          description: cc.world_description,
          world_description: cc.world_description,
          narrator_tone: cc.narrator_tone,
          is_custom: true,
          is_public: cc.is_public ?? false,
        });
      if (campaignErr) throw campaignErr;

      // Insert starting scene
      const { error: sceneErr } = await serviceClient
        .from("scenes")
        .insert({
          id: startLocation,
          campaign_id: campaignId,
          title: cc.starting_scene_title,
          description: cc.starting_scene_description,
          atmosphere: cc.starting_scene_atmosphere,
          exits: {},
          is_start_scene: true,
        });
      if (sceneErr) throw sceneErr;
    }

    // ── Create canonical state ────────────────────────────────────
    const newCharacterId = crypto.randomUUID();

    const { data: insertedRow, error: insertError } = await serviceClient
      .from("canonical_state")
      .insert({
        character_id: newCharacterId,
        user_id: user.id,
        character_name: body.character_name,
        character_class: body.character_class,
        portrait: body.portrait ?? 'default',
        origin: body.origin ?? '',
        backstory: body.backstory ?? '',
        hp: body.hp_max,
        hp_max: body.hp_max,
        mp: body.mp_max,
        mp_max: body.mp_max,
        stamina: body.stamina_max,
        stamina_max: body.stamina_max,
        current_location: startLocation,
        campaign_id: campaignId,
        skills: body.skills ?? {},
        inventory: body.starting_items ?? [],
        content_settings: {
          violence: true,
          horror: true,
          romance: false,
          mature: false,
          graphic: false,
        },
      })
      .select("character_id")
      .single();

    if (insertError) throw insertError;

    return new Response(JSON.stringify({ status: "CREATED", campaign_id: campaignId, character_id: insertedRow.character_id }), {
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  } catch (err) {
    console.error("create_character error:", err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  }
});
