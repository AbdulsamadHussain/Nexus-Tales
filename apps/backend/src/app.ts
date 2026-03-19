import Fastify from "fastify";

import { registerHealthRoutes } from "./routes/health.js";
import { registerTurnRoutes } from "./routes/turns.js";

export function buildApp() {
  const app = Fastify({
    logger: true
  });

  app.register(registerHealthRoutes);
  app.register(registerTurnRoutes);

  return app;
}

