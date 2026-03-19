import { CanonicalStateSchema, type CanonicalState } from "@nexus-tales/contracts";

export type CanonicalStateSnapshot = CanonicalState;

export interface InitialCanonicalStateContext {
  playerId: string;
  runId: string;
  saveSlotId: string;
  campaignId: string;
  sceneId: string;
}

export type InitialCanonicalStateProvider = (
  context: InitialCanonicalStateContext
) => CanonicalStateSnapshot;

function normalizeList(values: string[]) {
  return [...new Set(values.map((value) => value.trim()).filter(Boolean))].sort((left, right) =>
    left.localeCompare(right)
  );
}

export function normalizeCanonicalState(
  state: CanonicalStateSnapshot
): CanonicalStateSnapshot {
  return CanonicalStateSchema.parse({
    ...state,
    inventory: normalizeList(state.inventory),
    storyFlags: normalizeList(state.storyFlags)
  });
}

// Phase 2 fallback only. Replace this with campaign-pack state initialization
// before introducing additional campaigns or per-campaign starting inventories.
export function createPrototypeInitialCanonicalState(
  context: InitialCanonicalStateContext
): CanonicalStateSnapshot {
  return normalizeCanonicalState({
    sceneId: context.sceneId,
    turnCount: 0,
    momentum: 0,
    danger: 0,
    inventory: ["field journal", "lantern"],
    storyFlags: ["story:intro"],
    lastActionType: null
  });
}

export function extractCanonicalStateSnapshot(simulationResult: unknown) {
  const parsed = CanonicalStateSchema.safeParse(simulationResult);

  if (parsed.success) {
    return normalizeCanonicalState(parsed.data);
  }

  if (!simulationResult || typeof simulationResult !== "object") {
    return null;
  }

  const candidate =
    (simulationResult as { canonicalState?: unknown; stateDelta?: { canonicalState?: unknown } })
      .canonicalState ??
    (simulationResult as { stateDelta?: { canonicalState?: unknown } }).stateDelta?.canonicalState;
  const nestedParsed = CanonicalStateSchema.safeParse(candidate);

  return nestedParsed.success ? normalizeCanonicalState(nestedParsed.data) : null;
}
