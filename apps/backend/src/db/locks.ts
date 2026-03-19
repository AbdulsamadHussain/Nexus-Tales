import { createHash } from "node:crypto";

import { sql } from "drizzle-orm";

export function buildRunSlotLockKey(runId: string, saveSlotId: string): bigint {
  const hash = createHash("sha256").update(`${runId}:${saveSlotId}`).digest();
  return hash.readBigInt64BE(0);
}

export function advisoryLockStatement(runId: string, saveSlotId: string) {
  const lockKey = buildRunSlotLockKey(runId, saveSlotId);
  return sql.raw(`select pg_advisory_xact_lock(${lockKey.toString()})`);
}

