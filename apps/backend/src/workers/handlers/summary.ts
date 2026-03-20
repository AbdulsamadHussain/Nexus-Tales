import { db } from "../../db/client.js";
import { revisions, eventLogs } from "../../db/schema.js";
import { eq } from "drizzle-orm";
import type { SummaryJobPayload } from "../types.js";

/**
 * Summary Job Handler
 * Generates a human-readable recap of recent events for narrative continuity
 * 
 * Summary triggers include:
 * - Hard triggers: Combat end, quest completion, major relationship change
 * - Soft triggers: Location change, chapter progression
 * - Debounce: Skip if summary already queued in recent revisions
 * - Suppression window: Skip if last summary was within N revisions
 * 
 * Non-blocking, post-commit, and must be idempotent
 */
export class SummaryJobHandler {
  /**
   * Handle summary job - generate event recap
   */
  async execute(payload: SummaryJobPayload): Promise<void> {
    const { revisionId, campaignId, saveSlotId, schemaVersion, jobType, uniquenessKey } = payload;

    // Fetch the target revision to access canonical state and events
    const revisionResult = await db
      .select()
      .from(revisions)
      .where(eq(revisions.id, revisionId))
      .limit(1);

    if (!revisionResult.length) {
      console.warn(`Revision ${revisionId} not found for summary job`);
      return;
    }

    const revision = revisionResult[0];

    // Fetch recent events for this revision
    const recentEvents = await db
      .select()
      .from(eventLogs)
      .where(eq(eventLogs.revisionId, revisionId));

    // Extract summary-relevant event types
    const eventTypes = recentEvents.map((ev) => ev.eventType);

    // Generate summary based on events
    const summaryContent = this.generateSummaryContent(
      eventTypes,
      revision.simulationResult as any,
      revision.canonicalState as any
    );

    // TODO: Store summary artifact
    // For now, just log that summary was generated
    console.log(`Summary generated for revision ${revisionId}:`, summaryContent);

    // Store summary metadata in a summary artifact table
    // (would be added to schema)
  }

  /**
   * Generate summary content from events
   */
  private generateSummaryContent(
    eventTypes: string[],
    simulationResult: any,
    canonicalState: any
  ): string {
    const eventSummary = eventTypes.join(", ");
    const scene = canonicalState?.sceneId || "unknown scene";
    const turnCount = canonicalState?.turnCount || 0;

    return `Turn ${turnCount} in ${scene}: ${eventSummary}`;
  }

  /**
   * Check whether this summary is redundant
   * (would compare with recent summaries)
   */
  private isRedundant(): boolean {
    // TODO: Compare with recent summaries
    return false;
  }
}

export function createSummaryJobHandler() {
  return new SummaryJobHandler();
}
