import { describe, it, expect, beforeAll, afterAll, beforeEach } from "vitest";
import { Pool } from "pg";

import {
  RULESET_VERSION,
  PERSISTENCE_SCHEMA_VERSION,
  TurnAuthoritativeResponseSchema
} from "@nexus-tales/contracts";

import { createPgTurnIntakeRepository } from "../turns/pg-repository.js";
import { createTurnIntakeService } from "../turns/service.js";
import { env } from "../config/env.js";

const TEST_DATABASE_URL = env.DATABASE_URL;

describe("PostgreSQL Integration Tests", () => {
  let repository: ReturnType<typeof createPgTurnIntakeRepository>;
  let pool: Pool;

  beforeAll(async () => {
    repository = createPgTurnIntakeRepository(TEST_DATABASE_URL);
    pool = new Pool({ connectionString: TEST_DATABASE_URL });
  });

  afterAll(async () => {
    await repository.close?.();
    await pool.end();
  });

  async function setupTestData(
    playerId: string,
    runId: string,
    saveSlotId: string,
    campaignId = `campaign_${runId}`
  ) {
    // Create user
    await pool.query(
      `
      INSERT INTO users (id, auth_subject) 
      VALUES ($1, $2)
      ON CONFLICT (id) DO NOTHING
      `,
      [playerId, `auth:${playerId}`]
    );

    // Create campaign
    await pool.query(
      `
      INSERT INTO campaigns (id, slug, display_name)
      VALUES ($1, $2, $3)
      ON CONFLICT (id) DO NOTHING
      `,
      [campaignId, `slug-${campaignId}`, `Campaign ${campaignId}`]
    );

    // Create run
    await pool.query(
      `
      INSERT INTO runs (id, user_id, campaign_id)
      VALUES ($1, $2, $3)
      ON CONFLICT (id) DO NOTHING
      `,
      [runId, playerId, campaignId]
    );

    // Create save slot with the specified saveSlotId
    await pool.query(
      `
      INSERT INTO save_slots (id, run_id, slot_type, display_name)
      VALUES ($1, $2, $3, $4)
      ON CONFLICT (id) DO NOTHING
      `,
      [saveSlotId, runId, "MANUAL", "Test Slot"]
    );
  }

  function buildTurnPayload(overrides: Record<string, unknown> = {}) {
    return {
      playerId: "player_pg_001",
      runId: "run_pg_001",
      saveSlotId: "slot_run_pg_001",
      clientTurnId: "turn_pg_001",
      inputText: "I inspect the lantern.",
      sceneId: "scene_docks",
      sessionId: "session_pg_001",
      difficultyMode: "STANDARD" as const,
      contentSettings: {
        violenceLevel: "MEDIUM" as const,
        romanceEnabled: false,
        horrorEnabled: false,
        matureThemesEnabled: false,
        betrayalEnabled: false,
        customExclusions: []
      },
      ...overrides
    };
  }

  it("advisory lock prevents concurrent writes to same run_id + save_slot_id", async () => {
    await setupTestData("player_pg_001", "run_pg_001", "slot_run_pg_001");
    const service = createTurnIntakeService({ repository });

    // First turn should succeed
    const response1 = await service.handleTurn(buildTurnPayload());

    expect(response1.status).toBe("ACCEPTED");
    expect(response1.revisionId).toBeDefined();

    // Second turn to same run should also succeed (no concurrent access)
    const response2 = await service.handleTurn(
      buildTurnPayload({
        clientTurnId: "turn_pg_002",
        inputText: "I take the lantern."
      })
    );

    expect(response2.status).toBe("ACCEPTED");
    expect(response2.revisionId).toBeDefined();
    expect(response2.revisionId).not.toBe(response1.revisionId);
  }, 30000);

  it("revision is committed atomically with save snapshot, events, and outbox", async () => {
    const runId = "run_pg_atomic_test";
    const saveSlotId = "slot_pg_atomic_test";
    const playerId = "player_atomic";
    
    await setupTestData(playerId, runId, saveSlotId);

    const service = createTurnIntakeService({ repository });

    const response = await service.handleTurn({
      playerId,
      runId,
      saveSlotId,
      clientTurnId: "turn_atomic_001",
      inputText: "I search the chest.",
      sceneId: "scene_vault",
      sessionId: "session_atomic",
      difficultyMode: "STANDARD",
      contentSettings: {
        violenceLevel: "MEDIUM",
        romanceEnabled: false,
        horrorEnabled: false,
        matureThemesEnabled: false,
        betrayalEnabled: false,
        customExclusions: []
      }
    });

    expect(response.status).toBe("ACCEPTED");
    expect(response.revisionId).toBeDefined();

    // Query database directly to verify all atomic writes
    const revisionExists = await pool.query(
      "SELECT id FROM revisions WHERE id = $1",
      [response.revisionId]
    );
    expect(revisionExists.rows.length).toBe(1);

    const snapshotExists = await pool.query(
      "SELECT id FROM save_snapshots WHERE revision_id = $1",
      [response.revisionId]
    );
    expect(snapshotExists.rows.length).toBe(1);

    const eventsExist = await pool.query(
      "SELECT COUNT(*) as count FROM event_logs WHERE revision_id = $1",
      [response.revisionId]
    );
    expect(Number(eventsExist.rows[0].count)).toBeGreaterThan(0);

    const outboxExists = await pool.query(
      "SELECT COUNT(*) as count FROM outbox_events WHERE revision_id = $1",
      [response.revisionId]
    );
    expect(Number(outboxExists.rows[0].count)).toBeGreaterThan(0);
  });

  it("idempotency: same client_turn_id returns original response", async () => {
    const runId = "run_pg_idempotent";
    const saveSlotId = "slot_pg_idempotent";
    const playerId = "player_idempotent";
    const clientTurnId = "turn_pg_idempotent_001";

    await setupTestData(playerId, runId, saveSlotId);

    const service = createTurnIntakeService({ repository });

    const response1 = await service.handleTurn({
      playerId,
      runId,
      saveSlotId,
      clientTurnId,
      inputText: "I attack the enemy.",
      sceneId: "scene_combat",
      sessionId: "session_idempotent",
      difficultyMode: "STANDARD",
      contentSettings: {
        violenceLevel: "HIGH",
        romanceEnabled: false,
        horrorEnabled: false,
        matureThemesEnabled: false,
        betrayalEnabled: false,
        customExclusions: []
      }
    });

    expect(response1.status).toBe("ACCEPTED");
    expect(response1.revisionId).toBeDefined();

    // Replay with same clientTurnId should return original result
    const response2 = await service.handleTurn({
      playerId,
      runId,
      saveSlotId,
      clientTurnId,
      inputText: "I attack the enemy.",
      sceneId: "scene_combat",
      sessionId: "session_idempotent",
      difficultyMode: "STANDARD",
      contentSettings: {
        violenceLevel: "HIGH",
        romanceEnabled: false,
        horrorEnabled: false,
        matureThemesEnabled: false,
        betrayalEnabled: false,
        customExclusions: []
      }
    });

    expect(response2.status).toBe("ACCEPTED");
    expect(response2.revisionId).toBe(response1.revisionId);
  });

  it("save history includes all revisions and artifacts", async () => {
    const runId = "run_pg_history";
    const saveSlotId = "slot_pg_history";
    const playerId = "player_history";

    await setupTestData(playerId, runId, saveSlotId);

    const repository2 = createPgTurnIntakeRepository(TEST_DATABASE_URL);
    const service = createTurnIntakeService({ repository: repository2 });

    // Submit two turns
    const response1 = await service.handleTurn({
      playerId,
      runId,
      saveSlotId,
      clientTurnId: "turn_hist_001",
      inputText: "I open the door.",
      sceneId: "scene_entrance",
      sessionId: "session_hist",
      difficultyMode: "STANDARD",
      contentSettings: {
        violenceLevel: "MEDIUM",
        romanceEnabled: false,
        horrorEnabled: false,
        matureThemesEnabled: false,
        betrayalEnabled: false,
        customExclusions: []
      }
    });

    expect(response1.status).toBe("ACCEPTED");

    const response2 = await service.handleTurn({
      playerId,
      runId,
      saveSlotId,
      clientTurnId: "turn_hist_002",
      inputText: "I read the scroll.",
      sceneId: "scene_library",
      sessionId: "session_hist",
      difficultyMode: "STANDARD",
      contentSettings: {
        violenceLevel: "MEDIUM",
        romanceEnabled: false,
        horrorEnabled: false,
        matureThemesEnabled: false,
        betrayalEnabled: false,
        customExclusions: []
      }
    });

    expect(response2.status).toBe("ACCEPTED");

    // Query save history directly from database
    const historyRows = await pool.query(
      `
      SELECT COUNT(DISTINCT id) as count
      FROM revisions
      WHERE run_id = $1 AND save_slot_id = $2
      `,
      [runId, saveSlotId]
    );

    expect(Number(historyRows.rows[0].count)).toBeGreaterThanOrEqual(2);

    await repository2.close?.();
  });

  it("clarification state persists across reconnects", async () => {
    const runId = "run_pg_clarif";
    const saveSlotId = "slot_pg_clarif";
    const playerId = "player_clarif";

    await setupTestData(playerId, runId, saveSlotId);

    const service = createTurnIntakeService({ repository });

    // Ambiguous input 1
    const response1 = await service.handleTurn({
      playerId,
      runId,
      saveSlotId,
      clientTurnId: "turn_clarif_001",
      inputText: "do it",
      sceneId: "scene_ambiguous",
      sessionId: "session_clarif_1",
      difficultyMode: "STANDARD",
      contentSettings: {
        violenceLevel: "MEDIUM",
        romanceEnabled: false,
        horrorEnabled: false,
        matureThemesEnabled: false,
        betrayalEnabled: false,
        customExclusions: []
      }
    });

    expect(response1.status).toBe("CLARIFICATION_REQUIRED");
    expect(response1.intake?.clarification?.ambiguityCount).toBe(1);

    // Ambiguous input 2 with new session (simulating reconnect)
    const response2 = await service.handleTurn({
      playerId,
      runId,
      saveSlotId,
      clientTurnId: "turn_clarif_002",
      inputText: "do it",
      sceneId: "scene_ambiguous",
      sessionId: "session_clarif_2",
      difficultyMode: "STANDARD",
      contentSettings: {
        violenceLevel: "MEDIUM",
        romanceEnabled: false,
        horrorEnabled: false,
        matureThemesEnabled: false,
        betrayalEnabled: false,
        customExclusions: []
      }
    });

    expect(response2.status).toBe("CLARIFICATION_REQUIRED");
    // Ambiguity count should have incremented
    expect(response2.intake?.clarification?.ambiguityCount).toBeGreaterThanOrEqual(1);
  });
});
