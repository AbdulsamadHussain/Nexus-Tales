import type {
  ActionPacket,
  ParserAssistanceStatus,
  RouteCategory,
  SafetyDecision,
  TurnAuthoritativeResponse,
  TurnRequest
} from "@nexus-tales/contracts";
import {
  RULESET_VERSION,
  TurnAuthoritativeResponseSchema
} from "@nexus-tales/contracts";

import { buildFingerprint, buildStableHash, sanitizeInputText } from "./helpers.js";
import type {
  ClarificationStateRecord,
  TurnIntakeRepository
} from "./repository.js";

const HARD_REJECT_PATTERNS = [
  /\b(?:build|make)\s+(?:a\s+)?bomb\b/i,
  /\bdoxx(?:ing)?\b/i,
  /\bcredit\s+card\s+fraud\b/i,
  /\bterror(?:ist|ism)\b/i,
  /\bchild\s+(?:sexual|abuse)\b/i
] as const;

const PROMPT_INJECTION_PATTERNS = [
  /\bignore\s+(?:the\s+)?(?:previous|prior)\s+instructions?\b/gi,
  /\bbreak\s+character\b/gi,
  /\bsystem\s+prompt\b/gi,
  /\bdeveloper\s+message\b/gi,
  /\boverride\s+the\s+rules\b/gi
] as const;

const GENERIC_AMBIGUOUS_INPUTS = new Set([
  "do it",
  "go",
  "look",
  "use it",
  "attack",
  "talk",
  "continue",
  "help",
  "yes",
  "no"
]);

const UI_ACTION_PATTERNS = [
  /^(?:open|show|check|view)\s+(?:the\s+)?(?:inventory|quests?|codex|map|sheet|journal|settings|history)\b/i,
  /^(?:save|load|rollback)\b/i,
  /^(?:inventory|quests?|codex|map|sheet|settings|history)$/i
] as const;

type VerbConfig = {
  actionType: string;
  requiresRoll: boolean;
  candidateSkills: string[];
};

const VERB_CONFIGS: Record<string, VerbConfig> = {
  inspect: {
    actionType: "INSPECT",
    requiresRoll: false,
    candidateSkills: ["PERCEPTION", "INVESTIGATION"]
  },
  examine: {
    actionType: "INSPECT",
    requiresRoll: false,
    candidateSkills: ["PERCEPTION", "INVESTIGATION"]
  },
  search: {
    actionType: "SEARCH",
    requiresRoll: true,
    candidateSkills: ["INVESTIGATION", "PERCEPTION"]
  },
  open: {
    actionType: "OPEN",
    requiresRoll: false,
    candidateSkills: []
  },
  read: {
    actionType: "READ",
    requiresRoll: false,
    candidateSkills: ["LORE"]
  },
  take: {
    actionType: "TAKE",
    requiresRoll: false,
    candidateSkills: ["DEXTERITY"]
  },
  grab: {
    actionType: "TAKE",
    requiresRoll: false,
    candidateSkills: ["DEXTERITY"]
  },
  use: {
    actionType: "USE",
    requiresRoll: false,
    candidateSkills: []
  },
  talk: {
    actionType: "TALK",
    requiresRoll: false,
    candidateSkills: ["INSIGHT", "PERSUASION"]
  },
  ask: {
    actionType: "ASK",
    requiresRoll: false,
    candidateSkills: ["INSIGHT", "PERSUASION"]
  },
  persuade: {
    actionType: "PERSUADE",
    requiresRoll: true,
    candidateSkills: ["PERSUASION"]
  },
  convince: {
    actionType: "PERSUADE",
    requiresRoll: true,
    candidateSkills: ["PERSUASION"]
  },
  deceive: {
    actionType: "DECEIVE",
    requiresRoll: true,
    candidateSkills: ["DECEPTION"]
  },
  intimidate: {
    actionType: "INTIMIDATE",
    requiresRoll: true,
    candidateSkills: ["INTIMIDATION"]
  },
  attack: {
    actionType: "ATTACK",
    requiresRoll: true,
    candidateSkills: ["MELEE", "RANGED"]
  },
  strike: {
    actionType: "ATTACK",
    requiresRoll: true,
    candidateSkills: ["MELEE"]
  },
  shoot: {
    actionType: "ATTACK",
    requiresRoll: true,
    candidateSkills: ["RANGED"]
  },
  sneak: {
    actionType: "STEALTH",
    requiresRoll: true,
    candidateSkills: ["STEALTH"]
  },
  steal: {
    actionType: "STEAL",
    requiresRoll: true,
    candidateSkills: ["SLEIGHT_OF_HAND", "STEALTH"]
  },
  pickpocket: {
    actionType: "STEAL",
    requiresRoll: true,
    candidateSkills: ["SLEIGHT_OF_HAND", "STEALTH"]
  },
  lockpick: {
    actionType: "LOCKPICK",
    requiresRoll: true,
    candidateSkills: ["THIEVES_TOOLS"]
  },
  disarm: {
    actionType: "DISARM",
    requiresRoll: true,
    candidateSkills: ["DEXTERITY"]
  },
  climb: {
    actionType: "CLIMB",
    requiresRoll: true,
    candidateSkills: ["ATHLETICS"]
  },
  jump: {
    actionType: "JUMP",
    requiresRoll: true,
    candidateSkills: ["ATHLETICS"]
  },
  move: {
    actionType: "MOVE",
    requiresRoll: false,
    candidateSkills: []
  },
  go: {
    actionType: "MOVE",
    requiresRoll: false,
    candidateSkills: []
  },
  cast: {
    actionType: "CAST",
    requiresRoll: true,
    candidateSkills: ["ARCANA"]
  }
};

