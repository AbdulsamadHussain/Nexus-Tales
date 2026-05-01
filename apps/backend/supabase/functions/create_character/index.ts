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

    // Use service client to verify user from JWT
    const serviceClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SVC_ROLE_KEY")!,
    );

    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error: userError } = await serviceClient.auth.getUser(token);

    if (userError || !user) {
      return new Response(JSON.stringify({ error: "Invalid token" }), {
        status: 401,
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    const body = await req.json();

    // Check if canonical state already exists
    const { data: existing } = await serviceClient
      .from("canonical_state")
      .select("id")
      .eq("user_id", user.id)
      .maybeSingle();

    if (existing) {
      return new Response(JSON.stringify({ status: "EXISTS" }), {
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    // Create canonical state
    const { error: insertError } = await serviceClient
          .from("canonical_state")
          .insert({
            user_id: user.id,
            character_name: body.character_name,
            character_class: body.character_class,
            origin: body.origin,
            hp: body.hp_max,
            hp_max: body.hp_max,
            mp: body.mp_max,
            mp_max: body.mp_max,
            stamina: body.stamina_max,
            stamina_max: body.stamina_max,
            current_location: "vault_of_the_plague_warden",
            campaign_id: "campaign_01",
            skills: body.skills ?? {},
            inventory: body.starting_items ?? [],
            content_settings: {
              violence: true,
              horror: true,
              romance: false,
              mature: false,
            },
          });

    if (insertError) throw insertError;

    return new Response(JSON.stringify({ status: "CREATED" }), {
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