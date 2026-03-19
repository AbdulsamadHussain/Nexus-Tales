import type { FastifyInstance } from "fastify";

import {
  ErrorResponseSchema,
  TurnRequestSchema
} from "@nexus-tales/contracts";

import {
  IdempotencyConflictError,
  type TurnIntakeService
} from "../turns/service.js";

type RegisterTurnRoutesOptions = {
  turnIntakeService: TurnIntakeService;
};

export async function registerTurnRoutes(
  app: FastifyInstance,
  options: RegisterTurnRoutesOptions
) {
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

      const errorResponse = ErrorResponseSchema.parse({
        code: "INVALID_TURN_REQUEST",
        message: "Invalid turn request payload.",
        details: {
          issues: parsed.error.issues
        }
      });

      return reply.status(400).send(errorResponse);
    }

    try {
      const response = await options.turnIntakeService.handleTurn(parsed.data);

      request.log.info(
        {
          eventName: "turns.authoritative_response_ready",
          status: response.status,
          decision: response.decision,
          policyFlags: response.policy.policyFlags,
          narrationConstraints: response.policy.narrationConstraints,
          routeCategory: response.routeCategory,
          revisionId: response.revisionId,
          playerId: parsed.data.playerId,
          runId: parsed.data.runId,
          saveSlotId: parsed.data.saveSlotId,
          clientTurnId: parsed.data.clientTurnId
        },
        "Resolved turn request."
      );

      return reply.status(200).send(response);
    } catch (error) {
      if (error instanceof IdempotencyConflictError) {
        request.log.warn(
          {
            eventName: "turns.idempotency_conflict",
            playerId: parsed.data.playerId,
            runId: parsed.data.runId,
            saveSlotId: parsed.data.saveSlotId,
            clientTurnId: parsed.data.clientTurnId
          },
          error.message
        );

        const errorResponse = ErrorResponseSchema.parse({
          code: "TURN_IDEMPOTENCY_CONFLICT",
          message: error.message,
          details: {
            playerId: parsed.data.playerId,
            runId: parsed.data.runId,
            saveSlotId: parsed.data.saveSlotId,
            clientTurnId: parsed.data.clientTurnId
          }
        });

        return reply.status(409).send(errorResponse);
      }

      request.log.error(
        {
          eventName: "turns.intake_unhandled_error",
          error
        },
        "Unhandled turn intake error."
      );

      throw error;
    }
  });
}
