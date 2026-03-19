import {
  bigint,
  boolean,
  integer,
  jsonb,
  pgTable,
  text,
  timestamp,
  uniqueIndex
} from "drizzle-orm/pg-core";

export const users = pgTable("users", {
  id: text("id").primaryKey(),
  authSubject: text("auth_subject").notNull().unique(),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).defaultNow().notNull()
});

export const campaigns = pgTable("campaigns", {
  id: text("id").primaryKey(),
  slug: text("slug").notNull().unique(),
  displayName: text("display_name").notNull(),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull()
});

export const runs = pgTable("runs", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id),
  campaignId: text("campaign_id").notNull().references(() => campaigns.id),
  activeRevisionId: text("active_revision_id"),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).defaultNow().notNull()
});

export const saveSlots = pgTable("save_slots", {
  id: text("id").primaryKey(),
  runId: text("run_id").notNull().references(() => runs.id),
  slotType: text("slot_type").notNull(),
  displayName: text("display_name").notNull(),
  isProtected: boolean("is_protected").default(false).notNull(),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).defaultNow().notNull()
});

export const revisions = pgTable("revisions", {
  id: text("id").primaryKey(),
  runId: text("run_id").notNull().references(() => runs.id),
  saveSlotId: text("save_slot_id").notNull().references(() => saveSlots.id),
  previousRevisionId: text("previous_revision_id"),
  rulesetVersion: text("ruleset_version").notNull(),
  schemaVersion: integer("schema_version").notNull(),
  canonicalStatePointer: text("canonical_state_pointer").notNull(),
  actionPacket: jsonb("action_packet").notNull(),
  simulationResult: jsonb("simulation_result").notNull(),
  autosaveEligible: boolean("autosave_eligible").default(false).notNull(),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull()
});

export const turnRequests = pgTable(
  "turn_requests",
  {
    id: text("id").primaryKey(),
    playerId: text("player_id").notNull().references(() => users.id),
    runId: text("run_id").notNull().references(() => runs.id),
    saveSlotId: text("save_slot_id").notNull().references(() => saveSlots.id),
    clientTurnId: text("client_turn_id").notNull(),
    requestHash: text("request_hash").notNull(),
    revisionId: text("revision_id"),
    status: text("status").notNull(),
    responsePayload: jsonb("response_payload"),
    createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull()
  },
  (table) => ({
    replayKey: uniqueIndex("turn_requests_replay_key").on(
      table.playerId,
      table.runId,
      table.saveSlotId,
      table.clientTurnId
    )
  })
);

export const checkpoints = pgTable("checkpoints", {
  id: text("id").primaryKey(),
  revisionId: text("revision_id").notNull().references(() => revisions.id),
  checkpointType: text("checkpoint_type").notNull(),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull()
});

export const eventLogs = pgTable("event_logs", {
  id: text("id").primaryKey(),
  revisionId: text("revision_id").notNull().references(() => revisions.id),
  eventType: text("event_type").notNull(),
  payload: jsonb("payload").notNull(),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull()
});

export const outboxEvents = pgTable(
  "outbox_events",
  {
    id: text("id").primaryKey(),
    revisionId: text("revision_id").references(() => revisions.id),
    jobType: text("job_type").notNull(),
    uniquenessKey: text("uniqueness_key").notNull(),
    payload: jsonb("payload").notNull(),
    publishedAt: timestamp("published_at", { withTimezone: true }),
    createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull()
  },
  (table) => ({
    uniquenessKeyIdx: uniqueIndex("outbox_events_uniqueness_key").on(table.uniquenessKey)
  })
);

export const jobRecords = pgTable(
  "job_records",
  {
    id: text("id").primaryKey(),
    revisionId: text("revision_id").references(() => revisions.id),
    jobType: text("job_type").notNull(),
    uniquenessKey: text("uniqueness_key").notNull(),
    status: text("status").notNull(),
    payload: jsonb("payload").notNull(),
    retryCount: integer("retry_count").default(0).notNull(),
    createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
    updatedAt: timestamp("updated_at", { withTimezone: true }).defaultNow().notNull()
  },
  (table) => ({
    uniquenessKeyIdx: uniqueIndex("job_records_uniqueness_key").on(table.uniquenessKey)
  })
);

export const clarificationState = pgTable(
  "clarification_state",
  {
    id: text("id").primaryKey(),
    runId: text("run_id").notNull().references(() => runs.id),
    saveSlotId: text("save_slot_id").notNull().references(() => saveSlots.id),
    sessionId: text("session_id").notNull(),
    sceneFingerprint: text("scene_fingerprint").notNull(),
    lastTargetFingerprint: text("last_target_fingerprint"),
    lastRouteCategory: text("last_route_category"),
    ambiguityCount: integer("ambiguity_count").default(0).notNull(),
    updatedAt: timestamp("updated_at", { withTimezone: true }).defaultNow().notNull()
  },
  (table) => ({
    activeScopeIdx: uniqueIndex("clarification_state_scope_idx").on(
      table.runId,
      table.saveSlotId,
      table.sessionId
    )
  })
);

export const migrationRecords = pgTable("migration_records", {
  id: text("id").primaryKey(),
  revisionId: text("revision_id"),
  fromSchemaVersion: integer("from_schema_version").notNull(),
  toSchemaVersion: integer("to_schema_version").notNull(),
  status: text("status").notNull(),
  debugBundle: jsonb("debug_bundle"),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull()
});

export const advisoryLockAudit = pgTable("advisory_lock_audit", {
  id: text("id").primaryKey(),
  runId: text("run_id").notNull().references(() => runs.id),
  saveSlotId: text("save_slot_id").notNull().references(() => saveSlots.id),
  lockKey: bigint("lock_key", { mode: "bigint" }).notNull(),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull()
});