export class IdempotencyConflictError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "IdempotencyConflictError";
  }
}

export interface TurnFeatureFlags {
  parserAssistanceEnabled: boolean;
}

export interface TurnIntakeService {
  handleTurn(request: TurnRequest): Promise<TurnAuthoritativeResponse>;
}

type SafetyAssessment = {
  decision: SafetyDecision;
  effectiveInputText: string;
  playerMessage: string | null;
};

type RoutingAssessment = {
  routeCategory: RouteCategory;
  parserStatus: ParserAssistanceStatus;
  advisoryActionPacket: ActionPacket | null;
  targetFingerprint: string | null;
};

function normalizeForParsing(inputText: string) {
  return inputText
    .toLowerCase()
    .replace(/^[.!?]+|[.!?]+$/g, "")
    .replace(/^(?:i|we)\s+(?:want to\s+|try to\s+|attempt to\s+)?/, "")
    .trim();
}

function evaluateSafety(
  inputText: string,
  contentSettings: TurnRequest["contentSettings"]
): SafetyAssessment {
  if (HARD_REJECT_PATTERNS.some((pattern) => pattern.test(inputText))) {
    return {
      decision: "REJECT",
      effectiveInputText: inputText,
      playerMessage: "That action cannot be processed."
    };
  }

  let effectiveInputText = inputText;
  let wasTransformed = false;

  for (const pattern of PROMPT_INJECTION_PATTERNS) {
    const transformedInput = effectiveInputText.replace(pattern, " ");

    if (transformedInput !== effectiveInputText) {
      effectiveInputText = transformedInput;
      wasTransformed = true;
    }
  }

  effectiveInputText = sanitizeInputText(effectiveInputText);

  if (!effectiveInputText) {
    return {
      decision: "REJECT",
      effectiveInputText: inputText,
      playerMessage: "Describe the in-world action instead of system instructions."
    };
  }

  const loweredInput = effectiveInputText.toLowerCase();

  if (
    contentSettings.romanceEnabled === false &&
    /\b(?:kiss|flirt|seduce|romance)\b/i.test(loweredInput)
  ) {
    return {
      decision: "ALLOW_WITH_CONSTRAINTS",
      effectiveInputText,
      playerMessage: "Romance is disabled, so the action will stay non-romantic."
    };
  }

  if (
    contentSettings.horrorEnabled === false &&
    /\b(?:haunt|eldritch|horror|ritual sacrifice|necromanc(?:y|er))\b/i.test(loweredInput)
  ) {
    return {
      decision: "ALLOW_WITH_CONSTRAINTS",
      effectiveInputText,
      playerMessage: "Horror content is constrained by your current settings."
    };
  }

  if (
    contentSettings.matureThemesEnabled === false &&
    /\b(?:drug|torture|explicit|sex)\b/i.test(loweredInput)
  ) {
    return {
      decision: "ALLOW_WITH_CONSTRAINTS",
      effectiveInputText,
      playerMessage: "Mature themes are disabled, so the action will be toned down."
    };
  }

  if (
    contentSettings.betrayalEnabled === false &&
    /\b(?:betray|double[- ]cross|backstab|steal from)\b/i.test(loweredInput)
  ) {
    return {
      decision: "ALLOW_WITH_CONSTRAINTS",
      effectiveInputText,
      playerMessage: "Betrayal is disabled, so the action cannot target allies that way."
    };
  }

  if (
    (contentSettings.violenceLevel === "LOW" &&
      /\b(?:kill|murder|behead|dismember|gut)\b/i.test(loweredInput)) ||
    (contentSettings.violenceLevel === "MEDIUM" &&
      /\b(?:behead|dismember)\b/i.test(loweredInput))
  ) {
    return {
      decision: "ALLOW_WITH_CONSTRAINTS",
      effectiveInputText,
      playerMessage: "Violence is constrained by your current settings."
    };
  }

  if (wasTransformed) {
    return {
      decision: "TRANSFORM",
      effectiveInputText,
      playerMessage: "System-level instructions were stripped before routing the action."
    };
  }

  return {
    decision: "ALLOW",
    effectiveInputText,
    playerMessage: null
  };
}

