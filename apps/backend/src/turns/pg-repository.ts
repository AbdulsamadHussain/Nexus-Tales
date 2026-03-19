import { randomUUID } from "node:crypto";

import {
  CheckpointRecordSchema,
  RevisionRecordSchema,
  RouteCategorySchema,
  SaveArtifactKindSchema,
  TurnAuthoritativeResponseSchema
} from "@nexus-tales/contracts";
import { Pool, type PoolClient } from "pg";

import { buildRunSlotLockKey } from "../db/locks.js";
import { env } from "../config/env.js";
import type {
  PersistedAcceptedTurnCommit,
  SaveHistorySnapshot,
  ClarificationStateRecord,
  PersistedClarificationState,
  PersistedCheckpointRecord,
  PersistedMigrationRecord,
  PersistedTurnRequest,
  PersistedRollbackCommit,
  StoredSaveArtifact,
  StoredTurnRequest,
  TurnRunState,
  TurnIntakeRepository,
  TurnIntakeTransaction
} from "./repository.js";
import { extractCanonicalStateSnapshot } from "./state.js";

function buildBulkInsertValues(
  rows: unknown[][],
  jsonbColumnIndexes: Set<number> = new Set()
) {
  const values: unknown[] = [];
  const placeholders = rows
    .map((row) => {
      const rowPlaceholders = row.map((value, columnIndex) => {
        values.push(value);
        const placeholder = `$${values.length}`;

        // columnIndex is the column position within the current row shape.
        // It intentionally resets for each row; placeholder numbering comes
        // from the flat values array and continues across all rows.
        return jsonbColumnIndexes.has(columnIndex) ? `${placeholder}::jsonb` : placeholder;
      });

      return `(${rowPlaceholders.join(", ")})`;
    })
    .join(", ");

  return {
    placeholders,
    values
  };
}

