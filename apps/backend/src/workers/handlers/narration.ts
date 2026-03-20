import { db } from "../../db/client.js";
import { revisions } from "../../db/schema.js";
import { eq } from "drizzle-orm";
import type { NarrationJobPayload } from "../types.js";

/**
 * Narration Job Handler
 * Generates premium narrative prose for player actions
 * 
 * Architecture rules:
 * - Narration is strictly secondary to truth (simulation result)
 * - If premium narration fails or times out, return deterministic template narration
 * - Allow at most one optional async retry with a cheaper/shorter prompt
 * - Must be idempotent and non-blocking
 * 
 * The handler attempts premium narration first; if that fails, it falls back to
 * deterministic template narration derived from the simulation result.
 */
export class NarrationJobHandler {
  constructor(private retryCount: number = 1) {}

  /**
   * Handle narration job
   * Generates narrative text for a turn and stores it for client consumption
   */
  async execute(payload: NarrationJobPayload): Promise<string> {
    const { revisionId, campaignId, saveSlotId, schemaVersion } = payload;

    try {
      // Fetch revision to access simulation result and events
      const revisionResult = await db
        .select()
        .from(revisions)
        .where(eq(revisions.id, revisionId))
        .limit(1);

      if (!revisionResult.length) {
        console.warn(`Revision ${revisionId} not found for narration job`);
        return this.getTemplateNarration(null);
      }

      const revision = revisionResult[0];
      const simulationResult = revision.simulationResult as any;

      // Try to generate premium narration
      try {
        const premiumNarration = await this.generatePremiumNarration(
          revision.canonicalState as any,
          simulationResult,
          revision.actionPacket as any
        );

        console.log(`Premium narration generated for revision ${revisionId}`);
        // TODO: Store premium narration artifact
        return premiumNarration;
      } catch (premiumError) {
        console.warn(
          `Premium narration failed for revision ${revisionId}, using template fallback:`,
          premiumError
        );

        // Fall back to template narration
        const templateNarration = this.getTemplateNarration(simulationResult);
        // TODO: Store template narration artifact
        return templateNarration;
      }
    } catch (error) {
      console.error(`Narration job failed for revision ${revisionId}:`, error);
      // Return minimal fallback if everything fails
      return "Your action completed.";
    }
  }

  /**
   * Generate premium narrative prose using model
   * Times out after configurable duration
   */
  private async generatePremiumNarration(
    canonicalState: any,
    simulationResult: any,
    actionPacket: any,
    timeoutMs: number = 30000
  ): Promise<string> {
    // TODO: Call LLM service with premium prompt
    // For now, return template as placeholder
    return this.getTemplateNarration(simulationResult);
  }

  /**
   * Get deterministic template narration
   * Always available as fallback
   */
  private getTemplateNarration(simulationResult: any | null): string {
    if (!simulationResult) {
      return "Your action was processed.";
    }

    const { successTier, events } = simulationResult;

    const tierDescriptions: Record<string, string> = {
      CRITICAL_FAILURE: "Your attempt failed badly.",
      FAILURE: "Your attempt did not succeed as intended.",
      PARTIAL_SUCCESS: "Your attempt partially succeeded.",
      FULL_SUCCESS: "Your attempt succeeded.",
      CRITICAL_SUCCESS: "Your attempt exceeded all expectations."
    };

    const tierText = tierDescriptions[successTier] || "Your action completed.";

    if (events && events.length > 0) {
      const eventDescriptions = events
        .map((ev: any) => this.describeEvent(ev.eventType))
        .filter((desc: string) => desc.length > 0);

      if (eventDescriptions.length > 0) {
        return `${tierText} ${eventDescriptions.join(" ")}`;
      }
    }

    return tierText;
  }

  /**
   * Describe a canonical event in template prose
   */
  private describeEvent(eventType: string): string {
    const eventDescriptions: Record<string, string> = {
      COMBAT_TURN_RESOLVED: "Combat resolved.",
      ENEMY_STATUS_APPLIED: "The enemy is affected.",
      QUEST_UPDATED: "Your quest progress changed.",
      LOCATION_CHANGED: "You moved to a new location.",
      ITEM_ACQUIRED: "You gained an item.",
      ITEM_LOST: "You lost an item.",
      RELATIONSHIP_CHANGED: "A relationship shifted.",
      CHAPTER_PROGRESSED: "The story advanced.",
      MOMENTUM_GAINED: "You gained momentum.",
      DANGER_INCREASED: "Danger increased.",
      PLAYER_DAMAGED: "You took damage.",
      PLAYER_HEALED: "You were healed."
    };

    return eventDescriptions[eventType] || "";
  }
}

export function createNarrationJobHandler(retryCount?: number) {
  return new NarrationJobHandler(retryCount);
}
