import { randomUUID } from "node:crypto";

import type {
  CanonicalEvent,
  ManualSaveRequest,
  ManualSaveResponse,
  RevisionHistoryRequest,
  RevisionHistoryResponse,
  RollbackRequest,
  RollbackResponse,
  RevisionRecord,
  SaveArtifact
} from "@nexus-tales/contracts";
import {
  ManualSaveResponseSchema,
  PERSISTENCE_SCHEMA_VERSION,
  RevisionHistoryResponseSchema,
  RevisionRecordSchema,
  RollbackResponseSchema,
  RULESET_VERSION,
  SaveSnapshotSchema
} from "@nexus-tales/contracts";

import { buildStableHash } from "../turns/helpers.js";
import type {
  SaveHistorySnapshot,
  StoredSaveArtifact,
  TurnIntakeRepository
} from "../turns/repository.js";
import { migrateCanonicalState, SaveMigrationError } from "./migrations.js";

function buildOpaqueId(prefix: string) {
  return `${prefix}_${randomUUID().replace(/-/g, "")}`;
}

function buildSnapshotPointer(canonicalState: unknown) {
  return `snapshot:${buildStableHash(canonicalState).slice(0, 24)}`;
}

function buildEventId(revisionId: string, index: number, event: CanonicalEvent) {
  return `evt_${buildStableHash({ revisionId, index, event }).slice(0, 24)}`;
}

function buildNowTimestamp() {
  return new Date().toISOString();
}

function buildSaveArtifact(record: StoredSaveArtifact, saveKind = record.saveKind): SaveArtifact {
  return {
    saveId: record.saveId,
    gameRevision: record.gameRevision,
    saveSlotId: record.saveSlotId,
    campaignId: record.campaignId,
    schemaVersion: record.schemaVersion,
    snapshotPointer: record.snapshotPointer,
    savedAt: record.savedAt,
    saveKind,
    displayName: record.displayName
  };
}

function buildRevisionHistoryEntries(history: SaveHistorySnapshot) {
  return history.revisions.map((revision) => ({
    revisionId: revision.revisionId,
    previousRevisionId: revision.previousRevisionId,
    savedAt: revision.savedAt,
    turnCount: revision.canonicalState.turnCount,
    autosaveEligible: revision.autosaveEligible,
    summaryJobQueued: revision.summaryJobQueued,
    summaryKind: revision.summaryKind,
    successTier: revision.simulationResult.successTier,
    commitKind: revision.commitKind,
    restoredFromRevisionId: revision.restoredFromRevisionId,
    eventTypes: revision.events.map((event) => event.eventType),
    isActive: revision.revisionId === history.activeRevisionId
  }));
}

function buildAutosaves(history: SaveHistorySnapshot, autosaveRingSize: number) {
  const revisionSnapshots = new Map(
    history.saveArtifacts
      .filter((save) => save.saveKind === "REVISION")
      .map((save) => [save.gameRevision, save] as const)
  );

  return history.revisions
    .filter((revision) => revision.autosaveEligible)
    .slice(0, autosaveRingSize)
    .map((revision) => {
      const revisionSnapshot = revisionSnapshots.get(revision.revisionId);

      if (revisionSnapshot) {
        return buildSaveArtifact(revisionSnapshot, "AUTOSAVE");
      }

      return buildSaveArtifact(
        {
          saveId: `autosave_${revision.revisionId}`,
          gameRevision: revision.revisionId,
          saveSlotId: revision.saveSlotId,
          campaignId: history.campaignId,
          schemaVersion: revision.schemaVersion,
          snapshotPointer: revision.canonicalStatePointer,
          savedAt: revision.savedAt,
          canonicalState: revision.canonicalState,
          saveKind: "AUTOSAVE",
          displayName: null
        },
        "AUTOSAVE"
      );
    });
}

type ResolvedRollbackTarget = {
  targetKind: "REVISION" | "SAVE" | "CHECKPOINT";
  sourceRevisionId: string | null;
  sourceSaveId: string | null;
  sourceCheckpointId: string | null;
  schemaVersion: number;
  canonicalState: unknown;
};

