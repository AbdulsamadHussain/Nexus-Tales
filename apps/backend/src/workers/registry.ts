import { PgBoss } from "pg-boss";
import type { WorkerServiceConfig, WorkerJobPayload, JobType } from "./types.js";
import { SummaryTriggerService, createDefaultSummaryTriggerConfig } from "./summary-trigger.js";
import { OutboxService } from "./outbox.js";

/**
 * Worker Service Registry
 * Manages job handler initialization and pg-boss lifecycle
 * Coordinates summary triggers, narration fallbacks, and image generation
 */
export class WorkerServiceRegistry {
  private pgBoss: PgBoss | null = null;
  private summaryTriggerService: SummaryTriggerService;
  private outboxService = new OutboxService();
  private config: WorkerServiceConfig;

  private jobHandlers: Record<
    JobType,
    (payload: WorkerJobPayload) => Promise<void>
  > = {
    SUMMARY: async (payload) => this.handleSummaryJob(payload as any),
    NARRATION: async (payload) => this.handleNarrationJob(payload as any),
    IMAGE: async (payload) => this.handleImageJob(payload as any)
  };

  constructor(config: WorkerServiceConfig) {
    this.config = config;
    this.summaryTriggerService = new SummaryTriggerService(
      config.summaryTriggerConfig
    );
  }

  /**
   * Initialize pg-boss and register job handlers
   */
  async initialize() {
    this.pgBoss = new PgBoss(this.config.pgBossConnectionString);
    
    await this.pgBoss.start();

    // Register job handlers
    (this.pgBoss as any).subscribe("summary", this.createSummaryHandler());
    (this.pgBoss as any).subscribe("narration", this.createNarrationHandler());
    (this.pgBoss as any).subscribe("image", this.createImageHandler());

    // Start outbox polling loop
    this.startOutboxPoller();
  }

  /**
   * Create summary job handler function
   */
  private createSummaryHandler() {
    return async (job: any) => {
      await this.jobHandlers.SUMMARY(job.data);
    };
  }

  /**
   * Create narration job handler function
   */
  private createNarrationHandler() {
    return async (job: any) => {
      await this.jobHandlers.NARRATION(job.data);
    };
  }

  /**
   * Create image job handler function
   */
  private createImageHandler() {
    return async (job: any) => {
      await this.jobHandlers.IMAGE(job.data);
    };
  }

  /**
   * Stop pg-boss and cleanup
   */
  async shutdown() {
    if (this.pgBoss) {
      await this.pgBoss.stop();
    }
  }

  /**
   * Get summary trigger service (for use during revision commit)
   */
  getSummaryTriggerService(): SummaryTriggerService {
    return this.summaryTriggerService;
  }

  /**
   * Get outbox service (for use during revision commit)
   */
  getOutboxService(): OutboxService {
    return this.outboxService;
  }

  /**
   * Enqueue a job to pg-boss
   * Called by the outbox poller after confirming outbox event is durable
   */
  async enqueueJob(jobType: JobType, payload: WorkerJobPayload) {
    if (!this.pgBoss) {
      throw new Error("WorkerServiceRegistry not initialized");
    }

    const queueName = jobType.toLowerCase();
    const timeoutConfig =
      jobType === "NARRATION"
        ? { expireInSeconds: Math.floor(this.config.narrationConfig.timeoutMs / 1000) }
        : jobType === "IMAGE"
          ? { expireInSeconds: Math.floor(this.config.imageConfig.timeoutMs / 1000) }
          : {};

    await this.pgBoss.send(queueName, payload, timeoutConfig);
  }

  /**
   * Start the outbox polling loop
   * Polls new outbox events and enqueues them to pg-boss
   */
  private startOutboxPoller() {
    setInterval(async () => {
      try {
        const events = await this.outboxService.getUnpublishedEvents(100);

        for (const event of events) {
          try {
            // Enqueue to pg-boss
            await this.enqueueJob(event.jobType as any, event.payload as any);

            // Mark as published
            await this.outboxService.markEventPublished(event.id);
          } catch (error) {
            console.error(
              `Failed to enqueue job ${event.id}:`,
              error
            );
            // Continue with next event; failed events stay in outbox for retry
          }
        }
      } catch (error) {
        console.error("Outbox polling error:", error);
      }
    }, this.config.outboxPollingIntervalMs);
  }

