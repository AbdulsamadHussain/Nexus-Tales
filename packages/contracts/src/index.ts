import { z } from "zod";

export const CONTRACTS_VERSION = "0.1.0";
export const RULESET_VERSION = "phase0-ruleset-v1";
export const PERSISTENCE_SCHEMA_VERSION = 1;

export const RulesetVersionSchema = z.literal(RULESET_VERSION);
export const PersistenceSchemaVersionSchema = z.literal(PERSISTENCE_SCHEMA_VERSION);

export const SafetyDecisionSchema = z.enum([
  "ALLOW",
  "ALLOW_WITH_CONSTRAINTS",
  "TRANSFORM",
  "REJECT"
]);

export const PolicyFlagSchema = z.string().min(1);
export const NarrationConstraintSchema = z.string().min(1);

export const RouteCategorySchema = z.enum([
  "NO_ROLL_DETERMINISTIC",
  "ROLL_REQUIRED",
  "CLARIFICATION_REQUIRED",
  "SAFE_REJECT",
  "UI_ACTION",
  "SYSTEM_TRANSFORMED_ACTION"
]);

export const SuccessTierSchema = z.enum([
  "CRITICAL_FAILURE",
  "FAILURE",
  "PARTIAL_SUCCESS",
  "FULL_SUCCESS",
  "CRITICAL_SUCCESS"
]);

export const DifficultyModeSchema = z.enum([
  "STORY",
  "STANDARD",
  "HARD"
]);

export const SummaryTriggerKindSchema = z.enum([
  "HARD",
  "SOFT"
]);

export const RevisionCommitKindSchema = z.enum([
  "PLAYER_TURN",
  "ROLLBACK"
]);

export const WorkerJobTypeSchema = z.enum([
  "SUMMARY",
  "NARRATION",
  "IMAGE"
]);

export const WorkerJobStatusSchema = z.enum([
  "QUEUED",
  "SKIPPED"
]);

export const AutosaveStatusSchema = z.enum([
  "ELIGIBLE",
  "INELIGIBLE"
]);

export const SaveArtifactKindSchema = z.enum([
  "REVISION",
  "MANUAL",
  "AUTOSAVE"
]);

export const CheckpointTypeSchema = z.enum([
  "CHAPTER_START"
]);

export const TurnStatusSchema = z.enum([
  "ACCEPTED",
  "CLARIFICATION_REQUIRED",
  "NO_OP",
  "REJECTED"
]);

export const ParserAssistanceStatusSchema = z.enum([
  "DISABLED",
  "PARSED",
  "NO_MATCH",
  "FAILED"
]);

const MetadataSchema = z.record(z.string(), z.unknown());

export const ContentSettingsSchema = z.object({
  violenceLevel: z.enum(["LOW", "MEDIUM", "HIGH"]).default("MEDIUM"),
  romanceEnabled: z.boolean().default(false),
  horrorEnabled: z.boolean().default(false),
  matureThemesEnabled: z.boolean().default(false),
  betrayalEnabled: z.boolean().default(false),
  customExclusions: z.array(z.string().min(1)).default([])
});

export const CanonicalStateSchema = z.object({
  sceneId: z.string().min(1),
  turnCount: z.number().int().min(0),
  momentum: z.number().int(),
  danger: z.number().int().min(0),
  inventory: z.array(z.string().min(1)).default([]),
  storyFlags: z.array(z.string().min(1)).default([]),
  lastActionType: z.string().nullable().default(null)
});

export const SafetyGatewayResultSchema = z.object({
  decision: SafetyDecisionSchema,
  sanitizedInput: z.string().min(1),
  policyFlags: z.array(PolicyFlagSchema).default([]),
  narrationConstraints: z.array(NarrationConstraintSchema).default([]),
  transformationReason: z.string().nullable().default(null),
  playerMessage: z.string().nullable().default(null),
  retryAllowed: z.boolean().default(true)
});