function resolveRollbackTarget(
  history: SaveHistorySnapshot,
  request: RollbackRequest
): ResolvedRollbackTarget | null {
  if (request.saveId) {
    const saveArtifact = history.saveArtifacts.find((save) => save.saveId === request.saveId);

    if (!saveArtifact) {
      return null;
    }

    return {
      targetKind: "SAVE",
      sourceRevisionId: saveArtifact.gameRevision,
      sourceSaveId: saveArtifact.saveId,
      sourceCheckpointId: null,
      schemaVersion: saveArtifact.schemaVersion,
      canonicalState: saveArtifact.canonicalState
    };
  }

  if (request.checkpointId) {
    const checkpoint = history.checkpoints.find(
      (candidate) => candidate.checkpointId === request.checkpointId
    );

    if (!checkpoint) {
      return null;
    }

    const revision = history.revisions.find(
      (candidate) => candidate.revisionId === checkpoint.revisionId
    );

    if (!revision) {
      return null;
    }

    return {
      targetKind: "CHECKPOINT",
      sourceRevisionId: revision.revisionId,
      sourceSaveId: null,
      sourceCheckpointId: checkpoint.checkpointId,
      schemaVersion: revision.schemaVersion,
      canonicalState: revision.canonicalState
    };
  }

  if (request.revisionId) {
    const revision = history.revisions.find(
      (candidate) => candidate.revisionId === request.revisionId
    );

    if (!revision) {
      return null;
    }

    return {
      targetKind: "REVISION",
      sourceRevisionId: revision.revisionId,
      sourceSaveId: null,
      sourceCheckpointId: null,
      schemaVersion: revision.schemaVersion,
      canonicalState: revision.canonicalState
    };
  }

  return null;
}

function buildRollbackMessage(target: ResolvedRollbackTarget, appliedSteps: string[]) {
  const baseMessage =
    target.targetKind === "CHECKPOINT"
      ? "Protected checkpoint restored as the active canonical state."
      : target.targetKind === "SAVE"
        ? "Selected save restored as the active canonical state."
        : "Selected revision restored as the active canonical state.";

  if (appliedSteps.length === 0) {
    return baseMessage;
  }

  return `${baseMessage} Migration steps applied: ${appliedSteps.join(", ")}.`;
}

export class SaveManagementError extends Error {
  readonly code: string;
  readonly statusCode: number;
  readonly details: Record<string, unknown>;

  constructor(
    code: string,
    message: string,
    statusCode: number,
    details: Record<string, unknown> = {}
  ) {
    super(message);
    this.name = "SaveManagementError";
    this.code = code;
    this.statusCode = statusCode;
    this.details = details;
  }
}

export interface SaveManagementConfig {
  autosaveRingSize: number;
  manualSaveLimit: number;
}

export interface SaveManagementService {
  getHistory(request: RevisionHistoryRequest): Promise<RevisionHistoryResponse>;
  createManualSave(request: ManualSaveRequest): Promise<ManualSaveResponse>;
  rollback(request: RollbackRequest): Promise<RollbackResponse>;
}

