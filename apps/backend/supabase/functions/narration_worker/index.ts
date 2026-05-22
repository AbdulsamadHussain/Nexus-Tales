import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ── TYPES ────────────────────────────────────────────────────────

interface NarrationRequest {
  revision_id: string;
  user_id: string;
  narration_context: string;
  narration_constraints: string[];
}

// ── OLLAMA CALLER ────────────────────────────────────────────────
// Calls local Ollama. Falls back to code template if unreachable.
// Narration failure NEVER corrupts committed state — revision is
// already committed before this function is called.

async function callOllama(prompt: string): Promise<string> {
  const ollamaUrl = Deno.env.get("OLLAMA_URL") ?? "http://localhost:11434";

  const response = await fetch(`${ollamaUrl}/api/generate`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      model: "gemma4:e2b",
      prompt,
      stream: false,
      options: {
        temperature: 0.8,
        num_predict: 200,
      },
      // Disable thinking mode — we want prose output only
      system: "You are a dark fantasy game master narrator. Respond ONLY with vivid narrative prose. No thinking, no reasoning, no bullet points. 2-4 sentences maximum. Second person, present tense.",
    }),
  });

  if (!response.ok) throw new Error(`Ollama error: ${response.status}`);

  const data = await response.json();
  return data.response as string;
}

// ── FALLBACK TEMPLATE ────────────────────────────────────────────
// Architecture requirement: narrator timeout must never leave the
// player without a result. This builds prose from the revision data.

export function buildFallbackNarration(context: string): string {
  const lines = context.split("\n");
  const actionLine = lines.find((l) => l.startsWith("Player action:")) ?? "";
  const rollLine = lines.find((l) => l.startsWith("Roll:")) ?? "";
  const hpLine = lines.find((l) => l.startsWith("HP change:")) ?? "";

  const action = actionLine.replace("Player action:", "").replace(/"/g, "").trim();
  const hasRoll = rollLine.includes("FULL_SUCCESS") || rollLine.includes("CRITICAL_SUCCESS");
  const hasFail = rollLine.includes("FAILURE");
  const hpLoss = hpLine.includes("-");

  let narration = `You ${action.toLowerCase().replace(/^i /, "")}.`;
  if (hasRoll) narration += " The attempt succeeds.";
  if (hasFail) narration += " The attempt fails.";
  if (hpLoss) narration += " You take damage.";

  return narration;
}

// ── MAIN ─────────────────────────────────────────────────────────

if (import.meta.main) serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  try {
    const body: NarrationRequest = await req.json();
    const { revision_id, user_id, narration_context, narration_constraints } = body;

    // Build constraint instructions for the prompt
    const constraintText = narration_constraints.length > 0
      ? `Content constraints: ${narration_constraints.join(", ")}.`
      : "";

    const prompt = `${constraintText}

${narration_context}

Narrate what happens in 2-4 vivid sentences. Second person present tense. Dark fantasy tone. Do not repeat the action literally.`;

    // Attempt Ollama narration with 10 second timeout
    let narration: string;
    let usedFallback = false;

    try {
      const timeoutPromise = new Promise<never>((_, reject) =>
        setTimeout(() => reject(new Error("Ollama timeout")), 10_000)
      );
      narration = await Promise.race([callOllama(prompt), timeoutPromise]);
    } catch (err) {
      // Narration failure — use template fallback
      // This is the architecture's graceful degradation path
      console.warn("Narration fallback triggered:", err);
      narration = buildFallbackNarration(narration_context);
      usedFallback = true;
    }

    // Mark revision narration_done = true (convenience update only)
    // This does NOT affect canonical game state
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    await supabase
      .from("revisions")
      .update({ narration_done: true })
      .eq("id", revision_id)
      .eq("user_id", user_id);

    return new Response(
      JSON.stringify({ narration, used_fallback: usedFallback, revision_id }),
      {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  } catch (err) {
    console.error("narration_worker error:", err);
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});