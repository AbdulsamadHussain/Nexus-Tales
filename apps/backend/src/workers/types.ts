import type {
  SummaryJobSchema,
  NarrationJobSchema,
  ImageJobSchema,
  WorkerJobTypeSchema
} from "@nexus-tales/contracts";
import { z } from "zod";

/**
 * Summary Job Payload
 * Triggered by revision commit with summary-eligible flags.
 * Uniqueness key: summary:{revision_id}
 */
export type SummaryJobPayload = z.infer<typeof SummaryJobSchema>;

/**
 * Narration Job Payload
 * Triggered by revision commit; premium narration is optional.
 * Falls back to deterministic template narration.
 * Uniqueness key: narration:{revision_id}
 */
export type NarrationJobPayload = z.infer<typeof NarrationJobSchema>;

/**
 * Image Job Payload
 * Triggered on eligible scene/revision anchors.
 * Asynchronous and non-blocking.
 * Uniqueness key: image:{scene_anchor_id}:{revision_id}
 */
export type ImageJobPayload = z.infer<typeof ImageJobSchema>;

export type WorkerJobPayload =
  | SummaryJobPayload
  | NarrationJobPayload
  | ImageJobPayload;

export type JobType = z.infer<typeof WorkerJobTypeSchema>;

/**
 * Worker Job Status
 * QUEUED: Job has been enqueued to pg-boss
 * SKIPPED: Job was eligible but explicitly skipped (e.g., narration failure autocorrect)
 * COMPLETED: Job successfully completed
 * FAILED: Job failed and exhausted retries
 */
export enum WorkerJobStatus {
  QUEUED = "QUEUED",
  SKIPPED = "SKIPPED",
  COMPLETED = "COMPLETED",
  FAILED = "FAILED"
}

/**
 * Summary Trigger Rules (from architecture doc)
 * Hard triggers: Combat end, quest update, major relationship change
 * Soft triggers: Location change, chapter progression
 * Debounce: Skip if summary job already queued for recent revisions
 * Suppression window: Skip if last summary was within N revisions
 */
export interface SummaryTriggerConfig {
  hardTriggerFlags: Set<string>;
  softTriggerFlags: Set<string>;
  debounceRevisions: number;
  suppressionWindowRevisions: number;
  enabled: boolean;
}

/**
 * Outbox event for deferred post-commit job enqueue
 * Must be consumed transactionally before worker execution
 */
export interface OutboxEvent {
  id: string;
  revisionId: string | null;
  jobType: JobType;
  uniquenessKey: string;
  payload: WorkerJobPayload;
  publishedAt: Date | null;
  createdAt: Date;
}

/**
 * Job Record for idempotency and retry tracking
 * Stored to prevent duplicate worker artifacts from the same revision
 */
export interface JobRecord {
  id: string;
  revisionId: string | null;
  jobType: JobType;
  uniquenessKey: string;
  status: WorkerJobStatus;
  payload: WorkerJobPayload;
  retryCount: number;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Worker service configuration
 */
export interface WorkerServiceConfig {
  pgBossConnectionString: string;
  summaryTriggerConfig: SummaryTriggerConfig;
  narrationConfig: {
    enabled: boolean;
    retryCount: number;
    timeoutMs: number;
    fallbackToTemplate: boolean;
  };
  imageConfig: {
    enabled: boolean;
    retryCount: number;
    timeoutMs: number;
  };
  outboxPollingIntervalMs: number;
  maxConcurrentWorkers: number;
}
