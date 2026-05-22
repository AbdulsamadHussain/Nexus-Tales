import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface SummaryRequest {
  user_id: string;
  character_id: string;
  revision_id: string;
  trigger_type: "hard" | "soft";
  events: string[];
  narration_context: string;
  ollama_url?: string;
}

export function buildFallbackSummary(
  events: string[],
  characterName: string,
  location: string,
): string {
  const notable = events
    .filter((e) =>
      e.startsWith("STORY_BEAT:") ||
      e.startsWith("NPC_DEFEATED") ||
      e.startsWith("QUEST_UPDATED") ||
      e.startsWith("RELATIONSHIP_TIER_CHANGED:")
    )
    .map((e) =>
      e
        .replace("STORY_BEAT:", "Beat: ")
        .replace("RELATIONSHIP_TIER_CHANGED:", "Relationship changed: ")
    )
    .join(". ");
  return notable || `${characterName} continued exploring ${location}.`;
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
    const body: SummaryRequest = await req.json();
    const { user_id, character_id, revision_id, trigger_type, events, narration_context, ollama_url } = body;

    if (!user_id || !character_id || !revision_id) {
      return jsonResponse({ error: "Missing required fields: user_id, character_id, revision_id" }, 400);
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SVC_ROLE_KEY")!,
    );

    // ── Load canonical state for context ─────────────────────────
    const { data: state } = await supabase
      .from("canonical_state")
      .select("character_name, character_class, current_location, campaign_id, xp, level")
      .eq("user_id", user_id)
      .eq("character_id", character_id)
      .single();

    // ── Build summary prompt ──────────────────────────────────────
    const keyEvents = events
      .filter((e) => !e.startsWith("COMBAT_TURN_RESOLVED"))
      .join(", ");

    const prompt = `You are a dark fantasy chronicle writer. Write a 2-3 sentence summary of what just happened in this RPG session turn. Be specific about what changed. No preamble.

Character: ${state?.character_name} the ${state?.character_class}
Location: ${state?.current_location}
Key events this turn: ${keyEvents || "exploration"}
Trigger: ${trigger_type} summary

Narration context:
${narration_context.slice(0, 800)}

Write only the summary, 2-3 sentences maximum.`;

    // ── Call Ollama for summary generation ────────────────────────
    // Note: summary_worker is called from Flutter which passes the
    // ollama_url since Edge Functions can't reach localhost.
    let summaryText = "";

    if (ollama_url) {
      try {
        const ollamaResponse = await fetch(`${ollama_url}/api/generate`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            model: "gemma4:e2b",
            prompt,
            stream: false,
            think: false,
            options: { temperature: 0.5, num_predict: 100 },
          }),
        });

        if (ollamaResponse.ok) {
          const data = await ollamaResponse.json();
          const raw = (data.response as string ?? "").trim();
          if (raw.includes("</think>")) {
            summaryText = raw.substring(raw.lastIndexOf("</think>") + 8).trim();
          } else {
            summaryText = raw;
          }
        }
      } catch (e) {
        console.warn("Ollama summary generation failed:", e);
      }
    }

    // Fallback: deterministic event-log summary
    if (!summaryText) {
      summaryText = buildFallbackSummary(
        events,
        state?.character_name ?? "The adventurer",
        state?.current_location ?? "the area",
      );
    }

    // ── Store summary ─────────────────────────────────────────────
    const { data: summary, error } = await supabase
      .from("chapter_summaries")
      .insert({
        user_id,
        revision_id,
        campaign_id: state?.campaign_id,
        summary_type: trigger_type,
        summary_text: summaryText,
        events_covered: events,
        trigger: trigger_type,
        content: summaryText,
      })
      .select()
      .single();

    if (error) throw error;

    return jsonResponse({
      status: "OK",
      summary_id: summary.id,
      summary_text: summaryText,
      trigger_type,
    });

  } catch (err) {
    console.error("summary_worker error:", err);
    return jsonResponse({ error: String(err) }, 500);
  }
});