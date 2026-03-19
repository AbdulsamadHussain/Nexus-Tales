import type {
  ActionPacket,
  CanonicalEvent,
  RevisionRecord,
  RouteCategory,
  SafetyDecision,
  SimulationResult,
  TurnAuthoritativeResponse,
  TurnIntake,
  TurnRequest
} from "@nexus-tales/contracts";
import {
  ImageJobSchema,
  NarrationJobSchema,
  PERSISTENCE_SCHEMA_VERSION,
  RevisionRecordSchema,
  RULESET_VERSION,
  SaveSnapshotSchema,
  SimulationResultSchema,
  SummaryJobSchema,
  TurnAuthoritativeResponseSchema
} from "@nexus-tales/contracts";

import { buildStableHash } from "./helpers.js";
import type {
  PersistedEventLog,
  PersistedCheckpointRecord,
  PersistedOutboxEvent,
  TurnRunState
} from "./repository.js";
import {
  createPrototypeInitialCanonicalState,
  type InitialCanonicalStateProvider,
  type CanonicalStateSnapshot,
  normalizeCanonicalState
} from "./state.js";

const SIMULATION_EPOCH_MS = Date.parse("2026-01-01T00:00:00.000Z");

type OutcomeImpact = {
  momentumDelta: number;
  dangerDelta: number;
};

type ResourceValidation = {
  ok: boolean;
  reason: string | null;
};

type OutcomeSummary = {
  nextState: CanonicalStateSnapshot;
  summaryFlags: string[];
  inventoryAdded: string[];
  sceneChanged: boolean;
  roll: SimulationResult["roll"];
  successTier: SimulationResult["successTier"];
  validation: ResourceValidation;
};

export interface AcceptedTurnSimulationArgs {
  request: TurnRequest;
  requestHash: string;
  decision: SafetyDecision;
  policy: TurnAuthoritativeResponse["policy"];
  routeCategory: RouteCategory;
  intake: TurnIntake;
  safetyMessage: string | null;
  authoritativeActionPacket: ActionPacket | null;
  runState: TurnRunState;
  initialCanonicalStateProvider?: InitialCanonicalStateProvider;
}

export interface AcceptedTurnCommitPlan {
  response: TurnAuthoritativeResponse;
  revision: RevisionRecord;
  saveSnapshot: import("@nexus-tales/contracts").SaveSnapshot;
  eventLogs: PersistedEventLog[];
  outboxEvents: PersistedOutboxEvent[];
  checkpointRecords: PersistedCheckpointRecord[];
}

function buildDeterministicId(prefix: string, value: unknown) {
  return `${prefix}_${buildStableHash(value).slice(0, 24)}`;
}

function buildTimestamp(turnNumber: number, eventIndex = 0) {
  return new Date(SIMULATION_EPOCH_MS + turnNumber * 60_000 + eventIndex * 1_000).toISOString();
}

function hashModulo(value: unknown, modulus: number) {
  return Number.parseInt(buildStableHash(value).slice(0, 8), 16) % modulus;
}

function clamp(value: number, minimum: number, maximum: number) {
  return Math.max(minimum, Math.min(maximum, value));
}

function normalizeTarget(targetEntityId: string | null) {
  return targetEntityId?.trim().toLowerCase() ?? null;
}

function slugifyToken(value: string) {
  const slug = value
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "");

  return slug || "unknown";
}

function buildAuthoritativeActionPacket(
  authoritativeActionPacket: ActionPacket | null,
  intake: TurnIntake,
  routeCategory: RouteCategory
): ActionPacket {
  if (authoritativeActionPacket) {
    return authoritativeActionPacket;
  }

  throw new Error(
    `Accepted turn is missing a validated action packet. routeCategory=${routeCategory} input="${intake.sanitizedInputText}"`
  );
}

function validateResources(
  actionPacket: ActionPacket,
  state: CanonicalStateSnapshot
): ResourceValidation {
  const normalizedInventory = new Set(state.inventory.map((item) => item.toLowerCase()));
  const normalizedTarget = normalizeTarget(actionPacket.targetEntityId);

  if (actionPacket.actionType === "USE") {
    if (!normalizedTarget) {
      return {
        ok: false,
        reason: "A usable target is required before the action can resolve."
      };
    }

    if (!normalizedInventory.has(normalizedTarget)) {
      return {
        ok: false,
        reason: `The required item "${normalizedTarget}" is not available in the current inventory.`
      };
    }
  }

  if (actionPacket.actionType === "LOCKPICK" && !normalizedInventory.has("lockpick set")) {
    return {
      ok: false,
      reason: "A lockpick set is required before the lock can be challenged."
    };
  }

  return {
    ok: true,
    reason: null
  };
}

