import type {
  PersistedAcceptedTurnCommit,
  PersistedCheckpointRecord,
  ClarificationStateRecord,
  PersistedClarificationState,
  PersistedEventLog,
  PersistedMigrationRecord,
  PersistedOutboxEvent,
  PersistedRollbackCommit,
  PersistedRevisionContext,
  PersistedTurnRequest,
  SaveHistorySnapshot,
  StoredSaveArtifact,
  StoredTurnRequest,
  TurnRunState,
  TurnIntakeRepository,
  TurnIntakeTransaction
} from "./repository.js";
import { extractCanonicalStateSnapshot } from "./state.js";

function buildTurnRequestKey(
  playerId: string,
  runId: string,
  saveSlotId: string,
  clientTurnId: string
) {
  return `${playerId}:${runId}:${saveSlotId}:${clientTurnId}`;
}

function buildClarificationKey(
  runId: string,
  saveSlotId: string,
  sceneFingerprint: string
) {
  return `${runId}:${saveSlotId}:${sceneFingerprint}`;
}

function buildRunKey(runId: string, saveSlotId: string) {
  return `${runId}:${saveSlotId}`;
}

function mapRevisionSnapshot(
  saveSnapshot: PersistedAcceptedTurnCommit["saveSnapshot"]
): StoredSaveArtifact {
  return {
    saveId: saveSnapshot.saveId,
    gameRevision: saveSnapshot.gameRevision,
    saveSlotId: saveSnapshot.saveSlotId,
    campaignId: saveSnapshot.campaignId,
    schemaVersion: saveSnapshot.schemaVersion,
    snapshotPointer: saveSnapshot.snapshotPointer,
    savedAt: saveSnapshot.savedAt,
    canonicalState: structuredClone(saveSnapshot.canonicalState),
    saveKind: "REVISION",
    displayName: null
  };
}

function sortByTimestampDescending<T extends { savedAt?: string; createdAt?: string }>(
  left: T,
  right: T
) {
  const leftTimestamp = left.savedAt ?? left.createdAt ?? "";
  const rightTimestamp = right.savedAt ?? right.createdAt ?? "";

  return rightTimestamp.localeCompare(leftTimestamp);
}

export interface InMemoryTurnIntakeRepository extends TurnIntakeRepository {
  inspect(): {
    turnRequests: StoredTurnRequest[];
    revisions: PersistedAcceptedTurnCommit["revision"][];
    saveSnapshots: StoredSaveArtifact[];
    eventLogs: PersistedEventLog[];
    outboxEvents: PersistedOutboxEvent[];
    checkpoints: PersistedCheckpointRecord[];
    migrationRecords: PersistedMigrationRecord[];
    runStates: TurnRunState[];
  };
}

export interface CreateInMemoryTurnIntakeRepositoryOptions {
  runStates?: TurnRunState[];
  revisions?: PersistedAcceptedTurnCommit["revision"][];
  saveSnapshots?: StoredSaveArtifact[];
  checkpoints?: PersistedCheckpointRecord[];
  migrationRecords?: PersistedMigrationRecord[];
}

class LockQueue {
  #pending = Promise.resolve();

  async run<T>(execute: () => Promise<T>) {
    const previous = this.#pending;
    let release: (() => void) | undefined;

    this.#pending = new Promise<void>((resolve) => {
      release = resolve;
    });

    await previous;

    try {
      return await execute();
    } finally {
      release?.();
    }
  }
}

