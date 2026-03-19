import { randomUUID } from "node:crypto";

import {
  RouteCategorySchema,
  TurnAuthoritativeResponseSchema
} from "@nexus-tales/contracts";
import { Pool, type PoolClient } from "pg";

import { buildRunSlotLockKey } from "../db/locks.js";
import { env } from "../config/env.js";
import type {
  ClarificationStateRecord,
  PersistedClarificationState,
  PersistedTurnRequest,
  StoredTurnRequest,
  TurnIntakeRepository,
  TurnIntakeTransaction
} from "./repository.js";

function mapTurnRequestRow(row: {
  player_id: string;
  run_id: string;
  save_slot_id: string;
  client_turn_id: string;
  request_hash: string;
  status: string;
  response_payload: unknown;
}): StoredTurnRequest {
  return {
    playerId: row.player_id,
    runId: row.run_id,
    saveSlotId: row.save_slot_id,
    clientTurnId: row.client_turn_id,
    requestHash: row.request_hash,
    status: row.status,
    responsePayload: TurnAuthoritativeResponseSchema.parse(row.response_payload)
  };
}

function mapClarificationRow(row: {
  scene_fingerprint: string;
  ambiguity_count: number;
  last_target_fingerprint: string | null;
  last_route_category: string | null;
  last_input_fingerprint: string | null;
  last_session_id: string;
}): ClarificationStateRecord {
  return {
    sceneFingerprint: row.scene_fingerprint,
    ambiguityCount: row.ambiguity_count,
    lastTargetFingerprint: row.last_target_fingerprint,
    lastRouteCategory: row.last_route_category
      ? RouteCategorySchema.parse(row.last_route_category)
      : null,
    lastInputFingerprint: row.last_input_fingerprint,
    lastSessionId: row.last_session_id
  };
}

function createTransaction(client: PoolClient): TurnIntakeTransaction {
  return {
    async findTurnRequest(playerId, runId, saveSlotId, clientTurnId) {
      const result = await client.query<{
        player_id: string;
        run_id: string;
        save_slot_id: string;
        client_turn_id: string;
        request_hash: string;
        status: string;
        response_payload: unknown;
      }>(
        `select player_id, run_id, save_slot_id, client_turn_id, request_hash, status, response_payload
         from turn_requests
         where player_id = $1
           and run_id = $2
           and save_slot_id = $3
           and client_turn_id = $4
         limit 1`,
        [playerId, runId, saveSlotId, clientTurnId]
      );

      return result.rowCount ? mapTurnRequestRow(result.rows[0]) : null;
    },
    async saveTurnRequest(record: PersistedTurnRequest) {
      await client.query(
        `insert into turn_requests (
          id,
          player_id,
          run_id,
          save_slot_id,
          client_turn_id,
          request_hash,
          status,
          response_payload
        )
        values ($1, $2, $3, $4, $5, $6, $7, $8::jsonb)`,
        [
          randomUUID(),
          record.playerId,
          record.runId,
          record.saveSlotId,
          record.clientTurnId,
          record.requestHash,
          record.status,
          JSON.stringify(record.responsePayload)
        ]
      );
    },
    async getClarificationState(runId, saveSlotId, sceneFingerprint) {
      const result = await client.query<{
        scene_fingerprint: string;
        ambiguity_count: number;
        last_target_fingerprint: string | null;
        last_route_category: string | null;
        last_input_fingerprint: string | null;
        last_session_id: string;
      }>(
        `select scene_fingerprint,
                ambiguity_count,
                last_target_fingerprint,
                last_route_category,
                last_input_fingerprint,
                last_session_id
         from clarification_state
         where run_id = $1
           and save_slot_id = $2
           and scene_fingerprint = $3
         limit 1`,
        [runId, saveSlotId, sceneFingerprint]
      );

      return result.rowCount ? mapClarificationRow(result.rows[0]) : null;
    },
    async upsertClarificationState(record: PersistedClarificationState) {
      const result = await client.query<{
        scene_fingerprint: string;
        ambiguity_count: number;
        last_target_fingerprint: string | null;
        last_route_category: string | null;
        last_input_fingerprint: string | null;
        last_session_id: string;
      }>(
        `insert into clarification_state (
          id,
          run_id,
          save_slot_id,
          scene_fingerprint,
          last_target_fingerprint,
          last_route_category,
          last_input_fingerprint,
          last_session_id,
          ambiguity_count
        )
        values ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        on conflict (run_id, save_slot_id, scene_fingerprint)
        do update
        set last_target_fingerprint = excluded.last_target_fingerprint,
            last_route_category = excluded.last_route_category,
            last_input_fingerprint = excluded.last_input_fingerprint,
            last_session_id = excluded.last_session_id,
            ambiguity_count = excluded.ambiguity_count,
            updated_at = now()
        returning scene_fingerprint,
                  ambiguity_count,
                  last_target_fingerprint,
                  last_route_category,
                  last_input_fingerprint,
                  last_session_id`,
        [
          randomUUID(),
          record.runId,
          record.saveSlotId,
          record.sceneFingerprint,
          record.lastTargetFingerprint,
          record.lastRouteCategory,
          record.lastInputFingerprint,
          record.lastSessionId,
          record.ambiguityCount
        ]
      );

      return mapClarificationRow(result.rows[0]);
    },
    async clearClarificationState(runId, saveSlotId, sceneFingerprint) {
      await client.query(
        `delete from clarification_state
         where run_id = $1
           and save_slot_id = $2
           and scene_fingerprint = $3`,
        [runId, saveSlotId, sceneFingerprint]
      );
    }
  };
}

export function createPgTurnIntakeRepository(
  connectionString = env.DATABASE_URL
): TurnIntakeRepository {
  const pool = new Pool({
    connectionString
  });

  return {
    async withTurnLock(runId, saveSlotId, execute) {
      const client = await pool.connect();

      try {
        await client.query("begin");
        await client.query("select pg_advisory_xact_lock($1::bigint)", [
          buildRunSlotLockKey(runId, saveSlotId).toString()
        ]);

        const result = await execute(createTransaction(client));

        await client.query("commit");
        return result;
      } catch (error) {
        await client.query("rollback").catch(() => undefined);
        throw error;
      } finally {
        client.release();
      }
    },
    async close() {
      await pool.end();
    }
  };
}