function parseActionPacket(inputText: string): ActionPacket | null {
  const normalizedInput = normalizeForParsing(inputText);

  if (!normalizedInput) {
    return null;
  }

  const [verb] = normalizedInput.split(/\s+/, 1);
  const config = VERB_CONFIGS[verb];

  if (!config) {
    return null;
  }

  const remainder = normalizedInput.slice(verb.length).trim();
  const targetMatch = remainder.match(
    /^(?:the|a|an|to|at|on|into|in|from)?\s*([^,]+?)(?:\s+(?:with|using)\s+(.+))?$/i
  );

  const targetEntityId = targetMatch?.[1]?.trim() || null;
  const method = targetMatch?.[2]?.trim() || null;

  return {
    actionType: config.actionType,
    targetEntityId,
    method,
    stance: null,
    candidateSkills: config.candidateSkills,
    requiresRoll: config.requiresRoll
  };
}

function assessRouting(
  inputText: string,
  parserAssistanceEnabled: boolean,
  wasTransformed: boolean
): RoutingAssessment {
  if (UI_ACTION_PATTERNS.some((pattern) => pattern.test(inputText))) {
    return {
      routeCategory: "UI_ACTION",
      parserStatus: parserAssistanceEnabled ? "NO_MATCH" : "DISABLED",
      advisoryActionPacket: null,
      targetFingerprint: null
    };
  }

  let parserStatus: ParserAssistanceStatus = parserAssistanceEnabled ? "NO_MATCH" : "DISABLED";
  let advisoryActionPacket: ActionPacket | null = null;
  let classifiedActionPacket: ActionPacket | null = null;

  try {
    classifiedActionPacket = parseActionPacket(inputText);
    advisoryActionPacket = parserAssistanceEnabled ? classifiedActionPacket : null;
    parserStatus = parserAssistanceEnabled
      ? classifiedActionPacket
        ? "PARSED"
        : "NO_MATCH"
      : "DISABLED";
  } catch {
    classifiedActionPacket = null;
    advisoryActionPacket = null;
    parserStatus = parserAssistanceEnabled ? "FAILED" : "DISABLED";
  }

  const normalizedInput = normalizeForParsing(inputText);
  const classifiedTarget = classifiedActionPacket?.targetEntityId ?? null;
  const ambiguousPronoun =
    classifiedTarget !== null &&
    /^(?:it|them|that|this|there|someone|something)$/i.test(classifiedTarget);
  const missingTargetOnShortKnownVerb =
    classifiedActionPacket !== null &&
    classifiedActionPacket.targetEntityId === null &&
    normalizedInput.split(/\s+/).length <= 2;

  const routeCategory: RouteCategory =
    !normalizedInput ||
    GENERIC_AMBIGUOUS_INPUTS.has(normalizedInput) ||
    ambiguousPronoun ||
    missingTargetOnShortKnownVerb ||
    (!classifiedActionPacket && normalizedInput.split(/\s+/).length <= 2)
      ? "CLARIFICATION_REQUIRED"
      : wasTransformed
        ? "SYSTEM_TRANSFORMED_ACTION"
        : classifiedActionPacket?.requiresRoll
          ? "ROLL_REQUIRED"
          : "NO_ROLL_DETERMINISTIC";

  const targetFingerprint = classifiedActionPacket?.targetEntityId
    ? buildFingerprint(classifiedActionPacket.targetEntityId.toLowerCase())
    : null;

  return {
    routeCategory,
    parserStatus,
    advisoryActionPacket,
    targetFingerprint
  };
}