  /**
   * Summary job handler
   * Generates a human-readable recap of recent events for narrative continuity
   * Non-blocking, post-commit, and idempotent
   */
  private async handleSummaryJob(payload: any) {
    const { revisionId, campaignId, saveSlotId, jobType, uniquenessKey } = payload;

    // Check if already processed to ensure idempotency
    const job = await this.outboxService.getJobByUniquenessKey(uniquenessKey);
    if (job && job.status !== "QUEUED") {
      // Already processed, skip
      return;
    }

    try {
      // TODO: Implement actual summary generation logic
      // For now, mark as completed
      if (job) {
        await this.outboxService.updateJobStatus(job.id, "COMPLETED");
      }
    } catch (error) {
      console.error(`Summary job failed for revision ${revisionId}:`, error);
      if (job) {
        const newRetryCount = (job.retryCount || 0) + 1;
        if (newRetryCount > this.config.summaryTriggerConfig.debounceRevisions) {
          // Max retries exceeded, mark as failed
          await this.outboxService.updateJobStatus(job.id, "FAILED", newRetryCount);
        } else {
          // Retry
          await this.outboxService.updateJobStatus(job.id, "QUEUED", newRetryCount);
        }
      }
      throw error;
    }
  }

  /**
   * Narration job handler
   * Generates premium narrative prose for the turn
   * Must provide deterministic template fallback if it fails or times out
   */
  private async handleNarrationJob(payload: any) {
    const { revisionId, campaignId, saveSlotId, uniquenessKey } = payload;

    // Check if already processed to ensure idempotency
    const job = await this.outboxService.getJobByUniquenessKey(uniquenessKey);
    if (job && job.status !== "QUEUED") {
      // Already processed, skip
      return;
    }

    try {
      // TODO: Implement actual narration generation logic
      // For now, mark as completed
      if (job) {
        await this.outboxService.updateJobStatus(job.id, "COMPLETED");
      }
    } catch (error) {
      console.error(`Narration job failed for revision ${revisionId}:`, error);

      // Per architecture: narration failure should not block progression
      // Fallback to template narration is handled by the client
      if (job) {
        const newRetryCount = (job.retryCount || 0) + 1;
        if (newRetryCount > this.config.narrationConfig.retryCount) {
          // Max retries exceeded, mark as skipped (will use template)
          await this.outboxService.updateJobStatus(job.id, "SKIPPED", newRetryCount);
        } else {
          // Retry
          await this.outboxService.updateJobStatus(job.id, "QUEUED", newRetryCount);
        }
      }
    }
  }

  /**
   * Image job handler
   * Generates scene artwork asynchronously
   * Non-blocking and fully optional
   */
  private async handleImageJob(payload: any) {
    const { revisionId, campaignId, saveSlotId, sceneAnchorId, uniquenessKey } = payload;

    // Check if already processed to ensure idempotency
    const job = await this.outboxService.getJobByUniquenessKey(uniquenessKey);
    if (job && job.status !== "QUEUED") {
      // Already processed, skip
      return;
    }

    try {
      // TODO: Implement actual image generation logic
      // For now, mark as completed
      if (job) {
        await this.outboxService.updateJobStatus(job.id, "COMPLETED");
      }
    } catch (error) {
      console.error(`Image job failed for scene ${sceneAnchorId}:`, error);

      // Per architecture: image generation failure should not block progression
      if (job) {
        const newRetryCount = (job.retryCount || 0) + 1;
        if (newRetryCount > this.config.imageConfig.retryCount) {
          // Max retries exceeded, mark as skipped (will use placeholder)
          await this.outboxService.updateJobStatus(job.id, "SKIPPED", newRetryCount);
        } else {
          // Retry
          await this.outboxService.updateJobStatus(job.id, "QUEUED", newRetryCount);
        }
      }
    }
  }
}

/**
 * Create a worker service registry with default configuration
 */
export function createWorkerServiceRegistry(
  pgBossConnectionString: string
): WorkerServiceRegistry {
  const config: WorkerServiceConfig = {
    pgBossConnectionString,
    summaryTriggerConfig: createDefaultSummaryTriggerConfig(),
    narrationConfig: {
      enabled: true,
      retryCount: 1,
      timeoutMs: 30000, // 30 seconds max for narration
      fallbackToTemplate: true
    },
    imageConfig: {
      enabled: true,
      retryCount: 2,
      timeoutMs: 60000 // 60 seconds max for image generation
    },
    outboxPollingIntervalMs: 5000, // Poll every 5 seconds
    maxConcurrentWorkers: 5
  };

  return new WorkerServiceRegistry(config);
}
