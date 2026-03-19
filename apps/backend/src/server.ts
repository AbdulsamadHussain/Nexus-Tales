import { env } from "./config/env.js";
import { buildApp } from "./app.js";
import { createPgTurnIntakeRepository } from "./turns/pg-repository.js";
import { createTurnIntakeService } from "./turns/service.js";

const repository = createPgTurnIntakeRepository();
const app = buildApp({
  turnIntakeService: createTurnIntakeService({
    repository,
    featureFlags: {
      parserAssistanceEnabled: env.ENABLE_PARSER_ASSISTANCE
    }
  })
});

app.addHook("onClose", async () => {
  await repository.close?.();
});

try {
  await app.listen({
    port: env.PORT,
    host: "0.0.0.0"
  });
} catch (error) {
  app.log.error(error, "Failed to start backend.");
  process.exit(1);
}
