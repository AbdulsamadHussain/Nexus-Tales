import type { FastifyInstance, FastifyReply, FastifyRequest } from "fastify";

import {
  ErrorResponseSchema,
  ManualSaveRequestSchema,
  RevisionHistoryRequestSchema,
  RollbackRequestSchema
} from "@nexus-tales/contracts";

import {
  SaveManagementError,
  type SaveManagementService
} from "../saves/service.js";

type RegisterSaveRoutesOptions = {
  saveManagementService: SaveManagementService;
};

function sendValidationError(
  request: FastifyRequest,
  reply: FastifyReply,
  code: string,
  message: string,
  issues: unknown
) {
  request.log.warn(
    {
      eventName: "saves.request_invalid",
      code,
      issues
    },
    message
  );

  return reply.status(400).send(
    ErrorResponseSchema.parse({
      code,
      message,
      details: {
        issues
      }
    })
  );
}

export async function registerSaveRoutes(
  app: FastifyInstance,
  options: RegisterSaveRoutesOptions
) {
  app.get("/v1/runs/:runId/save-slots/:saveSlotId/history", async (request, reply) => {
    const parsed = RevisionHistoryRequestSchema.safeParse({
      playerId: (request.query as { playerId?: unknown } | undefined)?.playerId,
      runId: (request.params as { runId?: unknown } | undefined)?.runId,
      saveSlotId: (request.params as { saveSlotId?: unknown } | undefined)?.saveSlotId
    });

    if (!parsed.success) {
      return sendValidationError(
        request,
        reply,
        "INVALID_SAVE_HISTORY_REQUEST",
        "Invalid save history request.",
        parsed.error.issues
      );
    }

    try {
      const response = await options.saveManagementService.getHistory(parsed.data);
      return reply.status(200).send(response);
    } catch (error) {
      if (error instanceof SaveManagementError) {
        return reply.status(error.statusCode).send(
          ErrorResponseSchema.parse({
            code: error.code,
            message: error.message,
            details: error.details
          })
        );
      }

      throw error;
    }
  });

  app.post("/v1/saves/manual", async (request, reply) => {
    const parsed = ManualSaveRequestSchema.safeParse(request.body);

    if (!parsed.success) {
      return sendValidationError(
        request,
        reply,
        "INVALID_MANUAL_SAVE_REQUEST",
        "Invalid manual save request.",
        parsed.error.issues
      );
    }

    try {
      const response = await options.saveManagementService.createManualSave(parsed.data);
      return reply.status(200).send(response);
    } catch (error) {
      if (error instanceof SaveManagementError) {
        return reply.status(error.statusCode).send(
          ErrorResponseSchema.parse({
            code: error.code,
            message: error.message,
            details: error.details
          })
        );
      }

      throw error;
    }
  });

  app.post("/v1/saves/rollback", async (request, reply) => {
    const parsed = RollbackRequestSchema.safeParse(request.body);

    if (!parsed.success) {
      return sendValidationError(
        request,
        reply,
        "INVALID_ROLLBACK_REQUEST",
        "Invalid rollback request.",
        parsed.error.issues
      );
    }

    try {
      const response = await options.saveManagementService.rollback(parsed.data);
      return reply.status(200).send(response);
    } catch (error) {
      if (error instanceof SaveManagementError) {
        return reply.status(error.statusCode).send(
          ErrorResponseSchema.parse({
            code: error.code,
            message: error.message,
            details: error.details
          })
        );
      }

      throw error;
    }
  });
}