function resolveRoll(
  actionPacket: ActionPacket,
  state: CanonicalStateSnapshot,
  seed: string,
  difficultyMode: TurnRequest["difficultyMode"]
): SimulationResult["roll"] {
  if (!actionPacket.requiresRoll) {
    return null;
  }

  const skillSeed = actionPacket.candidateSkills[0] ?? actionPacket.actionType;
  const skillModifier = hashModulo({ skillSeed, actionType: actionPacket.actionType }, 5) - 1;
  const momentumModifier = clamp(Math.trunc(state.momentum / 2), -1, 3);
  const modifier = skillModifier + momentumModifier;
  const difficultyOffset =
    difficultyMode === "STORY" ? -2 : difficultyMode === "HARD" ? 2 : 0;
  const target =
    11 +
    difficultyOffset +
    hashModulo({ target: actionPacket.targetEntityId, sceneId: state.sceneId }, 6);
  const die = hashModulo({ seed, kind: "die" }, 20) + 1;
  const total = die + modifier;

  return {
    die,
    modifier,
    total,
    target
  };
}

function resolveSuccessTier(
  actionPacket: ActionPacket,
  state: CanonicalStateSnapshot,
  validation: ResourceValidation,
  roll: SimulationResult["roll"],
  difficultyMode: TurnRequest["difficultyMode"]
): SimulationResult["successTier"] {
  if (!validation.ok) {
    return "FAILURE";
  }

  if (actionPacket.requiresRoll && roll) {
    if (roll.die === 1 && difficultyMode !== "STORY") {
      return "CRITICAL_FAILURE";
    }

    if (roll.die === 20 || roll.total >= roll.target + 5) {
      return "CRITICAL_SUCCESS";
    }

    if (roll.total >= roll.target) {
      return "FULL_SUCCESS";
    }

    if (roll.total >= roll.target - 2) {
      return "PARTIAL_SUCCESS";
    }

    return "FAILURE";
  }

  const normalizedTarget = normalizeTarget(actionPacket.targetEntityId);

  if (
    actionPacket.actionType === "TAKE" &&
    normalizedTarget &&
    state.inventory.some((item) => item.toLowerCase() === normalizedTarget)
  ) {
    return "PARTIAL_SUCCESS";
  }

  return "FULL_SUCCESS";
}

function getRelationshipTier(score: number) {
  if (score <= -51) {
    return "HOSTILE";
  }

  if (score <= -11) {
    return "DISTRUSTFUL";
  }

  if (score <= 10) {
    return "NEUTRAL";
  }

  if (score <= 40) {
    return "WARM";
  }

  if (score <= 75) {
    return "LOYAL";
  }

  return "DEVOTED";
}

function applyOutcomeImpact(
  successTier: SimulationResult["successTier"]
): OutcomeImpact {
  switch (successTier) {
    case "CRITICAL_SUCCESS":
      return {
        momentumDelta: 2,
        dangerDelta: -1
      };
    case "FULL_SUCCESS":
      return {
        momentumDelta: 1,
        dangerDelta: 0
      };
    case "PARTIAL_SUCCESS":
      return {
        momentumDelta: 0,
        dangerDelta: 1
      };
    case "CRITICAL_FAILURE":
      return {
        momentumDelta: -2,
        dangerDelta: 2
      };
    default:
      return {
        momentumDelta: -1,
        dangerDelta: 1
      };
  }
}