export const CanonicalEventSchema = z.object({
  eventType: z.string().min(1),
  entityId: z.string().nullable().default(null),
  occurredAt: z.string().datetime(),
  metadata: MetadataSchema.default({})
});

export const ActionPacketSchema = z.object({
  actionType: z.string().min(1),
  targetEntityId: z.string().nullable().default(null),
  method: z.string().nullable().default(null),
  stance: z.string().nullable().default(null),
  candidateSkills: z.array(z.string()).default([]),
  requiresRoll: z.boolean()
});

export const RollResultSchema = z.object({
  die: z.number().int().min(1).max(20),
  modifier: z.number().int(),
  total: z.number().int(),
  target: z.number().int()
});

export const SimulationValidationSchema = z.object({
  ok: z.boolean(),
  reason: z.string().nullable().default(null)
});

export const SimulationStateDeltaSchema = z.object({
  canonicalState: CanonicalStateSchema,
  changes: MetadataSchema.default({}),
  validation: SimulationValidationSchema
});

export const SimulationResultSchema = z.object({
  rulesetVersion: RulesetVersionSchema,
  successTier: SuccessTierSchema,
  roll: RollResultSchema.nullable(),
  stateDelta: SimulationStateDeltaSchema,
  events: z.array(CanonicalEventSchema).default([]),
  summaryFlags: z.array(z.string()).default([])
});

export const SaveSnapshotSchema = z.object({
  saveId: z.string().min(1),
  gameRevision: z.string().min(1),
  saveSlotId: z.string().min(1),
  campaignId: z.string().min(1),
  schemaVersion: PersistenceSchemaVersionSchema,
  snapshotPointer: z.string().min(1),
  savedAt: z.string().datetime(),
  canonicalState: CanonicalStateSchema
});

export const SaveArtifactSchema = z.object({
  saveId: z.string().min(1),
  gameRevision: z.string().min(1),
  saveSlotId: z.string().min(1),
  campaignId: z.string().min(1),
  schemaVersion: z.number().int().min(0),
  snapshotPointer: z.string().min(1),
  savedAt: z.string().datetime(),
  saveKind: SaveArtifactKindSchema,
  displayName: z.string().nullable().default(null)
});

export const WorkerReferenceSchema = z.object({
  jobType: WorkerJobTypeSchema,
  jobId: z.string().min(1),
  uniquenessKey: z.string().min(1),
  status: WorkerJobStatusSchema
});

export const ClarificationStateSchema = z.object({
  sceneFingerprint: z.string().min(1),
  ambiguityCount: z.number().int().min(0),
  lastTargetFingerprint: z.string().nullable().default(null),
  lastRouteCategory: RouteCategorySchema.nullable().default(null)
});

export const TurnIntakeSchema = z.object({
  sanitizedInputText: z.string().min(1),
  parserStatus: ParserAssistanceStatusSchema,
  advisoryActionPacket: ActionPacketSchema.nullable().default(null),
  sceneFingerprint: z.string().min(1),
  targetFingerprint: z.string().nullable().default(null),
  clarification: ClarificationStateSchema.nullable().default(null)
});

export const SummaryJobSchema = z.object({
  revisionId: z.string().min(1),
  campaignId: z.string().min(1),
  saveSlotId: z.string().min(1),
  schemaVersion: PersistenceSchemaVersionSchema,
  jobType: z.literal("SUMMARY"),
  uniquenessKey: z.string().min(1)
});

export const ImageJobSchema = z.object({
  revisionId: z.string().min(1),
  campaignId: z.string().min(1),
  saveSlotId: z.string().min(1),
  schemaVersion: PersistenceSchemaVersionSchema,
  jobType: z.literal("IMAGE"),
  sceneAnchorId: z.string().min(1),
  uniquenessKey: z.string().min(1)
});

