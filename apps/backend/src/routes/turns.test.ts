import { describe, expect, it } from "vitest";

import {
  ErrorResponseSchema,
  TurnAuthoritativeResponseSchema
} from "@nexus-tales/contracts";

import { buildApp } from "../app.js";

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

describe("POST /v1/turns", () => {
  it("accepts deterministic turn intake with advisory parser output when enabled", async () => {
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
      expect(parsed.intake.sanitizedInputText).toBe("I inspect the lantern.");
      expect(parsed.intake.parserStatus).toBe("PARSED");
      expect(parsed.intake.advisoryActionPacket?.actionType).toBe("INSPECT");
      expect(parsed.intake.advisoryActionPacket?.targetEntityId).toBe("lantern");
      expect(parsed.revisionId).toBeNull();
      expect(parsed.simulationResult).toBeNull();
    } finally {
      await app.close();
    }
  });

  it("tracks clarification attempts across repeated ambiguous requests", async () => {
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
      expect(thirdParsed.intake.clarification?.ambiguityCount).toBe(3);
      expect(thirdParsed.playerMessage).toContain("I still need a clearer action");
    } finally {
      await app.close();
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

  it("returns the original response for valid idempotent replays", async () => {
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
        payload
      });

      expect(secondResponse.statusCode).toBe(200);
      expect(secondResponse.json()).toEqual(firstResponse.json());
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
      expect(parsed.routeCategory).toBe("SAFE_REJECT");
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