function buildOutcomeSummary(
  actionPacket: ActionPacket,
  state: CanonicalStateSnapshot,
  validation: ResourceValidation,
  roll: SimulationResult["roll"],
  successTier: SimulationResult["successTier"]
): OutcomeSummary {
  const normalizedTarget = normalizeTarget(actionPacket.targetEntityId);
  const inventory = new Set(state.inventory);
  const storyFlags = new Set(state.storyFlags);
  const impact = applyOutcomeImpact(successTier);
  const inventoryAdded: string[] = [];
  let nextSceneId = state.sceneId;

  if (
    actionPacket.actionType === "TAKE" &&
    normalizedTarget &&
    successTier !== "FAILURE" &&
    successTier !== "CRITICAL_FAILURE" &&
    !inventory.has(normalizedTarget)
  ) {
    inventory.add(normalizedTarget);
    inventoryAdded.push(normalizedTarget);
  }

  if (
    actionPacket.actionType === "MOVE" &&
    normalizedTarget &&
    successTier !== "FAILURE" &&
    successTier !== "CRITICAL_FAILURE"
  ) {
    nextSceneId = `scene_${slugifyToken(normalizedTarget)}`;
  }

  if (
    normalizedTarget &&
    successTier !== "FAILURE" &&
    successTier !== "CRITICAL_FAILURE" &&
    ["INSPECT", "READ", "USE", "TALK", "ASK"].includes(actionPacket.actionType)
  ) {
    storyFlags.add(`resolved:${actionPacket.actionType.toLowerCase()}:${slugifyToken(normalizedTarget)}`);
  }

  if (validation.reason) {
    storyFlags.add("validation:resource_missing");
  }

  const sceneChanged = nextSceneId !== state.sceneId;
  const nextState = normalizeCanonicalState({
    sceneId: sceneChanged ? nextSceneId : state.sceneId,
    turnCount: state.turnCount + 1,
    momentum: clamp(state.momentum + impact.momentumDelta, -3, 6),
    danger: clamp(state.danger + impact.dangerDelta, 0, 10),
    inventory: [...inventory],
    storyFlags: [...storyFlags],
    lastActionType: actionPacket.actionType
  });

  const summaryFlags = [
    `action:${actionPacket.actionType.toLowerCase()}`,
    `scene:${state.sceneId.toLowerCase()}`,
    `tier:${successTier.toLowerCase()}`,
    actionPacket.requiresRoll ? "resolution:roll" : "resolution:deterministic"
  ];

  if (sceneChanged) {
    summaryFlags.push("state:scene_changed");
  }

  if (inventoryAdded.length > 0) {
    summaryFlags.push("state:inventory_changed");
  }

  if (!validation.ok) {
    summaryFlags.push("validation:resource_missing");
  }

  if (roll) {
    summaryFlags.push(`roll:${roll.total}`);
  }

  return {
    nextState,
    summaryFlags: [...new Set(summaryFlags)].sort((left, right) => left.localeCompare(right)),
    inventoryAdded,
    sceneChanged,
    roll,
    successTier,
    validation
  };
}

function buildCanonicalEvents(args: {
  request: TurnRequest;
  actionPacket: ActionPacket;
  decision: SafetyDecision;
  policy: TurnAuthoritativeResponse["policy"];
  routeCategory: RouteCategory;
  successTier: SimulationResult["successTier"];
  roll: SimulationResult["roll"];
  state: CanonicalStateSnapshot;
  outcome: OutcomeSummary;
}) {
  const eventTimeBase = args.state.turnCount + 1;
  const events: CanonicalEvent[] = [];

  const pushEvent = (
    eventType: string,
    entityId: string | null,
    metadata: Record<string, unknown>
  ) => {
    events.push({
      eventType,
      entityId,
      occurredAt: buildTimestamp(eventTimeBase, events.length),
      metadata
    });
  };

  pushEvent("TURN_RESOLVED", args.actionPacket.targetEntityId, {
    clientTurnId: args.request.clientTurnId,
    actionType: args.actionPacket.actionType,
    decision: args.decision,
    routeCategory: args.routeCategory,
    successTier: args.successTier
  });

  if (args.roll) {
    pushEvent("ROLL_RESOLVED", args.actionPacket.targetEntityId, {
      die: args.roll.die,
      modifier: args.roll.modifier,
      total: args.roll.total,
      target: args.roll.target
    });
  }

  if (!args.outcome.validation.ok) {
    pushEvent("RESOURCE_CHECK_FAILED", args.actionPacket.targetEntityId, {
      reason: args.outcome.validation.reason
    });
  }

  if (args.outcome.inventoryAdded.length > 0) {
    pushEvent("UNIQUE_ITEM_ACQUIRED", args.actionPacket.targetEntityId, {
      inventoryAdded: args.outcome.inventoryAdded
    });
  }

  if (args.outcome.sceneChanged) {
    pushEvent("LOCATION_CHANGED", args.outcome.nextState.sceneId, {
      previousSceneId: args.state.sceneId,
      nextSceneId: args.outcome.nextState.sceneId
    });
  }

  if (args.decision !== "ALLOW") {
    pushEvent("POLICY_ADJUSTMENT_APPLIED", null, {
      decision: args.decision,
      policyFlags: args.policy.policyFlags,
      narrationConstraints: args.policy.narrationConstraints,
      transformationReason: args.policy.transformationReason
    });
  }

  return events;
}