export const NarrationJobSchema = z.object({
  revisionId: z.string().min(1),
  campaignId: z.string().min(1),
  saveSlotId: z.string().min(1),
  schemaVersion: PersistenceSchemaVersionSchema,
  jobType: z.literal("NARRATION"),
  uniquenessKey: z.string().min(1)
});

export const RevisionRecordSchema = z.object({
  revisionId: z.string().min(1),
  previousRevisionId: z.string().nullable().default(null),
  rulesetVersion: RulesetVersionSchema,
  schemaVersion: PersistenceSchemaVersionSchema,
  savedAt: z.string().datetime(),
  playerId: z.string().min(1),
  runId: z.string().min(1),
  saveSlotId: z.string().min(1),
  actionPacket: ActionPacketSchema,
  simulationResult: SimulationResultSchema,
  canonicalState: CanonicalStateSchema,
  events: z.array(CanonicalEventSchema).default([]),
  canonicalStatePointer: z.string().min(1),
  commitKind: RevisionCommitKindSchema,
  restoredFromRevisionId: z.string().nullable().default(null),
  autosaveEligible: z.boolean()
  ,
  summaryJobQueued: z.boolean(),
  summaryKind: SummaryTriggerKindSchema.nullable().default(null)
});

export const CheckpointRecordSchema = z.object({
  checkpointId: z.string().min(1),
  revisionId: z.string().min(1),
  checkpointType: CheckpointTypeSchema,
  createdAt: z.string().datetime()
});

export const RevisionHistoryEntrySchema = z.object({
  revisionId: z.string().min(1),
  previousRevisionId: z.string().nullable().default(null),
  savedAt: z.string().datetime(),
  turnCount: z.number().int().min(0),
  autosaveEligible: z.boolean(),
  summaryJobQueued: z.boolean(),
  summaryKind: SummaryTriggerKindSchema.nullable().default(null),
  successTier: SuccessTierSchema,
  commitKind: RevisionCommitKindSchema,
  restoredFromRevisionId: z.string().nullable().default(null),
  eventTypes: z.array(z.string().min(1)).default([]),
  isActive: z.boolean().default(false)
});

export const RevisionHistoryRequestSchema = z.object({
  playerId: z.string().min(1),
  runId: z.string().min(1),
  saveSlotId: z.string().min(1)
});

export const RevisionHistoryResponseSchema = z.object({
  playerId: z.string().min(1),
  runId: z.string().min(1),
  saveSlotId: z.string().min(1),
  activeRevisionId: z.string().nullable().default(null),
  revisions: z.array(RevisionHistoryEntrySchema).default([]),
  manualSaves: z.array(SaveArtifactSchema).default([]),
  autosaves: z.array(SaveArtifactSchema).default([]),
  checkpoints: z.array(CheckpointRecordSchema).default([]),
  autosaveRingSize: z.number().int().positive(),
  manualSaveLimit: z.number().int().positive()
});

export const TurnRequestSchema = z.object({
  playerId: z.string().min(1),
  runId: z.string().min(1),
  saveSlotId: z.string().min(1),
  clientTurnId: z.string().min(1),
  inputText: z.string().min(1),
  sceneId: z.string().min(1),
  difficultyMode: DifficultyModeSchema.default("STANDARD"),
  contentSettings: ContentSettingsSchema,
  sessionId: z.string().min(1)
});

export const ManualSaveRequestSchema = z.object({
  playerId: z.string().min(1),
  runId: z.string().min(1),
  saveSlotId: z.string().min(1),
  displayName: z.string().trim().min(1).max(80)
});

export const ManualSaveResponseSchema = z.object({
  save: SaveArtifactSchema,
  manualSaveLimit: z.number().int().positive(),
  manualSaveCount: z.number().int().min(0)
});

