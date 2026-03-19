import type {
  CanonicalEvent,
  CheckpointRecord,
  ImageJob,
  MigrationDebugBundle,
  NarrationJob,
  RevisionRecord,
  ClarificationState,
  RouteCategory,
  SaveArtifactKind,
  SaveSnapshot,
  SummaryJob,
  SummaryTriggerKind,
  TurnAuthoritativeResponse
} from "@nexus-tales/contracts";

import type { CanonicalStateSnapshot } from "./state.js";

export interface StoredTurnRequest {
  playerId: string;
  runId: string;
  saveSlotId: string;
  clientTurnId: string;
  requestHash: string;
  revisionId: string | null;
  status: string;
  responsePayload: TurnAuthoritativeResponse;
}

export interface ClarificationStateRecord extends ClarificationState {
  lastInputFingerprint: string | null;
  lastSessionId: string;
}

export interface PersistedClarificationState {
  runId: string;
  saveSlotId: string;
  sceneFingerprint: string;
  lastTargetFingerprint: string | null;
  lastRouteCategory: RouteCategory | null;
  lastInputFingerprint: string | null;
  lastSessionId: string;
  ambiguityCount: number;
}

export interface PersistedTurnRequest {
  playerId: string;
  runId: string;
  saveSlotId: string;
  clientTurnId: string;
  requestHash: string;
  revisionId: string | null;
  status: string;
  responsePayload: TurnAuthoritativeResponse;
}

export interface TurnRunState {
  playerId: string;
  runId: string;
  saveSlotId: string;
  campaignId: string;
  activeRevisionId: string | null;
  canonicalState: CanonicalStateSnapshot | null;
  recentRevisionContext: PersistedRevisionContext[];
}

export interface PersistedRevisionContext {
  revisionId: string;
  turnCount: number;
  summaryJobQueued: boolean;
  summaryKind: SummaryTriggerKind | null;
  eventTypes: string[];
}

export interface PersistedEventLog {
  id: string;
  revisionId: string;
  eventType: string;
  payload: CanonicalEvent;
}

export type PersistedWorkerPayload = SummaryJob | NarrationJob | ImageJob;

export interface PersistedOutboxEvent {
  id: string;
  revisionId: string;
  jobType: PersistedWorkerPayload["jobType"];
  uniquenessKey: string;
  payload: PersistedWorkerPayload;
}

export interface PersistedCheckpointRecord extends CheckpointRecord {}

export interface StoredSaveArtifact {
  saveId: string;
  gameRevision: string;
  saveSlotId: string;
  campaignId: string;
  schemaVersion: number;
  snapshotPointer: string;
  savedAt: string;
  canonicalState: unknown;
  saveKind: SaveArtifactKind;
  displayName: string | null;
}

export interface SaveHistorySnapshot {
  playerId: string;
  runId: string;
  saveSlotId: string;
  campaignId: string;
  activeRevisionId: string | null;
  revisions: RevisionRecord[];
  saveArtifacts: StoredSaveArtifact[];
  checkpoints: PersistedCheckpointRecord[];
}

export interface PersistedAcceptedTurnCommit {
  turnRequest: PersistedTurnRequest & {
    revisionId: string;
  };
  revision: RevisionRecord;
  saveSnapshot: SaveSnapshot;
  eventLogs: PersistedEventLog[];
  outboxEvents: PersistedOutboxEvent[];
  checkpointRecords: PersistedCheckpointRecord[];
}

export interface PersistedRollbackCommit {
  revision: RevisionRecord;
  saveSnapshot: SaveSnapshot;
  eventLogs: PersistedEventLog[];
}

export interface PersistedMigrationRecord {
  migrationId: string;
  revisionId: string | null;
  saveId: string | null;
  fromSchemaVersion: number;
  toSchemaVersion: number;
  status: "SUCCEEDED" | "FAILED";
  debugBundle: MigrationDebugBundle | null;
}

export interface TurnIntakeTransaction {
  findTurnRequest(
    playerId: string,
    runId: string,
    saveSlotId: string,
    clientTurnId: string
  ): Promise<StoredTurnRequest | null>;
  saveTurnRequest(record: PersistedTurnRequest): Promise<void>;
  getClarificationState(
    runId: string,
    saveSlotId: string,
    sceneFingerprint: string
  ): Promise<ClarificationStateRecord | null>;
  upsertClarificationState(
    record: PersistedClarificationState
  ): Promise<ClarificationStateRecord>;
  clearClarificationState(
    runId: string,
    saveSlotId: string,
    sceneFingerprint: string
  ): Promise<void>;
  getRunState(
    playerId: string,
    runId: string,
    saveSlotId: string
  ): Promise<TurnRunState>;
  commitAcceptedTurn(record: PersistedAcceptedTurnCommit): Promise<void>;
  getSaveHistory(
    playerId: string,
    runId: string,
    saveSlotId: string
  ): Promise<SaveHistorySnapshot>;
  saveArtifact(record: StoredSaveArtifact): Promise<void>;
  deleteSaveArtifacts(saveIds: string[]): Promise<void>;
  saveMigrationRecord(record: PersistedMigrationRecord): Promise<void>;
  commitRollback(record: PersistedRollbackCommit): Promise<void>;
}

export interface TurnIntakeRepository {
  withTurnLock<T>(
    runId: string,
    saveSlotId: string,
    execute: (transaction: TurnIntakeTransaction) => Promise<T>
  ): Promise<T>;
  close?(): Promise<void>;
}