function isAutosaveEligible(events: CanonicalEvent[]) {
  const autosaveEventTypes = new Set([
    "COMBAT_ENDED",
    "QUEST_UPDATED",
    "LOCATION_CHANGED",
    "RELATIONSHIP_TIER_CHANGED",
    "FACTION_THRESHOLD_CROSSED",
    "UNIQUE_ITEM_ACQUIRED",
    "DOWNTIME_COMPLETED",
    "CHAPTER_STARTED",
    "CHAPTER_ENDED"
  ]);

  return events.some((event) => autosaveEventTypes.has(event.eventType));
}

function determineSummaryTriggerKind(args: {
  currentTurnCount: number;
  nextTurnCount: number;
  events: CanonicalEvent[];
  recentRevisionContext: TurnRunState["recentRevisionContext"];
}) {
  const hardSummaryEventTypes = new Set([
    "COMBAT_ENDED",
    "QUEST_UPDATED",
    "CHAPTER_STARTED",
    "CHAPTER_ENDED",
    "LOCATION_CHANGED",
    "RELATIONSHIP_TIER_CHANGED",
    "FACTION_THRESHOLD_CROSSED",
    "DOWNTIME_COMPLETED",
    "UNIQUE_ITEM_ACQUIRED",
    "SEVERE_PERMANENT_STATE_CHANGE"
  ]);

  const hardTriggered = args.events.some((event) => hardSummaryEventTypes.has(event.eventType));

  if (hardTriggered) {
    return "HARD" as const;
  }

  const turnsSinceLastSummary = (() => {
    const latestSummary = args.recentRevisionContext.find((revision) => revision.summaryJobQueued);

    return latestSummary ? args.nextTurnCount - latestSummary.turnCount : args.nextTurnCount;
  })();

  const hardSummaryInLastEightTurns = args.recentRevisionContext.some(
    (revision) =>
      revision.summaryKind === "HARD" && args.nextTurnCount - revision.turnCount <= 8
  );
  const hardSummaryInSuppressionWindow = args.recentRevisionContext.some(
    (revision) =>
      revision.summaryKind === "HARD" && args.nextTurnCount - revision.turnCount <= 3
  );

  if (
    turnsSinceLastSummary >= 8 &&
    !hardSummaryInLastEightTurns &&
    !hardSummaryInSuppressionWindow
  ) {
    return "SOFT" as const;
  }

  return null;
}

function buildSaveSnapshot(args: {
  revisionId: string;
  saveSlotId: string;
  campaignId: string;
  canonicalState: CanonicalStateSnapshot;
  savedAt: string;
}) {
  const snapshotPointer = `snapshot:${buildStableHash(args.canonicalState).slice(0, 24)}`;

  return SaveSnapshotSchema.parse({
    saveId: buildDeterministicId("save", {
      revisionId: args.revisionId,
      saveSlotId: args.saveSlotId
    }),
    gameRevision: args.revisionId,
    saveSlotId: args.saveSlotId,
    campaignId: args.campaignId,
    schemaVersion: PERSISTENCE_SCHEMA_VERSION,
    snapshotPointer,
    savedAt: args.savedAt,
    canonicalState: args.canonicalState
  });
}

