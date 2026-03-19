import Fastify from "fastify";

import { registerHealthRoutes } from "./routes/health.js";
import { registerSaveRoutes } from "./routes/saves.js";
import { registerTurnRoutes } from "./routes/turns.js";
import {
  createSaveManagementService,
  type SaveManagementConfig,
  type SaveManagementService
} from "./saves/service.js";
import { createInMemoryTurnIntakeRepository } from "./turns/in-memory-repository.js";
import {
  createTurnIntakeService,
  type TurnFeatureFlags,
  type TurnIntakeService
} from "./turns/service.js";
import type { TurnIntakeRepository } from "./turns/repository.js";
import type { InitialCanonicalStateProvider } from "./turns/state.js";

export interface BuildAppOptions {
  repository?: TurnIntakeRepository;
  turnIntakeService?: TurnIntakeService;
  saveManagementService?: SaveManagementService;
  saveManagementConfig?: SaveManagementConfig;
  featureFlags?: Partial<TurnFeatureFlags>;
  initialCanonicalStateProvider?: InitialCanonicalStateProvider;
}

export function buildApp(options: BuildAppOptions = {}) {
  const app = Fastify({
    logger: true
  });
  const repository = options.repository ?? createInMemoryTurnIntakeRepository();
  const turnIntakeService =
    options.turnIntakeService ??
    createTurnIntakeService({
      repository,
      featureFlags: options.featureFlags,
      initialCanonicalStateProvider: options.initialCanonicalStateProvider
    });
  const saveManagementService =
    options.saveManagementService ??
    createSaveManagementService({
      repository,
      config: {
        autosaveRingSize: options.saveManagementConfig?.autosaveRingSize ?? 5,
        manualSaveLimit: options.saveManagementConfig?.manualSaveLimit ?? 12
      }
    });

  app.register(registerHealthRoutes);
  app.register(registerTurnRoutes, {
    turnIntakeService
  });
  app.register(registerSaveRoutes, {
    saveManagementService
  });

  return app;
}