export function createInMemoryTurnIntakeRepository(
  options: CreateInMemoryTurnIntakeRepositoryOptions = {}
): InMemoryTurnIntakeRepository {
  const turnRequests = new Map<string, StoredTurnRequest>();
  const clarificationStates = new Map<string, ClarificationStateRecord>();
  const lockQueues = new Map<string, LockQueue>();
  const revisions = new Map<string, PersistedAcceptedTurnCommit["revision"]>();
  const saveSnapshots = new Map<string, StoredSaveArtifact>(
    (options.saveSnapshots ?? []).map((record) => [record.saveId, structuredClone(record)])
  );
  const eventLogs = new Map<string, PersistedEventLog>();
  const outboxEvents = new Map<string, PersistedOutboxEvent>();
  const checkpoints = new Map<string, PersistedCheckpointRecord>(
    (options.checkpoints ?? []).map((record) => [record.checkpointId, structuredClone(record)])
  );
  const migrationRecords = new Map<string, PersistedMigrationRecord>(
    (options.migrationRecords ?? []).map((record) => [
      record.migrationId,
      structuredClone(record)
    ])
  );
  const runStates = new Map<string, TurnRunState>(
    (options.runStates ?? []).map((runState) => [
      buildRunKey(runState.runId, runState.saveSlotId),
      structuredClone(runState)
    ])
  );

  for (const revision of options.revisions ?? []) {
    revisions.set(revision.revisionId, structuredClone(revision));
  }

  return {
    async withTurnLock(runId, saveSlotId, execute) {
      const lockKey = buildRunKey(runId, saveSlotId);
      const lockQueue = lockQueues.get(lockKey) ?? new LockQueue();

      lockQueues.set(lockKey, lockQueue);

      return lockQueue.run(async () => {
        const transaction: TurnIntakeTransaction = {
          async findTurnRequest(playerId, lockedRunId, lockedSaveSlotId, clientTurnId) {
            return (
              turnRequests.get(
                buildTurnRequestKey(playerId, lockedRunId, lockedSaveSlotId, clientTurnId)
              ) ?? null
            );
          },
          async saveTurnRequest(record: PersistedTurnRequest) {
            turnRequests.set(
              buildTurnRequestKey(
                record.playerId,
                record.runId,
                record.saveSlotId,
                record.clientTurnId
              ),
              structuredClone(record)
            );
          },
          async getClarificationState(lockedRunId, lockedSaveSlotId, sceneFingerprint) {
            return (
              clarificationStates.get(
                buildClarificationKey(lockedRunId, lockedSaveSlotId, sceneFingerprint)
              ) ?? null
            );
          },
          async upsertClarificationState(record: PersistedClarificationState) {
            const storedRecord: ClarificationStateRecord = {
              sceneFingerprint: record.sceneFingerprint,
              ambiguityCount: record.ambiguityCount,
              lastTargetFingerprint: record.lastTargetFingerprint,
              lastRouteCategory: record.lastRouteCategory,
              lastInputFingerprint: record.lastInputFingerprint,
              lastSessionId: record.lastSessionId
            };

            clarificationStates.set(
              buildClarificationKey(record.runId, record.saveSlotId, record.sceneFingerprint),
              storedRecord
            );

            return storedRecord;
          },
          async clearClarificationState(lockedRunId, lockedSaveSlotId, sceneFingerprint) {
            clarificationStates.delete(
              buildClarificationKey(lockedRunId, lockedSaveSlotId, sceneFingerprint)
            );
          },
          async getRunState(playerId, lockedRunId, lockedSaveSlotId) {
            const runKey = buildRunKey(lockedRunId, lockedSaveSlotId);
            const storedState = runStates.get(runKey) ?? {
              playerId,
              runId: lockedRunId,
              saveSlotId: lockedSaveSlotId,
              campaignId: `campaign_${lockedRunId}`,
              activeRevisionId: null,
              canonicalState: null,
              recentRevisionContext: []
            };

            runStates.set(runKey, structuredClone(storedState));

            return structuredClone(storedState);
          },
          async getSaveHistory(playerId, lockedRunId, lockedSaveSlotId) {
            const runState = await this.getRunState(playerId, lockedRunId, lockedSaveSlotId);
            const revisionEntries = [...revisions.values()]
              .filter((revision) => revision.saveSlotId === lockedSaveSlotId)
              .map((revision) => structuredClone(revision))
              .sort((left, right) => right.savedAt.localeCompare(left.savedAt));
            const saveArtifacts = [...saveSnapshots.values()]
              .filter((snapshot) => snapshot.saveSlotId === lockedSaveSlotId)
              .map((snapshot) => structuredClone(snapshot))
              .sort(sortByTimestampDescending);
            const checkpointEntries = [...checkpoints.values()]
              .filter((checkpoint) =>
                revisionEntries.some((revision) => revision.revisionId === checkpoint.revisionId)
              )
              .map((checkpoint) => structuredClone(checkpoint))
              .sort(sortByTimestampDescending);

            return {
              playerId,
              runId: lockedRunId,
              saveSlotId: lockedSaveSlotId,
              campaignId: runState.campaignId,
              activeRevisionId: runState.activeRevisionId,
              revisions: revisionEntries,
              saveArtifacts,
              checkpoints: checkpointEntries
            } satisfies SaveHistorySnapshot;
          },
          async saveArtifact(record: StoredSaveArtifact) {
            saveSnapshots.set(record.saveId, structuredClone(record));
          },
          async deleteSaveArtifacts(saveIds: string[]) {
            for (const saveId of saveIds) {
              saveSnapshots.delete(saveId);
            }
          },
          async saveMigrationRecord(record: PersistedMigrationRecord) {
            migrationRecords.set(record.migrationId, structuredClone(record));
          },
          async commitAcceptedTurn(record) {
            const turnKey = buildTurnRequestKey(
              record.turnRequest.playerId,
              record.turnRequest.runId,
              record.turnRequest.saveSlotId,
              record.turnRequest.clientTurnId
            );
            const runKey = buildRunKey(record.turnRequest.runId, record.turnRequest.saveSlotId);
            const existingRunState = runStates.get(runKey) ?? {
              playerId: record.turnRequest.playerId,
              runId: record.turnRequest.runId,
              saveSlotId: record.turnRequest.saveSlotId,
              campaignId: `campaign_${record.turnRequest.runId}`,
              activeRevisionId: null,
              canonicalState: null,
              recentRevisionContext: []
            };

            turnRequests.set(turnKey, structuredClone(record.turnRequest));
            revisions.set(record.revision.revisionId, structuredClone(record.revision));
            saveSnapshots.set(
              record.saveSnapshot.saveId,
              mapRevisionSnapshot(record.saveSnapshot)
            );

            for (const eventLog of record.eventLogs) {
              eventLogs.set(eventLog.id, structuredClone(eventLog));
            }

            for (const outboxEvent of record.outboxEvents) {
              outboxEvents.set(outboxEvent.id, structuredClone(outboxEvent));
            }

            for (const checkpointRecord of record.checkpointRecords) {
              checkpoints.set(
                checkpointRecord.checkpointId,
                structuredClone(checkpointRecord)
              );
            }

            const nextRevisionContext: PersistedRevisionContext = {
              revisionId: record.revision.revisionId,
              turnCount: record.revision.canonicalState.turnCount,
              summaryJobQueued: record.revision.summaryJobQueued,
              summaryKind: record.revision.summaryKind,
              eventTypes: record.revision.events.map((event) => event.eventType)
            };

            runStates.set(runKey, {
              ...existingRunState,
              activeRevisionId: record.revision.revisionId,
              canonicalState: extractCanonicalStateSnapshot(record.saveSnapshot.canonicalState),
              recentRevisionContext: [
                nextRevisionContext,
                ...existingRunState.recentRevisionContext
              ].slice(0, 12)
            });
          },
          async commitRollback(record: PersistedRollbackCommit) {
            const runKey = buildRunKey(record.revision.runId, record.revision.saveSlotId);
            const existingRunState = runStates.get(runKey) ?? {
              playerId: "unknown_player",
              runId: record.revision.runId,
              saveSlotId: record.revision.saveSlotId,
              campaignId: `campaign_${record.revision.runId}`,
              activeRevisionId: null,
              canonicalState: null,
              recentRevisionContext: []
            };

            revisions.set(record.revision.revisionId, structuredClone(record.revision));
            saveSnapshots.set(
              record.saveSnapshot.saveId,
              mapRevisionSnapshot(record.saveSnapshot)
            );

            for (const eventLog of record.eventLogs) {
              eventLogs.set(eventLog.id, structuredClone(eventLog));
            }

            const nextRevisionContext: PersistedRevisionContext = {
              revisionId: record.revision.revisionId,
              turnCount: record.revision.canonicalState.turnCount,
              summaryJobQueued: record.revision.summaryJobQueued,
              summaryKind: record.revision.summaryKind,
              eventTypes: record.revision.events.map((event) => event.eventType)
            };

            runStates.set(runKey, {
              ...existingRunState,
              activeRevisionId: record.revision.revisionId,
              canonicalState: extractCanonicalStateSnapshot(record.saveSnapshot.canonicalState),
              recentRevisionContext: [
                nextRevisionContext,
                ...existingRunState.recentRevisionContext
              ].slice(0, 12)
            });
          }
        };

        return execute(transaction);
      });
    },
    inspect() {
      return {
        turnRequests: [...turnRequests.values()].map((record) => structuredClone(record)),
        revisions: [...revisions.values()].map((record) => structuredClone(record)),
        saveSnapshots: [...saveSnapshots.values()].map((record) => structuredClone(record)),
        eventLogs: [...eventLogs.values()].map((record) => structuredClone(record)),
        outboxEvents: [...outboxEvents.values()].map((record) => structuredClone(record)),
        checkpoints: [...checkpoints.values()].map((record) => structuredClone(record)),
        migrationRecords: [...migrationRecords.values()].map((record) =>
          structuredClone(record)
        ),
        runStates: [...runStates.values()].map((record) => structuredClone(record))
      };
    }
  };
}
