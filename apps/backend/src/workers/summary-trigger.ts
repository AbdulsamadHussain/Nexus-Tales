import type { SimulationResult } from "@nexus-tales/contracts";
import type { SummaryTriggerConfig } from "./types.js";

/**
 * Summary Trigger Service
 * Determines if a revision should trigger a summary job according to architecture rules:
 * - Hard triggers: combat end, quest update, major relationship change
 * - Soft triggers: location change, chapter progression
 * - Debounce: skip if summary already queued in debounce window
 * - Suppression window: skip if last summary was within suppression window
 */
export class SummaryTriggerService {
  constructor(private config: SummaryTriggerConfig) {}

  /**
   * Evaluate if a revision should trigger a summary
   * Returns the summary kind (HARD or SOFT) or null if no trigger
   */
  evaluateTrigger(
    simulationResult: SimulationResult,
    summaryFlags: string[],
    lastSummaryRevisionOffset: number | null
  ): "HARD" | "SOFT" | null {
    if (!this.config.enabled) {
      return null;
    }

    // Check hard triggers first
    const hasHardTrigger = summaryFlags.some((flag) =>
      this.config.hardTriggerFlags.has(flag)
    );

    if (hasHardTrigger) {
      // Hard triggers always fire unless in suppression window
      if (
        lastSummaryRevisionOffset === null ||
        lastSummaryRevisionOffset > this.config.suppressionWindowRevisions
      ) {
        return "HARD";
      }
      // Otherwise skip due to suppression window
      return null;
    }

    // Check soft triggers
    const hasSoftTrigger = summaryFlags.some((flag) =>
      this.config.softTriggerFlags.has(flag)
    );

    if (hasSoftTrigger) {
      // Soft triggers fire unless in suppression window
      if (
        lastSummaryRevisionOffset === null ||
        lastSummaryRevisionOffset > this.config.suppressionWindowRevisions
      ) {
        return "SOFT";
      }
      // Otherwise skip due to suppression window
      return null;
    }

    return null;
  }

  /**
   * Check if summary would be debounced
   * (e.g., if a summary job is already queued for a recent revision)
   */
  isDebounced(lastSummaryJobQueuedRevisionOffset: number | null): boolean {
    if (lastSummaryJobQueuedRevisionOffset === null) {
      return false;
    }

    return lastSummaryJobQueuedRevisionOffset < this.config.debounceRevisions;
  }
}

/**
 * Create default summary trigger configuration
 * Hard triggers: COMBAT_ACTIVE, QUEST_UPDATED, MAJOR_RELATIONSHIP_CHANGE
 * Soft triggers: LOCATION_CHANGED, CHAPTER_PROGRESSED
 */
export function createDefaultSummaryTriggerConfig(): SummaryTriggerConfig {
  return {
    hardTriggerFlags: new Set([
      "COMBAT_ACTIVE",
      "QUEST_UPDATED",
      "MAJOR_RELATIONSHIP_CHANGE"
    ]),
    softTriggerFlags: new Set([
      "LOCATION_CHANGED",
      "CHAPTER_PROGRESSED"
    ]),
    debounceRevisions: 2,
    suppressionWindowRevisions: 5,
    enabled: true
  };
}
