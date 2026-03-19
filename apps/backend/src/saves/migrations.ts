import {
  CanonicalStateSchema,
  MigrationDebugBundleSchema,
  PERSISTENCE_SCHEMA_VERSION,
  type CanonicalState,
  type MigrationDebugBundle
} from "@nexus-tales/contracts";

const CANONICAL_STATE_FIELDS = [
  "sceneId",
  "turnCount",
  "momentum",
  "danger",
  "inventory",
  "storyFlags",
  "lastActionType"
] as const;

function asObject(value: unknown) {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new Error("Expected an object-like canonical state snapshot.");
  }

  return value as Record<string, unknown>;
}

function asInteger(value: unknown, field: string, fallback?: number) {
  if (typeof value === "number" && Number.isFinite(value)) {
    return Math.trunc(value);
  }

  if (fallback !== undefined) {
    return fallback;
  }

  throw new Error(`Expected an integer-compatible value for "${field}".`);
}

function asString(value: unknown, field: string, fallback?: string | null) {
  if (typeof value === "string" && value.trim().length > 0) {
    return value;
  }

  if (fallback !== undefined) {
    return fallback;
  }

  throw new Error(`Expected a non-empty string for "${field}".`);
}

function asStringArray(value: unknown) {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .filter((entry): entry is string => typeof entry === "string" && entry.trim().length > 0)
    .map((entry) => entry.trim());
}

function migrateV0ToV1(snapshot: unknown) {
  const candidate = asObject(snapshot);

  return {
    sceneId: asString(candidate.sceneId, "sceneId"),
    turnCount: asInteger(candidate.turnCount, "turnCount", 0),
    momentum: asInteger(candidate.momentum, "momentum", 0),
    danger: asInteger(candidate.danger ?? candidate.threat, "danger", 0),
    inventory: asStringArray(candidate.inventory),
    storyFlags: asStringArray(candidate.storyFlags),
    lastActionType: asString(candidate.lastActionType, "lastActionType", null)
  };
}

const MIGRATION_STEPS: Record<number, (snapshot: unknown) => unknown> = {
  0: migrateV0ToV1
};

export class SaveMigrationError extends Error {
  readonly debugBundle: MigrationDebugBundle;

  constructor(debugBundle: MigrationDebugBundle) {
    super(debugBundle.errorMessage);
    this.name = "SaveMigrationError";
    this.debugBundle = debugBundle;
  }
}

export function migrateCanonicalState(args: {
  canonicalState: unknown;
  fromSchemaVersion: number;
  sourceRevisionId: string | null;
  sourceSaveId: string | null;
}) {
  const attemptedSteps: string[] = [];
  let workingState = structuredClone(args.canonicalState);
  let currentVersion = args.fromSchemaVersion;

  try {
    if (currentVersion > PERSISTENCE_SCHEMA_VERSION) {
      throw new Error(
        `Save schema version ${currentVersion} is newer than supported version ${PERSISTENCE_SCHEMA_VERSION}.`
      );
    }

    while (currentVersion < PERSISTENCE_SCHEMA_VERSION) {
      const step = MIGRATION_STEPS[currentVersion];

      if (!step) {
        throw new Error(
          `Missing migration step from schema version ${currentVersion} to ${currentVersion + 1}.`
        );
      }

      attemptedSteps.push(`v${currentVersion}_to_v${currentVersion + 1}`);
      workingState = step(workingState);
      currentVersion += 1;
    }

    return {
      canonicalState: CanonicalStateSchema.parse(workingState) as CanonicalState,
      fromSchemaVersion: args.fromSchemaVersion,
      appliedSteps: attemptedSteps
    };
  } catch (error) {
    const errorMessage =
      error instanceof Error ? error.message : "Unknown save migration failure.";
    const debugBundle = MigrationDebugBundleSchema.parse({
      sourceRevisionId: args.sourceRevisionId,
      sourceSaveId: args.sourceSaveId,
      fromSchemaVersion: args.fromSchemaVersion,
      toSchemaVersion: PERSISTENCE_SCHEMA_VERSION,
      attemptedSteps,
      errorMessage,
      originalSnapshot: args.canonicalState,
      schemaDescriptor: {
        currentSchemaVersion: PERSISTENCE_SCHEMA_VERSION,
        canonicalStateFields: [...CANONICAL_STATE_FIELDS]
      }
    });

    throw new SaveMigrationError(debugBundle);
  }
}
