import type {
  ClarificationState,
  RouteCategory,
  TurnAuthoritativeResponse
} from "@nexus-tales/contracts";

export interface StoredTurnRequest {
  playerId: string;
  runId: string;
  saveSlotId: string;
  clientTurnId: string;
  requestHash: string;
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
  status: string;
  responsePayload: TurnAuthoritativeResponse;
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
}

export interface TurnIntakeRepository {
  withTurnLock<T>(
    runId: string,
    saveSlotId: string,
    execute: (transaction: TurnIntakeTransaction) => Promise<T>
  ): Promise<T>;
  close?(): Promise<void>;
}
