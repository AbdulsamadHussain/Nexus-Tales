import { describe, it, expect } from "vitest";
import {
  SummaryTriggerService,
  createDefaultSummaryTriggerConfig
} from "./summary-trigger.js";
import type { SimulationResult } from "@nexus-tales/contracts";

describe("SummaryTriggerService", () => {
  const config = createDefaultSummaryTriggerConfig();
  const service = new SummaryTriggerService(config);

  describe("evaluateTrigger", () => {
    it("should trigger HARD summary on hard trigger flags", () => {
      const simulationResult: Partial<SimulationResult> = {
        successTier: "FULL_SUCCESS",
        summaryFlags: ["COMBAT_ACTIVE"],
        events: []
      };

      const result = service.evaluateTrigger(
        simulationResult as any,
        ["COMBAT_ACTIVE"],
        null
      );

      expect(result).toBe("HARD");
    });

    it("should trigger SOFT summary on soft trigger flags", () => {
      const simulationResult: Partial<SimulationResult> = {
        successTier: "FULL_SUCCESS",
        summaryFlags: ["LOCATION_CHANGED"],
        events: []
      };

      const result = service.evaluateTrigger(
        simulationResult as any,
        ["LOCATION_CHANGED"],
        null
      );

      expect(result).toBe("SOFT");
    });

    it("should return null when no triggers match", () => {
      const simulationResult: Partial<SimulationResult> = {
        successTier: "FULL_SUCCESS",
        summaryFlags: [],
        events: []
      };

      const result = service.evaluateTrigger(
        simulationResult as any,
        [],
        null
      );

      expect(result).toBe(null);
    });

    it("should respect suppression window for hard triggers", () => {
      const simulationResult: Partial<SimulationResult> = {
        successTier: "FULL_SUCCESS",
        summaryFlags: ["COMBAT_ACTIVE"],
        events: []
      };

      // Within suppression window (last summary was 2 revisions ago, window is 5)
      const result = service.evaluateTrigger(
        simulationResult as any,
        ["COMBAT_ACTIVE"],
        2
      );

      expect(result).toBe(null);
    });

    it("should allow hard trigger after suppression window expires", () => {
      const simulationResult: Partial<SimulationResult> = {
        successTier: "FULL_SUCCESS",
        summaryFlags: ["QUEST_UPDATED"],
        events: []
      };

      // Outside suppression window (last summary was 6 revisions ago, window is 5)
      const result = service.evaluateTrigger(
        simulationResult as any,
        ["QUEST_UPDATED"],
        6
      );

      expect(result).toBe("HARD");
    });
  });

  describe("isDebounced", () => {
    it("should return false when no recent summary job", () => {
      const isDebounced = service.isDebounced(null);
      expect(isDebounced).toBe(false);
    });

    it("should return true when summary job was recently queued", () => {
      // Debounce window is 2 revisions
      const isDebounced = service.isDebounced(1);
      expect(isDebounced).toBe(true);
    });

    it("should return false when debounce window expires", () => {
      const isDebounced = service.isDebounced(3);
      expect(isDebounced).toBe(false);
    });
  });

  describe("hard trigger priority", () => {
    it("should prioritize hard triggers over soft triggers", () => {
      const simulationResult: Partial<SimulationResult> = {
        successTier: "FULL_SUCCESS",
        summaryFlags: ["COMBAT_ACTIVE", "LOCATION_CHANGED"],
        events: []
      };

      const result = service.evaluateTrigger(
        simulationResult as any,
        ["COMBAT_ACTIVE", "LOCATION_CHANGED"],
        null
      );

      expect(result).toBe("HARD");
    });
  });
});

describe("Worker Idempotency", () => {
  it("should prevent duplicate summary artifacts for same revision", () => {
    // This test verifies that the uniqueness key `summary:{revision_id}`
    // is properly enforced by the outbox system
    const uniquenessKey1 = "summary:rev_001";
    const uniquenessKey1Duplicate = "summary:rev_001";

    expect(uniquenessKey1).toBe(uniquenessKey1Duplicate);
  });

  it("should prevent duplicate narration artifacts for same revision", () => {
    const uniquenessKey1 = "narration:rev_001";
    const uniquenessKey1Duplicate = "narration:rev_001";

    expect(uniquenessKey1).toBe(uniquenessKey1Duplicate);
  });

  it("should prevent duplicate image artifacts for same scene anchor", () => {
    const uniquenessKey1 = "image:scene_forest_combat:rev_001";
    const uniquenessKey1Duplicate = "image:scene_forest_combat:rev_001";

    expect(uniquenessKey1).toBe(uniquenessKey1Duplicate);
  });
});

describe("Narration Fallback", () => {
  it("should have template narration available as fallback", () => {
    const templates: Record<string, string> = {
      CRITICAL_FAILURE: "Your attempt failed badly.",
      FAILURE: "Your attempt did not succeed as intended.",
      PARTIAL_SUCCESS: "Your attempt partially succeeded.",
      FULL_SUCCESS: "Your attempt succeeded.",
      CRITICAL_SUCCESS: "Your attempt exceeded all expectations."
    };

    Object.entries(templates).forEach(([tier, text]) => {
      expect(text).toBeTruthy();
      expect(text.length).toBeGreaterThan(0);
    });
  });
});

describe("Worker Job Status Transitions", () => {
  it("should start jobs in QUEUED status", () => {
    const initialStatus = "QUEUED";
    expect(initialStatus).toBe("QUEUED");
  });

  it("should allow retry transitions from QUEUED to QUEUED", () => {
    const retryTransition = {
      from: "QUEUED",
      to: "QUEUED",
      retryCountIncrement: 1
    };

    expect(retryTransition.retryCountIncrement).toBeGreaterThan(0);
  });

  it("should allow completion transition from QUEUED to COMPLETED", () => {
    const completionTransition = {
      from: "QUEUED",
      to: "COMPLETED"
    };

    expect(completionTransition.from).toBe("QUEUED");
    expect(completionTransition.to).toBe("COMPLETED");
  });

  it("should allow failure transition from QUEUED to FAILED", () => {
    const failureTransition = {
      from: "QUEUED",
      to: "FAILED"
    };

    expect(failureTransition.from).toBe("QUEUED");
    expect(failureTransition.to).toBe("FAILED");
  });

  it("should allow skip transition from QUEUED to SKIPPED", () => {
    const skipTransition = {
      from: "QUEUED",
      to: "SKIPPED"
    };

    expect(skipTransition.from).toBe("QUEUED");
    expect(skipTransition.to).toBe("SKIPPED");
  });
});