function buildWorkerArtifacts(args: {
  revisionId: string;
  campaignId: string;
  saveSlotId: string;
  actionPacket: ActionPacket;
  successTier: SimulationResult["successTier"];
  sceneId: string;
  summaryKind: "HARD" | "SOFT" | null;
  locationChanged: boolean;
}) {
  const workerJobs: TurnAuthoritativeResponse["workerJobs"] = [];
  const outboxEvents: PersistedOutboxEvent[] = [];
  const basePayload = {
    revisionId: args.revisionId,
    campaignId: args.campaignId,
    saveSlotId: args.saveSlotId,
    schemaVersion: PERSISTENCE_SCHEMA_VERSION
  };

  const enqueue = (
    jobType: "SUMMARY" | "NARRATION" | "IMAGE",
    payload: PersistedOutboxEvent["payload"],
    uniquenessKey: string
  ) => {
    workerJobs.push({
      jobType,
      jobId: buildDeterministicId("job", { jobType, revisionId: args.revisionId, uniquenessKey }),
      uniquenessKey,
      status: "QUEUED"
    });

    outboxEvents.push({
      id: buildDeterministicId("outbox", { jobType, revisionId: args.revisionId, uniquenessKey }),
      revisionId: args.revisionId,
      jobType,
      uniquenessKey,
      payload
    });
  };

  if (args.summaryKind) {
    const summaryUniquenessKey = `summary:${args.revisionId}`;
    enqueue(
      "SUMMARY",
      SummaryJobSchema.parse({
        ...basePayload,
        jobType: "SUMMARY",
        uniquenessKey: summaryUniquenessKey
      }),
      summaryUniquenessKey
    );
  }

  const narrationUniquenessKey = `narration:${args.revisionId}`;
  enqueue(
    "NARRATION",
    NarrationJobSchema.parse({
      ...basePayload,
      jobType: "NARRATION",
      uniquenessKey: narrationUniquenessKey
    }),
    narrationUniquenessKey
  );

  if (args.locationChanged) {
    const sceneAnchorId = slugifyToken(
      `${args.sceneId}:${args.actionPacket.actionType}:${args.successTier}`
    );
    const imageUniquenessKey = `image:${sceneAnchorId}:${args.revisionId}`;

    enqueue(
      "IMAGE",
      ImageJobSchema.parse({
        ...basePayload,
        jobType: "IMAGE",
        sceneAnchorId,
        uniquenessKey: imageUniquenessKey
      }),
      imageUniquenessKey
    );
  }

  return {
    workerJobs,
    outboxEvents
  };
}

function buildCheckpointRecords(
  revisionId: string,
  events: CanonicalEvent[]
): PersistedCheckpointRecord[] {
  const chapterStartEvent = events.find((event) => event.eventType === "CHAPTER_STARTED");

  if (!chapterStartEvent) {
    return [];
  }

  return [
    {
      checkpointId: buildDeterministicId("checkpoint", {
        revisionId,
        checkpointType: "CHAPTER_START"
      }),
      revisionId,
      checkpointType: "CHAPTER_START",
      createdAt: chapterStartEvent.occurredAt
    }
  ];
}

function buildPlayerMessage(
  safetyMessage: string | null,
  successTier: SimulationResult["successTier"],
  validation: ResourceValidation
) {
  const messageParts: string[] = [];

  if (safetyMessage) {
    messageParts.push(safetyMessage);
  }

  if (!validation.ok) {
    messageParts.push(validation.reason ?? "The action failed during resource validation.");
  } else {
    const outcomeMessage =
      successTier === "CRITICAL_SUCCESS"
        ? "Authoritative simulation resolved a critical success."
        : successTier === "FULL_SUCCESS"
          ? "Authoritative simulation resolved a full success."
          : successTier === "PARTIAL_SUCCESS"
            ? "Authoritative simulation resolved a partial success."
            : successTier === "CRITICAL_FAILURE"
              ? "Authoritative simulation resolved a critical failure."
              : "Authoritative simulation resolved a failure.";

    messageParts.push(outcomeMessage);
  }

  return messageParts.join(" ");
}