export const RollbackRequestSchema = z
  .object({
    playerId: z.string().min(1),
    runId: z.string().min(1),
    saveSlotId: z.string().min(1),
    revisionId: z.string().min(1).optional(),
    checkpointId: z.string().min(1).optional(),
    saveId: z.string().min(1).optional()
  })
  .superRefine((value, context) => {
    const targetCount = [value.revisionId, value.checkpointId, value.saveId].filter(
      (candidate) => typeof candidate === "string" && candidate.length > 0
    ).length;

    if (targetCount !== 1) {
      context.addIssue({
        code: z.ZodIssueCode.custom,
        message: "Exactly one rollback target must be provided."
      });
    }
  });

export const RollbackResponseSchema = z.object({
  revision: RevisionRecordSchema,
  saveSnapshot: SaveSnapshotSchema,
  restoredFromRevisionId: z.string().nullable().default(null),
  restoredFromSaveId: z.string().nullable().default(null),
  restoredFromCheckpointId: z.string().nullable().default(null),
  currentCanonicalState: CanonicalStateSchema,
  playerMessage: z.string().min(1)
});

export const TurnAuthoritativeResponseSchema = z.object({
  status: TurnStatusSchema,
  decision: SafetyDecisionSchema,
  policy: SafetyGatewayResultSchema,
  routeCategory: RouteCategorySchema,
  intake: TurnIntakeSchema,
  revisionId: z.string().nullable().default(null),
  simulationResult: SimulationResultSchema.nullable(),
  events: z.array(CanonicalEventSchema).default([]),
  saveSnapshot: SaveSnapshotSchema.nullable().default(null),
  autosaveStatus: AutosaveStatusSchema,
  workerJobs: z.array(WorkerReferenceSchema).default([]),
  playerMessage: z.string().nullable().default(null),
  rulesetVersion: RulesetVersionSchema
});

export const MigrationRecordStatusSchema = z.enum([
  "SUCCEEDED",
  "FAILED"
]);

export const MigrationDebugBundleSchema = z.object({
  sourceRevisionId: z.string().nullable().default(null),
  sourceSaveId: z.string().nullable().default(null),
  fromSchemaVersion: z.number().int().min(0),
  toSchemaVersion: z.number().int().min(0),
  attemptedSteps: z.array(z.string().min(1)).default([]),
  errorMessage: z.string().min(1),
  originalSnapshot: z.unknown(),
  schemaDescriptor: z.object({
    currentSchemaVersion: PersistenceSchemaVersionSchema,
    canonicalStateFields: z.array(z.string().min(1)).default([])
  })
});

export const MigrationRecordSchema = z.object({
  migrationId: z.string().min(1),
  revisionId: z.string().nullable().default(null),
  saveId: z.string().nullable().default(null),
  fromSchemaVersion: z.number().int().min(0),
  toSchemaVersion: z.number().int().min(0),
  status: MigrationRecordStatusSchema,
  debugBundle: MigrationDebugBundleSchema.nullable().default(null)
});

export const ErrorResponseSchema = z.object({
  code: z.string().min(1),
  message: z.string().min(1),
  details: MetadataSchema.default({})
});

