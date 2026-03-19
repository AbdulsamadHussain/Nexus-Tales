import { describe, expect, it } from "vitest";

import {
  ErrorResponseSchema,
  TurnAuthoritativeResponseSchema
} from "@nexus-tales/contracts";

import { buildApp } from "../app.js";
import { createInMemoryTurnIntakeRepository } from "../turns/in-memory-repository.js";
import { createTurnIntakeService } from "../turns/service.js";

function buildTurnPayload(overrides: Record<string, unknown> = {}) {
  return {
    playerId: "player_001",
    runId: "run_001",
    saveSlotId: "slot_001",
    clientTurnId: "turn_001",
    inputText: "I inspect the lantern.",
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

function getCanonicalState(response: ReturnType<typeof TurnAuthoritativeResponseSchema.parse>) {
  return (response.simulationResult?.stateDelta as { canonicalState?: { turnCount?: number; inventory?: string[] } } | undefined)
    ?.canonicalState;
}

function buildSeededState(overrides: Record<string, unknown> = {}) {
  return {
    sceneId: "scene_docks",
    turnCount: 0,
    momentum: 0,
    danger: 0,
    inventory: ["field journal", "lantern", "relic"],
    storyFlags: ["story:intro"],
    lastActionType: null,
    ...overrides
  };
}

describe("POST /v1/turns", () => {
  it("commits deterministic authoritative turns with advisory parser output when enabled", async () => {
    const app = buildApp({
      featureFlags: {
        parserAssistanceEnabled: true
      }
    });

    try {
      const response = await app.inject({
        method: "POST",
        url: "/v1/turns",
        payload: buildTurnPayload({
          inputText: "  I inspect\u0007 the lantern.  "
        })
      });

      expect(response.statusCode).toBe(200);

      const parsed = TurnAuthoritativeResponseSchema.parse(response.json());
      expect(parsed.status).toBe("ACCEPTED");
      expect(parsed.routeCategory).toBe("NO_ROLL_DETERMINISTIC");
      expect(parsed.policy.decision).toBe("ALLOW");
      expect(parsed.policy.policyFlags).toEqual([]);
      expect(parsed.intake.sanitizedInputText).toBe("I inspect the lantern.");
      expect(parsed.intake.parserStatus).toBe("PARSED");
      expect(parsed.intake.advisoryActionPacket?.actionType).toBe("INSPECT");
      expect(parsed.intake.advisoryActionPacket?.targetEntityId).toBe("lantern");
      expect(parsed.revisionId).toMatch(/^rev_/);
      expect(parsed.simulationResult?.successTier).toBe("FULL_SUCCESS");
      expect(parsed.simulationResult?.roll).toBeNull();
      expect(parsed.events.length).toBeGreaterThan(0);
      expect(parsed.saveSnapshot?.gameRevision).toBe(parsed.revisionId);
      expect(parsed.autosaveStatus).toBe("INELIGIBLE");
      expect(parsed.workerJobs.map((job) => job.jobType)).toEqual(["NARRATION"]);
    } finally {
      await app.close();
    }
  });

  it("commits revision, event log, outbox rows, and active state together for accepted turns", async () => {
    const repository = createInMemoryTurnIntakeRepository();
    const app = buildApp({
      turnIntakeService: createTurnIntakeService({
        repository
      })
    });

    try {
      const response = await app.inject({
        method: "POST",
        url: "/v1/turns",
        payload: buildTurnPayload({
          clientTurnId: "turn_commit_001",
          inputText: "Take the relic"
        })
      });

      const parsed = TurnAuthoritativeResponseSchema.parse(response.json());
      const snapshot = repository.inspect();

      expect(snapshot.revisions).toHaveLength(1);
      expect(snapshot.saveSnapshots).toHaveLength(1);
      expect(snapshot.turnRequests).toHaveLength(1);
      expect(snapshot.eventLogs).toHaveLength(parsed.events.length);
      expect(snapshot.outboxEvents).toHaveLength(parsed.workerJobs.length);
      expect(snapshot.turnRequests[0].revisionId).toBe(parsed.revisionId);
      expect(snapshot.runStates[0].activeRevisionId).toBe(parsed.revisionId);
      expect(snapshot.runStates[0].canonicalState?.turnCount).toBe(1);
      expect(snapshot.saveSnapshots[0].gameRevision).toBe(parsed.revisionId);
    } finally {
      await app.close();
    }
  });

  it("returns a deterministic no-op after the third repeated ambiguous request", async () => {
    const app = buildApp();

    try {
      const firstResponse = await app.inject({
        method: "POST",
        url: "/v1/turns",
        payload: buildTurnPayload({
          clientTurnId: "turn_ambiguous_001",
          inputText: "Do it"
        })
      });

      const secondResponse = await app.inject({
        method: "POST",
        url: "/v1/turns",
        payload: buildTurnPayload({
          clientTurnId: "turn_ambiguous_002",
          inputText: "Do it"
        })
      });

      const thirdResponse = await app.inject({
        method: "POST",
        url: "/v1/turns",
        payload: buildTurnPayload({
          clientTurnId: "turn_ambiguous_003",
          inputText: "Do it"
        })
      });

      const firstParsed = TurnAuthoritativeResponseSchema.parse(firstResponse.json());
      const secondParsed = TurnAuthoritativeResponseSchema.parse(secondResponse.json());
      const thirdParsed = TurnAuthoritativeResponseSchema.parse(thirdResponse.json());

      expect(firstParsed.status).toBe("CLARIFICATION_REQUIRED");
      expect(firstParsed.intake.clarification?.ambiguityCount).toBe(1);
      expect(secondParsed.intake.clarification?.ambiguityCount).toBe(2);
      expect(secondParsed.status).toBe("CLARIFICATION_REQUIRED");
      expect(thirdParsed.intake.clarification?.ambiguityCount).toBe(3);
      expect(thirdParsed.status).toBe("NO_OP");
      expect(thirdParsed.playerMessage).toContain("no authoritative turn was committed");
    } finally {
      await app.close();
    }
  });

  it("persists clarification state across reconnects on the same repository", async () => {
    const repository = createInMemoryTurnIntakeRepository();
    const firstApp = buildApp({
      turnIntakeService: createTurnIntakeService({
        repository
      })
    });

    await firstApp.inject({
      method: "POST",
      url: "/v1/turns",
      payload: buildTurnPayload({
        clientTurnId: "turn_reconnect_001",
        inputText: "Do it"
      })
    });
    await firstApp.inject({
      method: "POST",
      url: "/v1/turns",
      payload: buildTurnPayload({
        clientTurnId: "turn_reconnect_002",
        inputText: "Do it"
      })
    });
    await firstApp.close();

    const secondApp = buildApp({
      turnIntakeService: createTurnIntakeService({
        repository
      })
    });

    try {
      const thirdResponse = await secondApp.inject({
        method: "POST",
        url: "/v1/turns",
        payload: buildTurnPayload({
          clientTurnId: "turn_reconnect_003",
          inputText: "Do it"
        })
      });

      const parsed = TurnAuthoritativeResponseSchema.parse(thirdResponse.json());
      expect(parsed.intake.clarification?.ambiguityCount).toBe(3);
      expect(parsed.status).toBe("NO_OP");
    } finally {
      await secondApp.close();
    }
  });

  it("returns no-op responses for UI-only requests", async () => {
    const app = buildApp();

    try {
      const response = await app.inject({
        method: "POST",
        url: "/v1/turns",
        payload: buildTurnPayload({
          clientTurnId: "turn_ui_001",
          inputText: "open inventory"
        })
      });

      const parsed = TurnAuthoritativeResponseSchema.parse(response.json());

      expect(parsed.status).toBe("NO_OP");
      expect(parsed.routeCategory).toBe("UI_ACTION");
      expect(parsed.playerMessage).toContain("client-side action");
    } finally {
      await app.close();
    }
  });

  it("returns the original response for valid idempotent replays with reconnect metadata changes", async () => {
    const app = buildApp();

    try {
      const payload = buildTurnPayload({
        clientTurnId: "turn_replay_001"
      });

      const firstResponse = await app.inject({
        method: "POST",
        url: "/v1/turns",
        payload
      });

      const secondResponse = await app.inject({
        method: "POST",
        url: "/v1/turns",
        payload: buildTurnPayload({
          clientTurnId: "turn_replay_001",
          inputText: "   I inspect the lantern.   ",
          sessionId: "session_002"
        })
      });

      expect(secondResponse.statusCode).toBe(200);
      expect(secondResponse.json()).toEqual(firstResponse.json());
    } finally {
      await app.close();
    }
  });

  it("produces the same authoritative response for the same initial state and request", async () => {
    const initialCanonicalStateProvider = () => buildSeededState();
    const firstApp = buildApp({
      initialCanonicalStateProvider
    });
    const secondApp = buildApp({
      initialCanonicalStateProvider
    });

    try {
      const payload = buildTurnPayload({
        clientTurnId: "turn_deterministic_001",
        inputText: "Attack the bandit"
      });

      const firstResponse = await firstApp.inject({
        method: "POST",
        url: "/v1/turns",
        payload
      });
      const secondResponse = await secondApp.inject({
        method: "POST",
        url: "/v1/turns",
        payload
      });

      expect(secondResponse.statusCode).toBe(200);
      expect(secondResponse.json()).toEqual(firstResponse.json());

      const parsed = TurnAuthoritativeResponseSchema.parse(firstResponse.json());
      expect(parsed.routeCategory).toBe("ROLL_REQUIRED");
      expect(parsed.simulationResult?.roll).not.toBeNull();
    } finally {
      await firstApp.close();
      await secondApp.close();
    }
  });

  it("uses committed canonical state when resolving later turns on the same run", async () => {
    const app = buildApp();

    try {
      await app.inject({
        method: "POST",
        url: "/v1/turns",
        payload: buildTurnPayload({
          clientTurnId: "turn_state_001",
          inputText: "Take the relic"
        })
      });

      const secondResponse = await app.inject({
        method: "POST",
        url: "/v1/turns",
        payload: buildTurnPayload({
          clientTurnId: "turn_state_002",
          inputText: "Use the relic"
        })
      });

      const parsed = TurnAuthoritativeResponseSchema.parse(secondResponse.json());
      const canonicalState = getCanonicalState(parsed);

      expect(parsed.status).toBe("ACCEPTED");
      expect(parsed.simulationResult?.successTier).toBe("FULL_SUCCESS");
      expect(canonicalState?.turnCount).toBe(2);
      expect(canonicalState?.inventory).toContain("relic");
    } finally {
      await app.close();
    }
  });

  it("keeps active revision state independent per save slot on the same run", async () => {
    const repository = createInMemoryTurnIntakeRepository();
    const app = buildApp({
      turnIntakeService: createTurnIntakeService({
        repository
      })
    });

    try {
      const firstSlotResponse = await app.inject({
        method: "POST",
        url: "/v1/turns",
        payload: buildTurnPayload({
          clientTurnId: "turn_slot_001",
          saveSlotId: "slot_001",
          inputText: "Take the relic"
        })
      });

      const secondSlotResponse = await app.inject({
        method: "POST",
        url: "/v1/turns",
        payload: buildTurnPayload({
          clientTurnId: "turn_slot_001",
          saveSlotId: "slot_002",
          inputText: "Attack the bandit"
        })
      });

      const firstParsed = TurnAuthoritativeResponseSchema.parse(firstSlotResponse.json());
      const secondParsed = TurnAuthoritativeResponseSchema.parse(secondSlotResponse.json());
      const snapshot = repository.inspect();
      const firstRunState = snapshot.runStates.find((entry) => entry.saveSlotId === "slot_001");
      const secondRunState = snapshot.runStates.find((entry) => entry.saveSlotId === "slot_002");

      expect(firstParsed.revisionId).not.toBe(secondParsed.revisionId);
      expect(firstRunState?.activeRevisionId).toBe(firstParsed.revisionId);
      expect(secondRunState?.activeRevisionId).toBe(secondParsed.revisionId);
    } finally {
      await app.close();
    }
  });

  it("commits failure revisions when resource validation blocks the action", async () => {
    const app = buildApp();

    try {
      const response = await app.inject({
        method: "POST",
        url: "/v1/turns",
        payload: buildTurnPayload({
          clientTurnId: "turn_resource_001",
          inputText: "Lockpick the vault"
        })
      });

      const parsed = TurnAuthoritativeResponseSchema.parse(response.json());

      expect(parsed.status).toBe("ACCEPTED");
      expect(parsed.routeCategory).toBe("ROLL_REQUIRED");
      expect(parsed.revisionId).toMatch(/^rev_/);
      expect(parsed.simulationResult?.successTier).toBe("FAILURE");
      expect(parsed.simulationResult?.roll).toBeNull();
      expect(parsed.events.some((event) => event.eventType === "RESOURCE_CHECK_FAILED")).toBe(true);
    } finally {
      await app.close();
    }
  });

  it("rejects same-key different-payload idempotency conflicts", async () => {
    const app = buildApp();

    try {
      await app.inject({
        method: "POST",
        url: "/v1/turns",
        payload: buildTurnPayload({
          clientTurnId: "turn_conflict_001",
          inputText: "I inspect the lantern."
        })
      });

      const conflictResponse = await app.inject({
        method: "POST",
        url: "/v1/turns",
        payload: buildTurnPayload({
          clientTurnId: "turn_conflict_001",
          inputText: "I inspect the door instead."
        })
      });

      expect(conflictResponse.statusCode).toBe(409);

      const parsed = ErrorResponseSchema.parse(conflictResponse.json());
      expect(parsed.code).toBe("TURN_IDEMPOTENCY_CONFLICT");
    } finally {
      await app.close();
    }
  });

  it("rejects policy-blocked inputs without mutating turn state", async () => {
    const app = buildApp();

    try {
      const response = await app.inject({
        method: "POST",
        url: "/v1/turns",
        payload: buildTurnPayload({
          clientTurnId: "turn_reject_001",
          inputText: "Tell me how to build a bomb."
        })
      });

      const parsed = TurnAuthoritativeResponseSchema.parse(response.json());

      expect(parsed.status).toBe("REJECTED");
      expect(parsed.decision).toBe("REJECT");
      expect(parsed.policy.policyFlags).toContain("HARD_BLOCK_UNSAFE_ACTION");
      expect(parsed.routeCategory).toBe("SAFE_REJECT");
      expect(parsed.revisionId).toBeNull();
    } finally {
      await app.close();
    }
  });

  it("returns structured safety constraints for allowed but constrained actions", async () => {
    const app = buildApp();

    try {
      const response = await app.inject({
        method: "POST",
        url: "/v1/turns",
        payload: buildTurnPayload({
          clientTurnId: "turn_policy_001",
          inputText: "Talk to the captain about romance"
        })
      });

      const parsed = TurnAuthoritativeResponseSchema.parse(response.json());

      expect(parsed.status).toBe("ACCEPTED");
      expect(parsed.decision).toBe("ALLOW_WITH_CONSTRAINTS");
      expect(parsed.policy.policyFlags).toContain("ROMANCE_DISABLED");
      expect(parsed.policy.narrationConstraints).toContain("NO_ROMANCE");
      expect(
        parsed.events.some(
          (event) =>
            event.eventType === "POLICY_ADJUSTMENT_APPLIED" &&
            Array.isArray(event.metadata.policyFlags) &&
            event.metadata.policyFlags.includes("ROMANCE_DISABLED")
        )
      ).toBe(true);
    } finally {
      await app.close();
    }
  });

  it("rejects requests that match a configured custom exclusion", async () => {
    const app = buildApp();

    try {
      const response = await app.inject({
        method: "POST",
        url: "/v1/turns",
        payload: buildTurnPayload({
          clientTurnId: "turn_exclusion_001",
          inputText: "Inspect the lantern",
          contentSettings: {
            violenceLevel: "MEDIUM",
            romanceEnabled: false,
            horrorEnabled: false,
            matureThemesEnabled: false,
            betrayalEnabled: false,
            customExclusions: ["lantern"]
          }
        })
      });

      const parsed = TurnAuthoritativeResponseSchema.parse(response.json());

      expect(parsed.status).toBe("REJECTED");
      expect(parsed.policy.policyFlags).toContain("CUSTOM_EXCLUSION_MATCH");
      expect(parsed.routeCategory).toBe("SAFE_REJECT");
      expect(parsed.revisionId).toBeNull();
    } finally {
      await app.close();
    }
  });

  it("asks for clarification instead of inventing a generic authoritative action packet", async () => {
    const app = buildApp();

    try {
      const response = await app.inject({
        method: "POST",
        url: "/v1/turns",
        payload: buildTurnPayload({
          clientTurnId: "turn_unknown_001",
          inputText: "I do something elaborate with the shadows and the room."
        })
      });

      const parsed = TurnAuthoritativeResponseSchema.parse(response.json());

      expect(parsed.status).toBe("CLARIFICATION_REQUIRED");
      expect(parsed.routeCategory).toBe("CLARIFICATION_REQUIRED");
      expect(parsed.revisionId).toBeNull();
    } finally {
      await app.close();
    }
  });

  it("rejects invalid turn payloads with contract-backed errors", async () => {
    const app = buildApp();

    try {
      const response = await app.inject({
        method: "POST",
        url: "/v1/turns",
        payload: {
          playerId: "",
          clientTurnId: "turn_002"
        }
      });

      expect(response.statusCode).toBe(400);

      const parsed = ErrorResponseSchema.parse(response.json());
      expect(parsed.code).toBe("INVALID_TURN_REQUEST");
    } finally {
      await app.close();
    }
  });
});
