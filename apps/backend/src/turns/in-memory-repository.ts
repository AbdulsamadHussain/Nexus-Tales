import type {
  ClarificationStateRecord,
  PersistedClarificationState,
  PersistedTurnRequest,
  StoredTurnRequest,
  TurnIntakeRepository,
  TurnIntakeTransaction
} from "./repository.js";

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

export function createInMemoryTurnIntakeRepository(): TurnIntakeRepository {
  const turnRequests = new Map<string, StoredTurnRequest>();
  const clarificationStates = new Map<string, ClarificationStateRecord>();
  const lockQueues = new Map<string, LockQueue>();

  return {
    async withTurnLock(runId, saveSlotId, execute) {
      const lockKey = `${runId}:${saveSlotId}`;
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
              { ...record }
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
          }
        };

        return execute(transaction);
      });
    }
  };
}