export const ContractSchemas = {
  SafetyDecision: SafetyDecisionSchema,
  SafetyGatewayResult: SafetyGatewayResultSchema,
  RouteCategory: RouteCategorySchema,
  DifficultyMode: DifficultyModeSchema,
  SummaryTriggerKind: SummaryTriggerKindSchema,
  RevisionCommitKind: RevisionCommitKindSchema,
  SaveArtifactKind: SaveArtifactKindSchema,
  CheckpointType: CheckpointTypeSchema,
  CanonicalState: CanonicalStateSchema,
  ParserAssistanceStatus: ParserAssistanceStatusSchema,
  ActionPacket: ActionPacketSchema,
  SimulationResult: SimulationResultSchema,
  CanonicalEvent: CanonicalEventSchema,
  RevisionRecord: RevisionRecordSchema,
  SaveSnapshot: SaveSnapshotSchema,
  SaveArtifact: SaveArtifactSchema,
  SummaryJob: SummaryJobSchema,
  ImageJob: ImageJobSchema,
  NarrationJob: NarrationJobSchema,
  ClarificationState: ClarificationStateSchema,
  CheckpointRecord: CheckpointRecordSchema,
  RevisionHistoryEntry: RevisionHistoryEntrySchema,
  RevisionHistoryRequest: RevisionHistoryRequestSchema,
  RevisionHistoryResponse: RevisionHistoryResponseSchema,
  TurnIntake: TurnIntakeSchema,
  TurnRequest: TurnRequestSchema,
  ManualSaveRequest: ManualSaveRequestSchema,
  ManualSaveResponse: ManualSaveResponseSchema,
  RollbackRequest: RollbackRequestSchema,
  RollbackResponse: RollbackResponseSchema,
  TurnAuthoritativeResponse: TurnAuthoritativeResponseSchema,
  MigrationDebugBundle: MigrationDebugBundleSchema,
  MigrationRecord: MigrationRecordSchema,
  ErrorResponse: ErrorResponseSchema
} as const;

export type SafetyDecision = z.infer<typeof SafetyDecisionSchema>;
export type SafetyGatewayResult = z.infer<typeof SafetyGatewayResultSchema>;
export type RouteCategory = z.infer<typeof RouteCategorySchema>;
export type DifficultyMode = z.infer<typeof DifficultyModeSchema>;
export type SummaryTriggerKind = z.infer<typeof SummaryTriggerKindSchema>;
export type RevisionCommitKind = z.infer<typeof RevisionCommitKindSchema>;
export type SaveArtifactKind = z.infer<typeof SaveArtifactKindSchema>;
export type CheckpointType = z.infer<typeof CheckpointTypeSchema>;
export type CanonicalState = z.infer<typeof CanonicalStateSchema>;
export type ActionPacket = z.infer<typeof ActionPacketSchema>;
export type SimulationResult = z.infer<typeof SimulationResultSchema>;
export type CanonicalEvent = z.infer<typeof CanonicalEventSchema>;
export type RevisionRecord = z.infer<typeof RevisionRecordSchema>;
export type SaveSnapshot = z.infer<typeof SaveSnapshotSchema>;
export type SaveArtifact = z.infer<typeof SaveArtifactSchema>;
export type SummaryJob = z.infer<typeof SummaryJobSchema>;
export type ImageJob = z.infer<typeof ImageJobSchema>;
export type NarrationJob = z.infer<typeof NarrationJobSchema>;
export type ParserAssistanceStatus = z.infer<typeof ParserAssistanceStatusSchema>;
export type ClarificationState = z.infer<typeof ClarificationStateSchema>;
export type CheckpointRecord = z.infer<typeof CheckpointRecordSchema>;
export type RevisionHistoryEntry = z.infer<typeof RevisionHistoryEntrySchema>;
export type RevisionHistoryRequest = z.infer<typeof RevisionHistoryRequestSchema>;
export type RevisionHistoryResponse = z.infer<typeof RevisionHistoryResponseSchema>;
export type TurnIntake = z.infer<typeof TurnIntakeSchema>;
export type TurnRequest = z.infer<typeof TurnRequestSchema>;
export type ManualSaveRequest = z.infer<typeof ManualSaveRequestSchema>;
export type ManualSaveResponse = z.infer<typeof ManualSaveResponseSchema>;
export type RollbackRequest = z.infer<typeof RollbackRequestSchema>;
export type RollbackResponse = z.infer<typeof RollbackResponseSchema>;
export type TurnAuthoritativeResponse = z.infer<typeof TurnAuthoritativeResponseSchema>;
export type MigrationDebugBundle = z.infer<typeof MigrationDebugBundleSchema>;
export type MigrationRecord = z.infer<typeof MigrationRecordSchema>;
export type ErrorResponse = z.infer<typeof ErrorResponseSchema>;
