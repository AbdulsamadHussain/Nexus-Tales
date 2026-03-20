import { db } from "../db/client.js";
import { outboxEvents, jobRecords } from "../db/schema.js";
import type { WorkerJobPayload, JobType } from "./types.js";
import { WorkerJobStatus } from "./types.js";
import { eq, isNull, desc } from "drizzle-orm";

/**
 * Outbox Service
 * Implements transactional outbox pattern for reliable post-commit worker job enqueue.
 * Jobs are persisted to the outbox within the same transaction as the revision commit,
 * then consumed by a background poller that enqueues them to pg-boss.
 *
 * This ensures:
 * - No job is enqueued before the revision is durable
 * - Duplicate jobs are prevented via uniqueness keys
 * - Jobs can be retried safely without creating duplicate artifacts
 */
export class OutboxService {
  /**
   * Enqueue a job to the outbox within a transaction
   * Must be called inside the same database transaction as the revision commit
   *
   * Returns { alreadyExists: true } if a job with this uniqueness key already exists
   * Returns { alreadyExists: false } if the job was successfully enqueued
   */
  async enqueueJobInTransaction(
    revisionId: string,
    jobType: JobType,
    uniquenessKey: string,
    payload: WorkerJobPayload
  ): Promise<{ alreadyExists: boolean }> {
    // Check if a job with this uniqueness key already exists
    const existing = await db
      .select()
      .from(jobRecords)
      .where(eq(jobRecords.uniquenessKey, uniquenessKey))
      .limit(1);

    if (existing.length > 0) {
      return { alreadyExists: true };
    }

    // Create outbox event
    const outboxId = `outbox-${Date.now()}-${Math.random().toString(36).slice(2)}`;
    await db.insert(outboxEvents).values({
      id: outboxId,
      revisionId,
      jobType,
      uniquenessKey,
      payload: payload as any,
      publishedAt: null,
      createdAt: new Date()
    });

    // Create job record
    const jobId = `job-${Date.now()}-${Math.random().toString(36).slice(2)}`;
    await db.insert(jobRecords).values({
      id: jobId,
      revisionId,
      jobType,
      uniquenessKey,
      status: WorkerJobStatus.QUEUED,
      payload: payload as any,
      retryCount: 0,
      createdAt: new Date(),
      updatedAt: new Date()
    });

    return { alreadyExists: false };
  }

  /**
   * Get unpublished outbox events
   * Called by the outbox poller to find events ready for pg-boss enqueue
   */
  async getUnpublishedEvents(limit: number = 100) {
    return db
      .select()
      .from(outboxEvents)
      .where(isNull(outboxEvents.publishedAt))
      .limit(limit);
  }

  /**
   * Mark an outbox event as published
   * Called after successfully enqueueing to pg-boss
   */
  async markEventPublished(outboxEventId: string) {
    await db
      .update(outboxEvents)
      .set({ publishedAt: new Date() })
      .where(eq(outboxEvents.id, outboxEventId));
  }

  /**
   * Get a job record by uniqueness key
   * Used to check if a job has already been processed
   */
  async getJobByUniquenessKey(uniquenessKey: string) {
    const result = await db
      .select()
      .from(jobRecords)
      .where(eq(jobRecords.uniquenessKey, uniquenessKey))
      .limit(1);

    return result[0] || null;
  }

  /**
   * Update job record status
   */
  async updateJobStatus(
    jobId: string,
    status: string,
    retryCount?: number
  ) {
    const updates: any = {
      status,
      updatedAt: new Date()
    };

    if (retryCount !== undefined) {
      updates.retryCount = retryCount;
    }

    await db.update(jobRecords)
      .set(updates)
      .where(eq(jobRecords.id, jobId));
  }

  /**
   * Get last summary job for a revision
   * Used to check suppression window and debounce
   */
  async getLastSummaryJob(limit: number = 1) {
    return db
      .select()
      .from(jobRecords)
      .where(eq(jobRecords.jobType, "SUMMARY"))
      .orderBy(desc(jobRecords.createdAt))
      .limit(limit);
  }
}

export function createOutboxService() {
  return new OutboxService();
}
