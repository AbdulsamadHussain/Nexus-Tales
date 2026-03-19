import { describe, expect, it } from "vitest";

import {
  ErrorResponseSchema,
  ManualSaveResponseSchema,
  PERSISTENCE_SCHEMA_VERSION,
  RevisionHistoryResponseSchema,
  RevisionRecordSchema,
  RollbackResponseSchema,
  RULESET_VERSION,
  type RevisionRecord
} from "@nexus-tales/contracts";

import { buildApp } from "../app.js";
import { createInMemoryTurnIntakeRepository } from "../turns/in-memory-repository.js";
import type { StoredSaveArtifact, TurnRunState } from "../turns/repository.js";

function buildTurnPayload(overrides: Record<string, unknown> = {}) {
  return {
    playerId: "player_001",
    runId: "run_001",
    saveSlotId: "slot_001",
    clientTurnId: "turn_001",
    inputText: "Take the relic",
    sceneId: "scene_docks",
    sessionId: "session_001",
    contentSettings: {
      violenceLevel: "MEDIUM",
      romanceEnabled: false,
      horrorEnabled: false,
      matureThemesEnabled: false,
      betrayalEnabled: false
    },
    ...overrides
  };
}

function buildCanonicalState(overrides: Record<string, unknown> = {}) {
  return {
    sceneId: "scene_docks",
    turnCount: 1,
    momentum: 1,
    danger: 0,
    inventory: ["field journal", "lantern", "relic"],
    storyFlags: ["story:intro"],
    lastActionType: "TAKE",
    ...overrides
  };
}

function buildRevision(overrides: Partial<RevisionRecord> & { revisionId: string }): RevisionRecord {
  const canonicalState = buildCanonicalState(overrides.canonicalState ?? {});

  return RevisionRecordSchema.parse({
    revisionId: overrides.revisionId,
    previousRevisionId: overrides.previousRevisionId ?? null,
    rulesetVersion: RULESET_VERSION,
    schemaVersion: PERSISTENCE_SCHEMA_VERSION,
    savedAt: overrides.savedAt ?? "2026-03-19T18:42:14.000Z",
    playerId: overrides.playerId ?? "player_001",
    runId: overrides.runId ?? "run_001",
    saveSlotId: overrides.saveSlotId ?? "slot_001",
    actionPacket: overrides.actionPacket ?? {
      actionType: "TAKE",
      targetEntityId: "relic",
      method: null,
      stance: null,
      candidateSkills: [],
      requiresRoll: false
    },
    simulationResult: overrides.simulationResult ?? {
      rulesetVersion: RULESET_VERSION,
      successTier: "FULL_SUCCESS",
      roll: null,
      stateDelta: {
        canonicalState,
        changes: {},
        validation: {
          ok: true,
          reason: null
        }
      },
      events: overrides.events ?? [],
      summaryFlags: []
    },
    canonicalState,
    events: overrides.events ?? [],
    canonicalStatePointer:
      overrides.canonicalStatePointer ?? `snapshot:${overrides.revisionId.slice(0, 8)}`,
    commitKind: overrides.commitKind ?? "PLAYER_TURN",
    restoredFromRevisionId: overrides.restoredFromRevisionId ?? null,
    autosaveEligible: overrides.autosaveEligible ?? true,
    summaryJobQueued: overrides.summaryJobQueued ?? false,
    summaryKind: overrides.summaryKind ?? null
  });
}

function buildRevisionSnapshot(
  revision: RevisionRecord,
  overrides: Partial<StoredSaveArtifact> = {}
): StoredSaveArtifact {
  return {
    saveId: overrides.saveId ?? `save_${revision.revisionId}`,
    gameRevision: revision.revisionId,
    saveSlotId: revision.saveSlotId,
    campaignId: overrides.campaignId ?? "campaign_run_001",
    schemaVersion: overrides.schemaVersion ?? revision.schemaVersion,
    snapshotPointer: overrides.snapshotPointer ?? revision.canonicalStatePointer,
    savedAt: overrides.savedAt ?? revision.savedAt,
    canonicalState: overrides.canonicalState ?? revision.canonicalState,
    saveKind: overrides.saveKind ?? "REVISION",
    displayName: overrides.displayName ?? null
  };
}

function buildRunState(activeRevision: RevisionRecord): TurnRunState {
  return {
    playerId: activeRevision.playerId,
    runId: activeRevision.runId,
    saveSlotId: activeRevision.saveSlotId,
    campaignId: "campaign_run_001",
    activeRevisionId: activeRevision.revisionId,
    canonicalState: activeRevision.canonicalState,
    recentRevisionContext: [
      {
        revisionId: activeRevision.revisionId,
        turnCount: activeRevision.canonicalState.turnCount,
        summaryJobQueued: activeRevision.summaryJobQueued,
        summaryKind: activeRevision.summaryKind,
        eventTypes: activeRevision.events.map((event) => event.eventType)
      }
    ]
  };
}

