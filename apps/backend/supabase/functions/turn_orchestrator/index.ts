import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

type RouteCategory =
  | "NO_ROLL_DETERMINISTIC"
  | "ROLL_REQUIRED"
  | "CLARIFICATION_REQUIRED"
  | "SAFE_REJECT"
  | "UI_ACTION"
  | "SYSTEM_TRANSFORMED_ACTION";

type GatewayDecision =
  | "ALLOW"
  | "ALLOW_WITH_CONSTRAINTS"
  | "TRANSFORM"
  | "REJECT";

interface TurnRequest {
  user_id: string;
  player_action: string;
  previous_revision_id: string | null;
  resolved_route?: string;
  content_settings: {
    violence: boolean;
    horror: boolean;
    romance: boolean;
    mature: boolean;
  };
}

interface GatewayResult {
  decision: GatewayDecision;
  sanitized_input: string;
  policy_flags: string[];
  narration_constraints: string[];
  player_message?: string;
}

function runSafetyGateway(
  input: string,
  contentSettings: TurnRequest["content_settings"]
): GatewayResult {
  const lower = input.toLowerCase();

  if (/ignore (all |previous |your )?instructions|system prompt|jailbreak|override rules|forget everything|you are now|pretend you/.test(lower)) {
    return { decision: "REJECT", sanitized_input: input, policy_flags: ["PROMPT_INJECTION"], narration_constraints: [], player_message: "That action is not allowed." };
  }

  if (!contentSettings.romance && /seduce|kiss|romance|flirt/.test(lower)) {
    return { decision: "REJECT", sanitized_input: input, policy_flags: ["ROMANCE_DISABLED"], narration_constraints: [], player_message: "Romance content is disabled in your settings." };
  }

  if (/torture|mutilate|dismember/.test(lower)) {
    return {
      decision: "TRANSFORM",
      sanitized_input: input.replace(/torture/gi, "interrogate").replace(/mutilate/gi, "attack").replace(/dismember/gi, "strike"),
      policy_flags: ["COERCION_SOFTENED"],
      narration_constraints: ["NO_GRAPHIC_ABUSE"],
    };
  }

  if (contentSettings.violence && /gore|brutal|visceral|graphic/.test(lower)) {
    return { decision: "ALLOW_WITH_CONSTRAINTS", sanitized_input: input, policy_flags: ["VIOLENCE_LIMITED"], narration_constraints: ["NO_GORE"] };
  }

  return { decision: "ALLOW", sanitized_input: input, policy_flags: [], narration_constraints: [] };
}

function runDeterministicRouter(input: string): RouteCategory {
  const lower = input.trim().toLowerCase();

  if (/\b(inventory|codex|map|quest log|settings|save|load)\b/.test(lower)) return "UI_ACTION";
  if (lower.length < 4) return "CLARIFICATION_REQUIRED";
  if (/^(hi|hello|hey|sup|yo|hi there|good morning|good evening)[\s!?.]*$/.test(lower)) return "CLARIFICATION_REQUIRED";
  if (/what (model|ai|llm|version)|who are you|are you (an ai|a bot|gpt|claude|gemma)/.test(lower)) return "CLARIFICATION_REQUIRED";

  if (/\b(read|look at|examine|check|open unlocked|buy|purchase|talk to|speak to|ask about)\b/.test(lower) &&
    !/attack|fight|sneak|steal|pick lock|persuade|intimidate|cast|jump|climb/.test(lower)) return "NO_ROLL_DETERMINISTIC";

  if (/\b(go to|walk to|move to|head to|enter|leave|go north|go south|go east|go west)\b/.test(lower)) return "NO_ROLL_DETERMINISTIC";
  if (/\b(attack|strike|stab|shoot|cast|throw|charge|backstab|ambush|slash|punch|kick)\b/.test(lower)) return "ROLL_REQUIRED";
  if (/\b(sneak|hide|shadow|disappear|cloak|blend in)\b/.test(lower)) return "ROLL_REQUIRED";
  if (/\b(pick lock|lockpick|persuade|intimidate|deceive|bluff|steal|pickpocket|climb|jump|escape|search|investigate|disarm|hack)\b/.test(lower)) return "ROLL_REQUIRED";
  if (/\b(retreat|flee|run away|back away|exit)\b/.test(lower)) return "NO_ROLL_DETERMINISTIC";
  if (/\b(i |my |we )(try|attempt|grab|take|use|open|push|pull|lift|break|destroy|throw|place|drop|equip|unequip)\b/.test(lower)) return "ROLL_REQUIRED";

  return "CLARIFICATION_REQUIRED";
}