function buildClarificationResponseMessage(
  ambiguityCount: number,
  inputText: string,
  targetFingerprint: string | null
) {
  if (ambiguityCount >= 3) {
    return "I still need a clearer action and target before I can proceed. Rephrase with one concrete verb and object.";
  }

  if (!targetFingerprint) {
    return `I need a more specific action for "${inputText}". Tell me what you want to do and what you are acting on.`;
  }

  return "I need a clearer target or method before I can route that action.";
}

function shouldContinueClarification(
  previousState: ClarificationStateRecord | null,
  nextRouteCategory: RouteCategory,
  targetFingerprint: string | null,
  inputFingerprint: string
) {
  return (
    previousState !== null &&
    previousState.lastRouteCategory === nextRouteCategory &&
    previousState.lastTargetFingerprint === targetFingerprint &&
    previousState.lastInputFingerprint === inputFingerprint
  );
}

function buildAcceptedMessage(
  decision: SafetyDecision,
  routeCategory: RouteCategory,
  safetyMessage: string | null
) {
  if (safetyMessage) {
    return safetyMessage;
  }

  if (routeCategory === "UI_ACTION") {
    return "That request is a client-side action, so it does not consume a turn.";
  }

  if (decision === "ALLOW") {
    return "Turn accepted for deterministic simulation.";
  }

  return "Turn accepted with intake-time policy adjustments.";
}