function mapTurnRequestRow(row: {
  player_id: string;
  run_id: string;
  save_slot_id: string;
  client_turn_id: string;
  request_hash: string;
  revision_id: string | null;
  status: string;
  response_payload: unknown;
}): StoredTurnRequest {
  return {
    playerId: row.player_id,
    runId: row.run_id,
    saveSlotId: row.save_slot_id,
    clientTurnId: row.client_turn_id,
    requestHash: row.request_hash,
    revisionId: row.revision_id,
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

function mapSaveArtifactRow(row: {
  id: string;
  revision_id: string;
  save_slot_id: string;
  campaign_id: string;
  schema_version: number;
  snapshot_pointer: string;
  canonical_state: unknown;
  saved_at: Date | string;
  save_kind: string;
  display_name: string | null;
}): StoredSaveArtifact {
  return {
    saveId: row.id,
    gameRevision: row.revision_id,
    saveSlotId: row.save_slot_id,
    campaignId: row.campaign_id,
    schemaVersion: row.schema_version,
    snapshotPointer: row.snapshot_pointer,
    canonicalState: row.canonical_state,
    savedAt:
      row.saved_at instanceof Date ? row.saved_at.toISOString() : new Date(row.saved_at).toISOString(),
    saveKind: SaveArtifactKindSchema.parse(row.save_kind),
    displayName: row.display_name
  };
}

function mapCheckpointRow(row: {
  checkpoint_id: string;
  revision_id: string;
  checkpoint_type: string;
  created_at: Date | string;
}): PersistedCheckpointRecord {
  return CheckpointRecordSchema.parse({
    checkpointId: row.checkpoint_id,
    revisionId: row.revision_id,
    checkpointType: row.checkpoint_type,
    createdAt:
      row.created_at instanceof Date
        ? row.created_at.toISOString()
        : new Date(row.created_at).toISOString()
  });
}

function mapRevisionRow(row: {
  id: string;
  player_id: string;
  run_id: string;
  save_slot_id: string;
  previous_revision_id: string | null;
  ruleset_version: string;
  schema_version: number;
  created_at: Date | string;
  action_packet: unknown;
  simulation_result: unknown;
  canonical_state: unknown;
  canonical_state_pointer: string;
  autosave_eligible: boolean;
  summary_job_queued: boolean;
  summary_kind: "HARD" | "SOFT" | null;
  commit_kind: string;
  restored_from_revision_id: string | null;
  events: unknown;
}) {
  return RevisionRecordSchema.parse({
    revisionId: row.id,
    previousRevisionId: row.previous_revision_id,
    rulesetVersion: row.ruleset_version,
    schemaVersion: row.schema_version,
    savedAt:
      row.created_at instanceof Date
        ? row.created_at.toISOString()
        : new Date(row.created_at).toISOString(),
    playerId: row.player_id,
    runId: row.run_id,
    saveSlotId: row.save_slot_id,
    actionPacket: row.action_packet,
    simulationResult: row.simulation_result,
    canonicalState: row.canonical_state,
    events: row.events,
    canonicalStatePointer: row.canonical_state_pointer,
    commitKind: row.commit_kind,
    restoredFromRevisionId: row.restored_from_revision_id,
    autosaveEligible: row.autosave_eligible,
    summaryJobQueued: row.summary_job_queued,
    summaryKind: row.summary_kind
  });
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
        revision_id: string | null;
        status: string;
        response_payload: unknown;
      }>(
        `select player_id,
                run_id,
                save_slot_id,
                client_turn_id,
                request_hash,
                revision_id,
                status,
                response_payload
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
          revision_id,
          status,
          response_payload
        )
        values ($1, $2, $3, $4, $5, $6, $7, $8, $9::jsonb)`,
        [
          randomUUID(),
          record.playerId,
          record.runId,
          record.saveSlotId,
          record.clientTurnId,
          record.requestHash,
          record.revisionId,
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
    },
    async getRunState(playerId, runId, saveSlotId) {
      const result = await client.query<{
        campaign_id: string;
        active_revision_id: string | null;
        canonical_state: unknown | null;
        simulation_result: unknown | null;
      }>(
        `select runs.campaign_id,
                save_slots.active_revision_id,
                revisions.canonical_state,
                revisions.simulation_result
         from runs
         inner join save_slots
           on save_slots.run_id = runs.id
          and save_slots.id = $2
         left join revisions
           on revisions.id = save_slots.active_revision_id
         where runs.id = $1
           and runs.user_id = $3
         limit 1`,
        [runId, saveSlotId, playerId]
      );

      if (!result.rowCount) {
        const diagnostics = await client.query<{
          run_exists: boolean;
          save_slot_exists: boolean;
          save_slot_matches_run: boolean;
          player_matches_run: boolean;
        }>(
          `select exists(select 1 from runs where id = $1) as run_exists,
                  exists(select 1 from save_slots where id = $2) as save_slot_exists,
                  exists(select 1 from save_slots where id = $2 and run_id = $1) as save_slot_matches_run,
                  exists(select 1 from runs where id = $1 and user_id = $3) as player_matches_run`,
          [runId, saveSlotId, playerId]
        );

        const detail = diagnostics.rows[0];
        let reason = "Turn run context was not found.";

        if (!detail.run_exists) {
          reason = "Run was not found.";
        } else if (!detail.save_slot_exists) {
          reason = "Save slot was not found.";
        } else if (!detail.save_slot_matches_run) {
          reason = "Save slot does not belong to the requested run.";
        } else if (!detail.player_matches_run) {
          reason = "Player does not match the requested run.";
        }

        throw new Error(
          `${reason} lookup={ playerId: "${playerId}", runId: "${runId}", saveSlotId: "${saveSlotId}" }`
        );
      }

      const revisionContextResult = await client.query<{
        revision_id: string;
        canonical_state: unknown;
        summary_job_queued: boolean;
        summary_kind: "HARD" | "SOFT" | null;
        event_types: string[] | null;
      }>(
        `select revisions.id as revision_id,
                revisions.canonical_state,
                revisions.summary_job_queued,
                revisions.summary_kind,
                coalesce(array_agg(event_logs.event_type) filter (where event_logs.event_type is not null), '{}') as event_types
         from revisions
         left join event_logs
           on event_logs.revision_id = revisions.id
         where revisions.save_slot_id = $1
         group by revisions.id, revisions.canonical_state, revisions.summary_job_queued, revisions.summary_kind, revisions.created_at
         order by revisions.created_at desc
         limit 12`,
        [saveSlotId]
      );

      return {
        playerId,
        runId,
        saveSlotId,
        campaignId: result.rows[0].campaign_id,
        activeRevisionId: result.rows[0].active_revision_id,
        canonicalState: extractCanonicalStateSnapshot(
          result.rows[0].canonical_state ?? result.rows[0].simulation_result
        ),
        recentRevisionContext: revisionContextResult.rows.map((row) => ({
          revisionId: row.revision_id,
          turnCount: extractCanonicalStateSnapshot(row.canonical_state)?.turnCount ?? 0,
          summaryJobQueued: row.summary_job_queued,
          summaryKind: row.summary_kind,
          eventTypes: row.event_types ?? []
        }))
      } satisfies TurnRunState;
    },
    async getSaveHistory(playerId, runId, saveSlotId) {
      const runState = await this.getRunState(playerId, runId, saveSlotId);
      const revisionsResult = await client.query<{
        player_id: string;
        id: string;
        run_id: string;
        save_slot_id: string;
        previous_revision_id: string | null;
        ruleset_version: string;
        schema_version: number;
        created_at: Date | string;
        action_packet: unknown;
        simulation_result: unknown;
        canonical_state: unknown;
        canonical_state_pointer: string;
        autosave_eligible: boolean;
        summary_job_queued: boolean;
        summary_kind: "HARD" | "SOFT" | null;
        commit_kind: string;
        restored_from_revision_id: string | null;
        events: unknown;
      }>(
        `select $1::text as player_id,
                revisions.id,
                revisions.run_id,
                revisions.save_slot_id,
                revisions.previous_revision_id,
                revisions.ruleset_version,
                revisions.schema_version,
                revisions.created_at,
                revisions.action_packet,
                revisions.simulation_result,
                revisions.canonical_state,
                revisions.canonical_state_pointer,
                revisions.autosave_eligible,
                revisions.summary_job_queued,
                revisions.summary_kind,
                revisions.commit_kind,
                revisions.restored_from_revision_id,
                coalesce(
                  jsonb_agg(event_logs.payload order by event_logs.created_at)
                    filter (where event_logs.id is not null),
                  '[]'::jsonb
                ) as events
         from revisions
         left join event_logs
           on event_logs.revision_id = revisions.id
         where revisions.run_id = $2
           and revisions.save_slot_id = $3
         group by revisions.id
         order by revisions.created_at desc`,
        [playerId, runId, saveSlotId]
      );
      const saveArtifactsResult = await client.query<{
        id: string;
        revision_id: string;
        save_slot_id: string;
        campaign_id: string;
        schema_version: number;
        snapshot_pointer: string;
        canonical_state: unknown;
        saved_at: Date | string;
        save_kind: string;
        display_name: string | null;
      }>(
        `select id,
                revision_id,
                save_slot_id,
                campaign_id,
                schema_version,
                snapshot_pointer,
                canonical_state,
                saved_at,
                save_kind,
                display_name
         from save_snapshots
         where save_slot_id = $1
         order by saved_at desc`,
        [saveSlotId]
      );
      const checkpointsResult = await client.query<{
        checkpoint_id: string;
        revision_id: string;
        checkpoint_type: string;
        created_at: Date | string;
      }>(
        `select checkpoints.id as checkpoint_id,
                checkpoints.revision_id,
                checkpoints.checkpoint_type,
                checkpoints.created_at
         from checkpoints
         inner join revisions
           on revisions.id = checkpoints.revision_id
         where revisions.run_id = $1
           and revisions.save_slot_id = $2
         order by checkpoints.created_at desc`,
        [runId, saveSlotId]
      );

      return {
        playerId,
        runId,
        saveSlotId,
        campaignId: runState.campaignId,
        activeRevisionId: runState.activeRevisionId,
        revisions: revisionsResult.rows.map(mapRevisionRow),
        saveArtifacts: saveArtifactsResult.rows.map(mapSaveArtifactRow),
        checkpoints: checkpointsResult.rows.map(mapCheckpointRow)
      } satisfies SaveHistorySnapshot;
    },
    async saveArtifact(record: StoredSaveArtifact) {
      await client.query(
        `insert into save_snapshots (
          id,
          revision_id,
          save_slot_id,
          campaign_id,
          schema_version,
          snapshot_pointer,
          canonical_state,
          saved_at,
          save_kind,
          display_name
        )
        values ($1, $2, $3, $4, $5, $6, $7::jsonb, $8, $9, $10)`,
        [
          record.saveId,
          record.gameRevision,
          record.saveSlotId,
          record.campaignId,
          record.schemaVersion,
          record.snapshotPointer,
          JSON.stringify(record.canonicalState),
          record.savedAt,
          record.saveKind,
          record.displayName
        ]
      );
    },
    async deleteSaveArtifacts(saveIds: string[]) {
      if (saveIds.length === 0) {
        return;
      }

      await client.query(
        `delete from save_snapshots
         where id = any($1::text[])`,
        [saveIds]
      );
    },
    async saveMigrationRecord(record: PersistedMigrationRecord) {
      await client.query(
        `insert into migration_records (
          id,
          revision_id,
          save_id,
          from_schema_version,
          to_schema_version,
          status,
          debug_bundle
        )
        values ($1, $2, $3, $4, $5, $6, $7::jsonb)`,
        [
          record.migrationId,
          record.revisionId,
          record.saveId,
          record.fromSchemaVersion,
          record.toSchemaVersion,
          record.status,
          JSON.stringify(record.debugBundle)
        ]
      );
    },
    async commitAcceptedTurn(record: PersistedAcceptedTurnCommit) {
      await client.query(
        `insert into save_snapshots (
          id,
          revision_id,
          save_slot_id,
          campaign_id,
          schema_version,
          snapshot_pointer,
          canonical_state,
          saved_at,
          save_kind,
          display_name
        )
        values ($1, $2, $3, $4, $5, $6, $7::jsonb, $8, $9, $10)`,
        [
          record.saveSnapshot.saveId,
          record.saveSnapshot.gameRevision,
          record.saveSnapshot.saveSlotId,
          record.saveSnapshot.campaignId,
          record.saveSnapshot.schemaVersion,
          record.saveSnapshot.snapshotPointer,
          JSON.stringify(record.saveSnapshot.canonicalState),
          record.saveSnapshot.savedAt,
          "REVISION",
          null
        ]
      );

      await client.query(
        `insert into revisions (
          id,
          run_id,
          save_slot_id,
          previous_revision_id,
          ruleset_version,
          schema_version,
          canonical_state,
          canonical_state_pointer,
          action_packet,
          simulation_result,
          commit_kind,
          restored_from_revision_id,
          autosave_eligible,
          summary_job_queued,
          summary_kind
        )
        values ($1, $2, $3, $4, $5, $6, $7::jsonb, $8, $9::jsonb, $10::jsonb, $11, $12, $13, $14, $15)`,
        [
          record.revision.revisionId,
          record.revision.runId,
          record.revision.saveSlotId,
          record.revision.previousRevisionId,
          record.revision.rulesetVersion,
          record.revision.schemaVersion,
          JSON.stringify(record.revision.canonicalState),
          record.revision.canonicalStatePointer,
          JSON.stringify(record.revision.actionPacket),
          JSON.stringify(record.revision.simulationResult),
          record.revision.commitKind,
          record.revision.restoredFromRevisionId,
          record.revision.autosaveEligible,
          record.revision.summaryJobQueued,
          record.revision.summaryKind
        ]
      );

      if (record.eventLogs.length > 0) {
        const eventLogValues = buildBulkInsertValues(
          record.eventLogs.map((eventLog) => [
            eventLog.id,
            eventLog.revisionId,
            eventLog.eventType,
            JSON.stringify(eventLog.payload)
          ]),
          new Set([3])
        );

        await client.query(
          `insert into event_logs (
            id,
            revision_id,
            event_type,
            payload
          )
          values ${eventLogValues.placeholders}`,
          eventLogValues.values
        );
      }

      if (record.outboxEvents.length > 0) {
        const outboxValues = buildBulkInsertValues(
          record.outboxEvents.map((outboxEvent) => [
            outboxEvent.id,
            outboxEvent.revisionId,
            outboxEvent.jobType,
            outboxEvent.uniquenessKey,
            JSON.stringify(outboxEvent.payload)
          ]),
          new Set([4])
        );

        await client.query(
          `insert into outbox_events (
            id,
            revision_id,
            job_type,
            uniqueness_key,
            payload
          )
          values ${outboxValues.placeholders}`,
          outboxValues.values
        );
      }

      if (record.checkpointRecords.length > 0) {
        const checkpointValues = buildBulkInsertValues(
          record.checkpointRecords.map((checkpointRecord) => [
            checkpointRecord.checkpointId,
            checkpointRecord.revisionId,
            checkpointRecord.checkpointType,
            checkpointRecord.createdAt
          ])
        );

        await client.query(
          `insert into checkpoints (
            id,
            revision_id,
            checkpoint_type,
            created_at
          )
          values ${checkpointValues.placeholders}`,
          checkpointValues.values
        );
      }

      await client.query(
        `with updated_save_slot as (
           update save_slots
           set active_revision_id = $2,
               updated_at = now()
           where id = $1
           returning run_id
         )
         update runs
         set updated_at = now()
         where id in (select run_id from updated_save_slot)`,
        [record.revision.saveSlotId, record.revision.revisionId]
      );

      await client.query(
        `insert into turn_requests (
          id,
          player_id,
          run_id,
          save_slot_id,
          client_turn_id,
          request_hash,
          revision_id,
          status,
          response_payload
        )
        values ($1, $2, $3, $4, $5, $6, $7, $8, $9::jsonb)`,
        [
          randomUUID(),
          record.turnRequest.playerId,
          record.turnRequest.runId,
          record.turnRequest.saveSlotId,
          record.turnRequest.clientTurnId,
          record.turnRequest.requestHash,
          record.turnRequest.revisionId,
          record.turnRequest.status,
          JSON.stringify(record.turnRequest.responsePayload)
        ]
      );
    },
    async commitRollback(record: PersistedRollbackCommit) {
      await client.query(
        `insert into save_snapshots (
          id,
          revision_id,
          save_slot_id,
          campaign_id,
          schema_version,
          snapshot_pointer,
          canonical_state,
          saved_at,
          save_kind,
          display_name
        )
        values ($1, $2, $3, $4, $5, $6, $7::jsonb, $8, $9, $10)`,
        [
          record.saveSnapshot.saveId,
          record.saveSnapshot.gameRevision,
          record.saveSnapshot.saveSlotId,
          record.saveSnapshot.campaignId,
          record.saveSnapshot.schemaVersion,
          record.saveSnapshot.snapshotPointer,
          JSON.stringify(record.saveSnapshot.canonicalState),
          record.saveSnapshot.savedAt,
          "REVISION",
          null
        ]
      );

      await client.query(
        `insert into revisions (
          id,
          run_id,
          save_slot_id,
          previous_revision_id,
          ruleset_version,
          schema_version,
          canonical_state,
          canonical_state_pointer,
          action_packet,
          simulation_result,
          commit_kind,
          restored_from_revision_id,
          autosave_eligible,
          summary_job_queued,
          summary_kind
        )
        values ($1, $2, $3, $4, $5, $6, $7::jsonb, $8, $9::jsonb, $10::jsonb, $11, $12, $13, $14, $15)`,
        [
          record.revision.revisionId,
          record.revision.runId,
          record.revision.saveSlotId,
          record.revision.previousRevisionId,
          record.revision.rulesetVersion,
          record.revision.schemaVersion,
          JSON.stringify(record.revision.canonicalState),
          record.revision.canonicalStatePointer,
          JSON.stringify(record.revision.actionPacket),
          JSON.stringify(record.revision.simulationResult),
          record.revision.commitKind,
          record.revision.restoredFromRevisionId,
          record.revision.autosaveEligible,
          record.revision.summaryJobQueued,
          record.revision.summaryKind
        ]
      );

      if (record.eventLogs.length > 0) {
        const eventLogValues = buildBulkInsertValues(
          record.eventLogs.map((eventLog) => [
            eventLog.id,
            eventLog.revisionId,
            eventLog.eventType,
            JSON.stringify(eventLog.payload)
          ]),
          new Set([3])
        );

        await client.query(
          `insert into event_logs (
            id,
            revision_id,
            event_type,
            payload
          )
          values ${eventLogValues.placeholders}`,
          eventLogValues.values
        );
      }

      await client.query(
        `with updated_save_slot as (
           update save_slots
           set active_revision_id = $2,
               updated_at = now()
           where id = $1
           returning run_id
         )
         update runs
         set updated_at = now()
         where id in (select run_id from updated_save_slot)`,
        [record.revision.saveSlotId, record.revision.revisionId]
      );
    }
  };
}

export function createPgTurnIntakeRepository(
  connectionString = env.DATABASE_URL,
  max = env.DATABASE_POOL_MAX
): TurnIntakeRepository {
  const pool = new Pool({
    connectionString,
    max
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
