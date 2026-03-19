import type { FastifyInstance } from "fastify";

import {
  RULESET_VERSION,
  TurnAuthoritativeResponseSchema,
  TurnRequestSchema
} from "@nexus-tales/contracts";

export async function registerTurnRoutes(app: FastifyInstance) {
  app.post("/v1/turns", async (request, reply) => {
    const parsed = TurnRequestSchema.safeParse(request.body);

    if (!parsed.success) {
      request.log.warn(
        {
          eventName: "contracts.turn_request_invalid",
          issues: parsed.error.issues
        },
        "Rejected invalid turn request."
      );

      return reply.status(400).send({
        message: "Invalid turn request payload.",
        issues: parsed.error.issues
      });
    }

    const now = new Date().toISOString();
    const { clientTurnId, inputText, playerId, runId, saveSlotId } = parsed.data;

    const mockResponse = TurnAuthoritativeResponseSchema.parse({
      status: "ACCEPTED",
      decision: "ALLOW",
      routeCategory: "NO_ROLL_DETERMINISTIC",
      revisionId: `rev_mock_${clientTurnId}`,
      simulationResult: {
        rulesetVersion: RULESET_VERSION,
        successTier: "FULL_SUCCESS",
        roll: null,
        stateDelta: {
          mocked: true,
          echoedInput: inputText
        },
        events: [
          {
            eventType: "TURN_ACCEPTED",
            entityId: playerId,
            occurredAt: now,
            metadata: {
              runId,
              saveSlotId
            }
          }
        ],
        summaryFlags: []
      },
      events: [
        {
          eventType: "TURN_ACCEPTED",
          entityId: playerId,
          occurredAt: now,
          metadata: {
            runId,
            saveSlotId
          }
        }
      ],
      autosaveStatus: "ELIGIBLE",
      workerJobs: [
        {
          jobType: "NARRATION",
          jobId: `job_narration_${clientTurnId}`,
          uniquenessKey: `narration:rev_mock_${clientTurnId}`,
          status: "QUEUED"
        },
        {
          jobType: "SUMMARY",
          jobId: `job_summary_${clientTurnId}`,
          uniquenessKey: `summary:rev_mock_${clientTurnId}`,
          status: "QUEUED"
        }
      ],
      playerMessage: "Phase 0 mock authoritative response.",
      rulesetVersion: RULESET_VERSION
    });

    request.log.info(
      {
        eventName: "phase0.turn_mock_accepted",
        routeCategory: mockResponse.routeCategory,
        revisionId: mockResponse.revisionId,
        playerId,
        runId,
        saveSlotId
      },
      "Returned mocked authoritative turn response."
    );

    return reply.status(200).send(mockResponse);
  });
}

