import type {
  TurnAuthoritativeResponse,
  SimulationResult,
  CanonicalEvent
} from "@nexus-tales/contracts";
import type { SummaryTriggerService } from "./summary-trigger.js";
import type { TurnRunState } from "../turns/repository.js";

/**
 * Worker Integration Service
 * Bridges turn commit logic with worker trigger decisions
 * 
 * Used during revision commit to:
 * - Evaluate if a summary job should be triggered
 * - Determine debounce/suppression windows
 * - Provide summary trigger kind to the commit plan
 */
export class WorkerIntegrationService {
  constructor(private summaryTriggerService: SummaryTriggerService) {}

  /**
   * Evaluate whether a summary should be triggered for this revision
   * Returns "HARD", "SOFT", or null
   */
  evaluateSummaryTrigger(
    simulationResult: SimulationResult,
    runState: TurnRunState,
    currentTurnCount: number,
    nextTurnCount: number
  ): "HARD" | "SOFT" | null {
    // Extract summary flags from simulation result
    const summaryFlags = simulationResult.summaryFlags || [];

    // Calculate offset of last summary (if any)
    const lastSummaryRevision = runState.recentRevisionContext.find(
      (rev) => rev.summaryJobQueued
    );
    const lastSummaryRevisionOffset = lastSummaryRevision
      ? nextTurnCount - lastSummaryRevision.turnCount
      : null;

    // Calculate offset of last summary job enqueued
    const lastSummaryJobRevision = runState.recentRevisionContext.find(
      (rev) => rev.summaryKind !== null
    );
    const lastSummaryJobRevisionOffset = lastSummaryJobRevision
      ? nextTurnCount - lastSummaryJobRevision.turnCount
      : null;

    // Check debounce - if a summary job was recently queued, skip
    if (this.summaryTriggerService.isDebounced(lastSummaryJobRevisionOffset)) {
      return null;
    }

    // Evaluate trigger based on simulation result flags
    return this.summaryTriggerService.evaluateTrigger(
      simulationResult,
      summaryFlags,
      lastSummaryRevisionOffset
    );
  }

  /**
   * Get worker jobs response for a turn
   * Called after revision commit to inform client of pending/queued jobs
   */
  buildWorkerJobsResponse(
    workerJobs: TurnAuthoritativeResponse["workerJobs"]
  ): TurnAuthoritativeResponse["workerJobs"] {
    // Validate that all worker jobs have required fields
    return workerJobs.filter((job) => {
      return job.jobType && job.jobId && job.uniquenessKey && job.status;
    });
  }
}

export function createWorkerIntegrationService(
  summaryTriggerService: SummaryTriggerService
): WorkerIntegrationService {
  return new WorkerIntegrationService(summaryTriggerService);
}
