import Fastify from "fastify";

import { registerHealthRoutes } from "./routes/health.js";
import { registerTurnRoutes } from "./routes/turns.js";
import { createInMemoryTurnIntakeRepository } from "./turns/in-memory-repository.js";
import {
  createTurnIntakeService,
  type TurnFeatureFlags,
  type TurnIntakeService
} from "./turns/service.js";

export interface BuildAppOptions {
  turnIntakeService?: TurnIntakeService;
  featureFlags?: Partial<TurnFeatureFlags>;
}

export function buildApp(options: BuildAppOptions = {}) {
  const app = Fastify({
    logger: true
  });
  const turnIntakeService =
    options.turnIntakeService ??
    createTurnIntakeService({
      repository: createInMemoryTurnIntakeRepository(),
      featureFlags: options.featureFlags
    });

  app.register(registerHealthRoutes);
  app.register(registerTurnRoutes, {
    turnIntakeService
  });

  return app;
}
