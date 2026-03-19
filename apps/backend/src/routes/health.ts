import type { FastifyInstance } from "fastify";

export async function registerHealthRoutes(app: FastifyInstance) {
  app.get("/", async () => ({
    status: "ok",
    service: "nexus-tales-backend",
    endpoints: {
      health: "/v1/health",
      turns: "/v1/turns"
    }
  }));

  app.get("/v1/health", async () => ({
    status: "ok"
  }));
}