async function callFunction(name: string, payload: unknown): Promise<Response> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SVC_ROLE_KEY");
  if (!supabaseUrl) throw new Error("Missing SUPABASE_URL");
  if (!serviceKey) throw new Error("Missing SVC_ROLE_KEY");
  return await fetch(`${supabaseUrl}/functions/v1/${name}`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${serviceKey}` },
    body: JSON.stringify(payload),
  });
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
  });
}

serve(async (req: Request) => {
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
    const body: TurnRequest = await req.json();
    const { user_id, player_action, previous_revision_id, content_settings } = body;

    if (!user_id || !player_action || !content_settings) {
      return jsonResponse({ error: "Missing required fields." }, 400);
    }

    // ── STEP 1: Safety gateway ────────────────────────────────────
    const gateway = runSafetyGateway(player_action, content_settings);

    if (gateway.decision === "REJECT") {
      return jsonResponse({ status: "REJECTED", player_message: gateway.player_message, policy_flags: gateway.policy_flags });
    }

    // ── STEP 2: Router ────────────────────────────────────────────
    // Accept resolved_route from Flutter's local parser assist.
    // Constrained to valid enum values — never trusted blindly.
    const validRoutes = ["NO_ROLL_DETERMINISTIC", "ROLL_REQUIRED", "CLARIFICATION_REQUIRED", "SAFE_REJECT", "UI_ACTION", "SYSTEM_TRANSFORMED_ACTION"];
    const resolvedRoute = body.resolved_route;
    const routeCategory: RouteCategory = (resolvedRoute && validRoutes.includes(resolvedRoute))
      ? resolvedRoute as RouteCategory
      : runDeterministicRouter(gateway.sanitized_input);

    if (routeCategory === "UI_ACTION") {
      return jsonResponse({ status: "UI_ACTION", route_category: routeCategory });
    }

    // ── STEP 3: Clarification — Flutter handles parser assist ─────
    // Flutter calls local Ollama, classifies intent, resubmits
    // with resolved_route. No state mutation until resolved.
    if (routeCategory === "CLARIFICATION_REQUIRED") {
      return jsonResponse({
        status: "CLARIFICATION_REQUIRED",
        route_category: routeCategory,
        player_message: "What do you do? Describe your action — attack, search, move, speak, or use an item.",
      });
    }

    // ── STEP 4: Simulation service (only state writer) ────────────
    const simResponse = await callFunction("simulation_service", {
      user_id,
      player_action: gateway.sanitized_input,
      route_category: routeCategory,
      gateway_decision: gateway.decision,
      narration_constraints: gateway.narration_constraints,
      previous_revision_id,
    });

    if (!simResponse.ok) {
      const err = await simResponse.text();
      throw new Error(`simulation_service failed: ${err}`);
    }

    const simResult = await simResponse.json();

    // ── STEP 5: Return to Flutter ─────────────────────────────────
    return jsonResponse({
      status: "OK",
      revision_id: simResult.revision_id,
      success_tier: simResult.success_tier,
      roll: simResult.roll,
      state_delta: simResult.state_delta,
      events: simResult.events,
      narration_context: simResult.narration_context,
      gateway_decision: gateway.decision,
      route_category: routeCategory,
      autosave_candidate: simResult.autosave_candidate,
    });

  } catch (err) {
    console.error("turn_orchestrator error:", err);
    return jsonResponse({ error: String(err) }, 500);
  }
});