export function createTurnIntakeService(options: {
  repository: TurnIntakeRepository;
  featureFlags?: Partial<TurnFeatureFlags>;
}): TurnIntakeService {
  const featureFlags: TurnFeatureFlags = {
    parserAssistanceEnabled: options.featureFlags?.parserAssistanceEnabled ?? false
  };

  return {
    async handleTurn(request) {
      const sanitizedInputText = sanitizeInputText(request.inputText);
      const requestHash = buildStableHash(request);
      const sceneFingerprint = buildFingerprint(request.sceneId);
      const inputFingerprint = buildFingerprint(sanitizedInputText.toLowerCase());
      const safetyAssessment = evaluateSafety(sanitizedInputText, request.contentSettings);
      const routingAssessment =
        safetyAssessment.decision === "REJECT"
          ? {
              routeCategory: "SAFE_REJECT" as const,
              parserStatus: featureFlags.parserAssistanceEnabled
                ? ("NO_MATCH" as const)
                : ("DISABLED" as const),
              advisoryActionPacket: null,
              targetFingerprint: null
            }
          : assessRouting(
              safetyAssessment.effectiveInputText,
              featureFlags.parserAssistanceEnabled,
              safetyAssessment.decision === "TRANSFORM"
            );

      return options.repository.withTurnLock(request.runId, request.saveSlotId, async (tx) => {
        const existingTurn = await tx.findTurnRequest(
          request.playerId,
          request.runId,
          request.saveSlotId,
          request.clientTurnId
        );

        if (existingTurn) {
          if (existingTurn.requestHash !== requestHash) {
            throw new IdempotencyConflictError(
              "The same client_turn_id was reused with a different request payload."
            );
          }

          return existingTurn.responsePayload;
        }

        let status: TurnAuthoritativeResponse["status"];
        let playerMessage: string | null;
        let clarification = null;

        if (safetyAssessment.decision === "REJECT") {
          status = "REJECTED";
          playerMessage = safetyAssessment.playerMessage;
          await tx.clearClarificationState(
            request.runId,
            request.saveSlotId,
            sceneFingerprint
          );
        } else if (routingAssessment.routeCategory === "CLARIFICATION_REQUIRED") {
          const previousClarification = await tx.getClarificationState(
            request.runId,
            request.saveSlotId,
            sceneFingerprint
          );

          const ambiguityCount = shouldContinueClarification(
            previousClarification,
            routingAssessment.routeCategory,
            routingAssessment.targetFingerprint,
            inputFingerprint
          )
            ? (previousClarification?.ambiguityCount ?? 0) + 1
            : 1;

          const storedClarification = await tx.upsertClarificationState({
            runId: request.runId,
            saveSlotId: request.saveSlotId,
            sceneFingerprint,
            lastTargetFingerprint: routingAssessment.targetFingerprint,
            lastRouteCategory: routingAssessment.routeCategory,
            lastInputFingerprint: inputFingerprint,
            lastSessionId: request.sessionId,
            ambiguityCount
          });

          clarification = {
            sceneFingerprint: storedClarification.sceneFingerprint,
            ambiguityCount: storedClarification.ambiguityCount,
            lastTargetFingerprint: storedClarification.lastTargetFingerprint,
            lastRouteCategory: storedClarification.lastRouteCategory
          };

          status = "CLARIFICATION_REQUIRED";
          playerMessage = buildClarificationResponseMessage(
            storedClarification.ambiguityCount,
            safetyAssessment.effectiveInputText,
            routingAssessment.targetFingerprint
          );
        } else {
          await tx.clearClarificationState(
            request.runId,
            request.saveSlotId,
            sceneFingerprint
          );

          status = routingAssessment.routeCategory === "UI_ACTION" ? "NO_OP" : "ACCEPTED";
          playerMessage = buildAcceptedMessage(
            safetyAssessment.decision,
            routingAssessment.routeCategory,
            safetyAssessment.playerMessage
          );
        }

        const response = TurnAuthoritativeResponseSchema.parse({
          status,
          decision: safetyAssessment.decision,
          routeCategory: routingAssessment.routeCategory,
          intake: {
            sanitizedInputText: safetyAssessment.effectiveInputText,
            parserStatus: routingAssessment.parserStatus,
            advisoryActionPacket: routingAssessment.advisoryActionPacket,
            sceneFingerprint,
            targetFingerprint: routingAssessment.targetFingerprint,
            clarification
          },
          revisionId: null,
          simulationResult: null,
          events: [],
          autosaveStatus: "INELIGIBLE",
          workerJobs: [],
          playerMessage,
          rulesetVersion: RULESET_VERSION
        });

        await tx.saveTurnRequest({
          playerId: request.playerId,
          runId: request.runId,
          saveSlotId: request.saveSlotId,
          clientTurnId: request.clientTurnId,
          requestHash,
          status: response.status,
          responsePayload: response
        });

        return response;
      });
    }
  };
}
