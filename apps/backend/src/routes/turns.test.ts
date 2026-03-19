import { afterAll, describe, expect, it } from "vitest";

import { TurnAuthoritativeResponseSchema } from "@nexus-tales/contracts";

import { buildApp } from "../app.js";

const app = buildApp();

afterAll(async () => {
  await app.close();
});

describe("POST /v1/turns", () => {
  it("returns a contract-valid mocked authoritative response", async () => {
    const response = await app.inject({
      method: "POST",
      url: "/v1/turns",
      payload: {
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
        }
      }
    });

    expect(response.statusCode).toBe(200);

    const parsed = TurnAuthoritativeResponseSchema.safeParse(response.json());
    expect(parsed.success).toBe(true);
    expect(parsed.success && parsed.data.status).toBe("ACCEPTED");
  });

  it("rejects invalid turn payloads", async () => {
    const response = await app.inject({
      method: "POST",
      url: "/v1/turns",
      payload: {
        playerId: "",
        clientTurnId: "turn_002"
      }
    });

    expect(response.statusCode).toBe(400);
  });
});