export function simulateAcceptedTurn(
  args: AcceptedTurnSimulationArgs
): AcceptedTurnCommitPlan {
  const currentState =
    args.runState.canonicalState ??
    (args.initialCanonicalStateProvider ?? createPrototypeInitialCanonicalState)({
      playerId: args.request.playerId,
      runId: args.request.runId,
      saveSlotId: args.request.saveSlotId,
      campaignId: args.runState.campaignId,
      sceneId: args.request.sceneId
    });
  const actionPacket = buildAuthoritativeActionPacket(
    args.authoritativeActionPacket,
    args.intake,
    args.routeCategory
  );
  const revisionId = buildDeterministicId("rev", {
    playerId: args.request.playerId,
    runId: args.request.runId,
    saveSlotId: args.request.saveSlotId,
    previousRevisionId: args.runState.activeRevisionId,
    requestHash: args.requestHash,
    actionPacket,
    routeCategory: args.routeCategory,
    rulesetVersion: RULESET_VERSION,
    schemaVersion: PERSISTENCE_SCHEMA_VERSION
  });
  const validation = validateResources(actionPacket, currentState);
  const roll = validation.ok
    ? resolveRoll(actionPacket, currentState, revisionId, args.request.difficultyMode)
    : null;
  const successTier = resolveSuccessTier(
    actionPacket,
    currentState,
    validation,
    roll,
    args.request.difficultyMode
  );
  const outcome = buildOutcomeSummary(
    actionPacket,
    currentState,
    validation,
    roll,
    successTier
  );
  const events = buildCanonicalEvents({
    request: args.request,
    actionPacket,
    decision: args.decision,
    policy: args.policy,
    routeCategory: args.routeCategory,
    successTier,
    roll: outcome.roll,
    state: currentState,
    outcome
  });
  const simulationResult = SimulationResultSchema.parse({
    rulesetVersion: RULESET_VERSION,
    successTier,
    roll: outcome.roll,
    stateDelta: {
      canonicalState: outcome.nextState,
      changes: {
        turnCountDelta: 1,
        momentumDelta: outcome.nextState.momentum - currentState.momentum,
        dangerDelta: outcome.nextState.danger - currentState.danger,
        inventoryAdded: outcome.inventoryAdded,
        sceneChanged: outcome.sceneChanged
      },
      validation: {
        ok: validation.ok,
        reason: validation.reason
      }
    },
    events,
    summaryFlags: outcome.summaryFlags
  });
  const summaryKind = determineSummaryTriggerKind({
    currentTurnCount: currentState.turnCount,
    nextTurnCount: outcome.nextState.turnCount,
    events,
    recentRevisionContext: args.runState.recentRevisionContext
  });
  const autosaveEligible = isAutosaveEligible(events);
  const savedAt = buildTimestamp(outcome.nextState.turnCount);
  const saveSnapshot = buildSaveSnapshot({
    revisionId,
    saveSlotId: args.request.saveSlotId,
    campaignId: args.runState.campaignId,
    canonicalState: outcome.nextState,
    savedAt
  });
  const revision = RevisionRecordSchema.parse({
    revisionId,
    previousRevisionId: args.runState.activeRevisionId,
    rulesetVersion: RULESET_VERSION,
    schemaVersion: PERSISTENCE_SCHEMA_VERSION,
    savedAt,
    playerId: args.request.playerId,
    runId: args.request.runId,
    saveSlotId: args.request.saveSlotId,
    actionPacket,
    simulationResult,
    canonicalState: outcome.nextState,
    events,
    canonicalStatePointer: saveSnapshot.snapshotPointer,
    commitKind: "PLAYER_TURN",
    restoredFromRevisionId: null,
    autosaveEligible,
    summaryJobQueued: summaryKind !== null,
    summaryKind
  });
  const workerArtifacts = buildWorkerArtifacts({
    revisionId,
    campaignId: args.runState.campaignId,
    saveSlotId: args.request.saveSlotId,
    actionPacket,
    successTier,
    sceneId: outcome.nextState.sceneId,
    summaryKind,
    locationChanged: outcome.sceneChanged
  });
  const response = TurnAuthoritativeResponseSchema.parse({
    status: "ACCEPTED",
    decision: args.decision,
    policy: args.policy,
    routeCategory: args.routeCategory,
    intake: args.intake,
    revisionId,
    simulationResult,
    events,
    saveSnapshot,
    autosaveStatus: autosaveEligible ? "ELIGIBLE" : "INELIGIBLE",
    workerJobs: workerArtifacts.workerJobs,
    playerMessage: buildPlayerMessage(args.safetyMessage, successTier, validation),
    rulesetVersion: RULESET_VERSION
  });

  return {
    response,
    revision,
    saveSnapshot,
    eventLogs: events.map((event, index) => ({
      id: buildDeterministicId("evt", { revisionId, index, event }),
      revisionId,
      eventType: event.eventType,
        payload: event
      })),
    outboxEvents: workerArtifacts.outboxEvents,
    checkpointRecords: buildCheckpointRecords(revisionId, events)
  };
}