describe("save management routes", () => {
  it("creates manual saves and exposes revision history with autosaves", async () => {
    const repository = createInMemoryTurnIntakeRepository();
    const app = buildApp({
      repository,
      saveManagementConfig: {
        autosaveRingSize: 2,
        manualSaveLimit: 2
      }
    });

    try {
      const turnResponse = await app.inject({
        method: "POST",
        url: "/v1/turns",
        payload: buildTurnPayload()
      });

      const manualSaveResponse = await app.inject({
        method: "POST",
        url: "/v1/saves/manual",
        payload: {
          playerId: "player_001",
          runId: "run_001",
          saveSlotId: "slot_001",
          displayName: "Before the vault"
        }
      });
      const historyResponse = await app.inject({
        method: "GET",
        url: "/v1/runs/run_001/save-slots/slot_001/history?playerId=player_001"
      });

      expect(turnResponse.statusCode).toBe(200);
      expect(manualSaveResponse.statusCode).toBe(200);
      expect(historyResponse.statusCode).toBe(200);

      const manualSave = ManualSaveResponseSchema.parse(manualSaveResponse.json());
      const history = RevisionHistoryResponseSchema.parse(historyResponse.json());

      expect(manualSave.save.displayName).toBe("Before the vault");
      expect(history.manualSaves).toHaveLength(1);
      expect(history.autosaves).toHaveLength(1);
      expect(history.revisions[0].commitKind).toBe("PLAYER_TURN");
      expect(history.activeRevisionId).toBe(history.revisions[0].revisionId);
    } finally {
      await app.close();
    }
  });

  it("rolls back from a manual save by creating a new rollback revision", async () => {
    const repository = createInMemoryTurnIntakeRepository();
    const app = buildApp({
      repository,
      saveManagementConfig: {
        autosaveRingSize: 2,
        manualSaveLimit: 3
      }
    });

    try {
      await app.inject({
        method: "POST",
        url: "/v1/turns",
        payload: buildTurnPayload({
          clientTurnId: "turn_save_001",
          inputText: "Take the relic"
        })
      });

      const manualSaveResponse = await app.inject({
        method: "POST",
        url: "/v1/saves/manual",
        payload: {
          playerId: "player_001",
          runId: "run_001",
          saveSlotId: "slot_001",
          displayName: "Relic secured"
        }
      });

      await app.inject({
        method: "POST",
        url: "/v1/turns",
        payload: buildTurnPayload({
          clientTurnId: "turn_save_002",
          inputText: "Move to the tower"
        })
      });

      const manualSave = ManualSaveResponseSchema.parse(manualSaveResponse.json());
      const rollbackResponse = await app.inject({
        method: "POST",
        url: "/v1/saves/rollback",
        payload: {
          playerId: "player_001",
          runId: "run_001",
          saveSlotId: "slot_001",
          saveId: manualSave.save.saveId
        }
      });

      expect(rollbackResponse.statusCode).toBe(200);

      const parsed = RollbackResponseSchema.parse(rollbackResponse.json());
      const snapshot = repository.inspect();

      expect(parsed.revision.commitKind).toBe("ROLLBACK");
      expect(parsed.restoredFromSaveId).toBe(manualSave.save.saveId);
      expect(parsed.currentCanonicalState.turnCount).toBe(1);
      expect(parsed.currentCanonicalState.sceneId).toBe("scene_docks");
      expect(snapshot.runStates[0].activeRevisionId).toBe(parsed.revision.revisionId);
    } finally {
      await app.close();
    }
  });

  it("restores a protected checkpoint as a rollback target", async () => {
    const checkpointRevision = buildRevision({
      revisionId: "rev_checkpoint_001",
      canonicalState: buildCanonicalState({
        sceneId: "scene_chapter_gate",
        turnCount: 3
      }),
      events: [
        {
          eventType: "CHAPTER_STARTED",
          entityId: null,
          occurredAt: "2026-03-19T18:40:00.000Z",
          metadata: {}
        }
      ]
    });
    const currentRevision = buildRevision({
      revisionId: "rev_current_001",
      previousRevisionId: checkpointRevision.revisionId,
      canonicalState: buildCanonicalState({
        sceneId: "scene_later_chapter",
        turnCount: 5
      })
    });
    const repository = createInMemoryTurnIntakeRepository({
      runStates: [buildRunState(currentRevision)],
      revisions: [currentRevision, checkpointRevision],
      saveSnapshots: [
        buildRevisionSnapshot(checkpointRevision),
        buildRevisionSnapshot(currentRevision)
      ],
      checkpoints: [
        {
          checkpointId: "checkpoint_001",
          revisionId: checkpointRevision.revisionId,
          checkpointType: "CHAPTER_START",
          createdAt: "2026-03-19T18:40:00.000Z"
        }
      ]
    });
    const app = buildApp({
      repository
    });

    try {
      const rollbackResponse = await app.inject({
        method: "POST",
        url: "/v1/saves/rollback",
        payload: {
          playerId: "player_001",
          runId: "run_001",
          saveSlotId: "slot_001",
          checkpointId: "checkpoint_001"
        }
      });

      expect(rollbackResponse.statusCode).toBe(200);

      const parsed = RollbackResponseSchema.parse(rollbackResponse.json());
      expect(parsed.restoredFromCheckpointId).toBe("checkpoint_001");
      expect(parsed.currentCanonicalState.sceneId).toBe("scene_chapter_gate");
      expect(parsed.currentCanonicalState.turnCount).toBe(3);
    } finally {
      await app.close();
    }
  });

  it("records a migration failure without changing the active revision", async () => {
    const activeRevision = buildRevision({
      revisionId: "rev_active_001",
      canonicalState: buildCanonicalState({
        sceneId: "scene_active",
        turnCount: 6
      })
    });
    const legacyBrokenSave: StoredSaveArtifact = {
      saveId: "save_legacy_broken",
      gameRevision: activeRevision.revisionId,
      saveSlotId: "slot_001",
      campaignId: "campaign_run_001",
      schemaVersion: 0,
      snapshotPointer: "snapshot:legacybroken",
      savedAt: "2026-03-18T10:00:00.000Z",
      canonicalState: {
        threat: 4,
        inventory: ["field journal"]
      },
      saveKind: "MANUAL",
      displayName: "Broken legacy save"
    };
    const repository = createInMemoryTurnIntakeRepository({
      runStates: [buildRunState(activeRevision)],
      revisions: [activeRevision],
      saveSnapshots: [buildRevisionSnapshot(activeRevision), legacyBrokenSave]
    });
    const app = buildApp({
      repository
    });

    try {
      const rollbackResponse = await app.inject({
        method: "POST",
        url: "/v1/saves/rollback",
        payload: {
          playerId: "player_001",
          runId: "run_001",
          saveSlotId: "slot_001",
          saveId: legacyBrokenSave.saveId
        }
      });

      expect(rollbackResponse.statusCode).toBe(422);

      const parsed = ErrorResponseSchema.parse(rollbackResponse.json());
      const snapshot = repository.inspect();

      expect(parsed.code).toBe("SAVE_MIGRATION_FAILED");
      expect(parsed.details).toHaveProperty("debugBundle");
      expect(snapshot.runStates[0].activeRevisionId).toBe(activeRevision.revisionId);
      expect(snapshot.migrationRecords).toHaveLength(1);
      expect(snapshot.migrationRecords[0].status).toBe("FAILED");
    } finally {
      await app.close();
    }
  });

  it("migrates a legacy save snapshot before rollback commit", async () => {
    const activeRevision = buildRevision({
      revisionId: "rev_active_legacy_001",
      canonicalState: buildCanonicalState({
        sceneId: "scene_active",
        turnCount: 6,
        danger: 1
      })
    });
    const legacySave: StoredSaveArtifact = {
      saveId: "save_legacy_ok",
      gameRevision: "rev_legacy_source",
      saveSlotId: "slot_001",
      campaignId: "campaign_run_001",
      schemaVersion: 0,
      snapshotPointer: "snapshot:legacyok",
      savedAt: "2026-03-18T11:00:00.000Z",
      canonicalState: {
        sceneId: "scene_legacy_archive",
        turnCount: 2,
        momentum: 3,
        threat: 4,
        inventory: ["field journal", "old key"],
        storyFlags: ["story:intro"],
        lastActionType: "READ"
      },
      saveKind: "MANUAL",
      displayName: "Legacy archive save"
    };
    const repository = createInMemoryTurnIntakeRepository({
      runStates: [buildRunState(activeRevision)],
      revisions: [activeRevision],
      saveSnapshots: [buildRevisionSnapshot(activeRevision), legacySave]
    });
    const app = buildApp({
      repository
    });

    try {
      const rollbackResponse = await app.inject({
        method: "POST",
        url: "/v1/saves/rollback",
        payload: {
          playerId: "player_001",
          runId: "run_001",
          saveSlotId: "slot_001",
          saveId: legacySave.saveId
        }
      });

      expect(rollbackResponse.statusCode).toBe(200);

      const parsed = RollbackResponseSchema.parse(rollbackResponse.json());
      const snapshot = repository.inspect();

      expect(parsed.currentCanonicalState.sceneId).toBe("scene_legacy_archive");
      expect(parsed.currentCanonicalState.danger).toBe(4);
      expect(parsed.currentCanonicalState.turnCount).toBe(2);
      expect(snapshot.migrationRecords).toHaveLength(1);
      expect(snapshot.migrationRecords[0].status).toBe("SUCCEEDED");
    } finally {
      await app.close();
    }
  });
});