export function createSaveManagementService(options: {
  repository: TurnIntakeRepository;
  config: SaveManagementConfig;
}): SaveManagementService {
  return {
    async getHistory(request) {
      return options.repository.withTurnLock(request.runId, request.saveSlotId, async (tx) => {
        const history = await tx.getSaveHistory(
          request.playerId,
          request.runId,
          request.saveSlotId
        );

        return RevisionHistoryResponseSchema.parse({
          playerId: request.playerId,
          runId: request.runId,
          saveSlotId: request.saveSlotId,
          activeRevisionId: history.activeRevisionId,
          revisions: buildRevisionHistoryEntries(history),
          manualSaves: history.saveArtifacts
            .filter((save) => save.saveKind === "MANUAL")
            .map((save) => buildSaveArtifact(save)),
          autosaves: buildAutosaves(history, options.config.autosaveRingSize),
          checkpoints: history.checkpoints,
          autosaveRingSize: options.config.autosaveRingSize,
          manualSaveLimit: options.config.manualSaveLimit
        });
      });
    },
    async createManualSave(request) {
      return options.repository.withTurnLock(request.runId, request.saveSlotId, async (tx) => {
        const history = await tx.getSaveHistory(
          request.playerId,
          request.runId,
          request.saveSlotId
        );
        const activeRevision = history.activeRevisionId
          ? history.revisions.find((revision) => revision.revisionId === history.activeRevisionId)
          : null;

        if (!activeRevision) {
          throw new SaveManagementError(
            "NO_ACTIVE_REVISION",
            "Manual save requires an active authoritative revision.",
            409
          );
        }

        const manualSaveRecord: StoredSaveArtifact = {
          saveId: buildOpaqueId("save"),
          gameRevision: activeRevision.revisionId,
          saveSlotId: request.saveSlotId,
          campaignId: history.campaignId,
          schemaVersion: activeRevision.schemaVersion,
          snapshotPointer: buildSnapshotPointer(activeRevision.canonicalState),
          savedAt: buildNowTimestamp(),
          canonicalState: activeRevision.canonicalState,
          saveKind: "MANUAL",
          displayName: request.displayName.trim()
        };

        await tx.saveArtifact(manualSaveRecord);

        const existingManualSaves = history.saveArtifacts
          .filter((save) => save.saveKind === "MANUAL")
          .sort((left, right) => right.savedAt.localeCompare(left.savedAt));
        const allManualSaves = [manualSaveRecord, ...existingManualSaves].sort((left, right) =>
          right.savedAt.localeCompare(left.savedAt)
        );
        const savesToDelete = allManualSaves.slice(options.config.manualSaveLimit);

        if (savesToDelete.length > 0) {
          await tx.deleteSaveArtifacts(savesToDelete.map((save) => save.saveId));
        }

        return ManualSaveResponseSchema.parse({
          save: buildSaveArtifact(manualSaveRecord),
          manualSaveLimit: options.config.manualSaveLimit,
          manualSaveCount: Math.min(allManualSaves.length, options.config.manualSaveLimit)
        });
      });
    },
    async rollback(request) {
      return options.repository.withTurnLock(request.runId, request.saveSlotId, async (tx) => {
        const history = await tx.getSaveHistory(
          request.playerId,
          request.runId,
          request.saveSlotId
        );
        const target = resolveRollbackTarget(history, request);

        if (!target) {
          throw new SaveManagementError(
            "ROLLBACK_TARGET_NOT_FOUND",
            "The requested rollback target was not found on this save slot.",
            404
          );
        }

        let migratedState;

        try {
          migratedState = migrateCanonicalState({
            canonicalState: target.canonicalState,
            fromSchemaVersion: target.schemaVersion,
            sourceRevisionId: target.sourceRevisionId,
            sourceSaveId: target.sourceSaveId
          });
        } catch (error) {
          if (!(error instanceof SaveMigrationError)) {
            throw error;
          }

          await tx.saveMigrationRecord({
            migrationId: buildOpaqueId("migration"),
            revisionId: target.sourceRevisionId,
            saveId: target.sourceSaveId,
            fromSchemaVersion: target.schemaVersion,
            toSchemaVersion: PERSISTENCE_SCHEMA_VERSION,
            status: "FAILED",
            debugBundle: error.debugBundle
          });

          throw new SaveManagementError(
            "SAVE_MIGRATION_FAILED",
            "The selected save could not be migrated safely.",
            422,
            {
              debugBundle: error.debugBundle
            }
          );
        }

        if (migratedState.appliedSteps.length > 0) {
          await tx.saveMigrationRecord({
            migrationId: buildOpaqueId("migration"),
            revisionId: target.sourceRevisionId,
            saveId: target.sourceSaveId,
            fromSchemaVersion: target.schemaVersion,
            toSchemaVersion: PERSISTENCE_SCHEMA_VERSION,
            status: "SUCCEEDED",
            debugBundle: null
          });
        }

        const savedAt = buildNowTimestamp();
        const revisionId = buildOpaqueId("rev");
        const saveSnapshot = SaveSnapshotSchema.parse({
          saveId: buildOpaqueId("snapshot"),
          gameRevision: revisionId,
          saveSlotId: request.saveSlotId,
          campaignId: history.campaignId,
          schemaVersion: PERSISTENCE_SCHEMA_VERSION,
          snapshotPointer: buildSnapshotPointer(migratedState.canonicalState),
          savedAt,
          canonicalState: migratedState.canonicalState
        });
        const events: CanonicalEvent[] = [
          {
            eventType: "ROLLBACK_APPLIED",
            entityId: target.sourceRevisionId,
            occurredAt: savedAt,
            metadata: {
              restoredFromRevisionId: target.sourceRevisionId,
              restoredFromSaveId: target.sourceSaveId,
              restoredFromCheckpointId: target.sourceCheckpointId
            }
          }
        ];

        if (target.sourceCheckpointId) {
          events.push({
            eventType: "CHECKPOINT_RESTORED",
            entityId: target.sourceCheckpointId,
            occurredAt: savedAt,
            metadata: {
              checkpointId: target.sourceCheckpointId,
              revisionId: target.sourceRevisionId
            }
          });
        }

        if (target.targetKind === "SAVE") {
          events.push({
            eventType: "SAVE_RESTORED",
            entityId: target.sourceSaveId,
            occurredAt: savedAt,
            metadata: {
              saveId: target.sourceSaveId,
              revisionId: target.sourceRevisionId
            }
          });
        }

        if (migratedState.appliedSteps.length > 0) {
          events.push({
            eventType: "SAVE_MIGRATION_APPLIED",
            entityId: target.sourceSaveId ?? target.sourceRevisionId,
            occurredAt: savedAt,
            metadata: {
              appliedSteps: migratedState.appliedSteps
            }
          });
        }

        const revision: RevisionRecord = RevisionRecordSchema.parse({
          revisionId,
          previousRevisionId: history.activeRevisionId,
          rulesetVersion: RULESET_VERSION,
          schemaVersion: PERSISTENCE_SCHEMA_VERSION,
          savedAt,
          playerId: request.playerId,
          runId: request.runId,
          saveSlotId: request.saveSlotId,
          actionPacket: {
            actionType: "SYSTEM_ROLLBACK",
            targetEntityId:
              target.sourceCheckpointId ?? target.sourceSaveId ?? target.sourceRevisionId,
            method: target.targetKind.toLowerCase(),
            stance: null,
            candidateSkills: [],
            requiresRoll: false
          },
          simulationResult: {
            rulesetVersion: RULESET_VERSION,
            successTier: "FULL_SUCCESS",
            roll: null,
            stateDelta: {
              canonicalState: migratedState.canonicalState,
              changes: {
                rollbackApplied: true,
                restoredFromRevisionId: target.sourceRevisionId,
                restoredFromSaveId: target.sourceSaveId,
                restoredFromCheckpointId: target.sourceCheckpointId,
                appliedSteps: migratedState.appliedSteps
              },
              validation: {
                ok: true,
                reason: null
              }
            },
            events,
            summaryFlags: [
              "system:rollback",
              target.targetKind === "CHECKPOINT"
                ? "rollback:checkpoint"
                : target.targetKind === "SAVE"
                  ? "rollback:save"
                  : "rollback:revision"
            ]
          },
          canonicalState: migratedState.canonicalState,
          events,
          canonicalStatePointer: saveSnapshot.snapshotPointer,
          commitKind: "ROLLBACK",
          restoredFromRevisionId: target.sourceRevisionId,
          autosaveEligible: false,
          summaryJobQueued: false,
          summaryKind: null
        });

        await tx.commitRollback({
          revision,
          saveSnapshot,
          eventLogs: events.map((event, index) => ({
            id: buildEventId(revisionId, index, event),
            revisionId,
            eventType: event.eventType,
            payload: event
          }))
        });

        return RollbackResponseSchema.parse({
          revision,
          saveSnapshot,
          restoredFromRevisionId: target.sourceRevisionId,
          restoredFromSaveId: target.sourceSaveId,
          restoredFromCheckpointId: target.sourceCheckpointId,
          currentCanonicalState: migratedState.canonicalState,
          playerMessage: buildRollbackMessage(target, migratedState.appliedSteps)
        });
      });
    }
  };
}
