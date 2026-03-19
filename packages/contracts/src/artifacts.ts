import { z } from "zod";

import {
  CONTRACTS_VERSION,
  ContractSchemas,
  PERSISTENCE_SCHEMA_VERSION,
  RULESET_VERSION
} from "./index.js";

export function buildArtifacts() {
  const schemaEntries = Object.entries(ContractSchemas).map(([name, schema]) => [
    name,
    z.toJSONSchema(schema)
  ]);

  const jsonSchemaDocument = {
    $schema: "https://json-schema.org/draft/2020-12/schema",
    title: "Nexus Tales Contracts",
    contractsVersion: CONTRACTS_VERSION,
    rulesetVersion: RULESET_VERSION,
    persistenceSchemaVersion: PERSISTENCE_SCHEMA_VERSION,
    schemas: Object.fromEntries(schemaEntries)
  };

  const openApiDocument = {
    openapi: "3.1.0",
    info: {
      title: "Nexus Tales API",
      version: CONTRACTS_VERSION,
      description: "Generated from the shared contracts package."
    },
    paths: {
      "/v1/health": {
        get: {
          summary: "Health check",
          responses: {
            "200": {
              description: "Healthy"
            }
          }
        }
      },
      "/v1/turns": {
        post: {
          summary: "Submit a player turn",
          requestBody: {
            required: true,
            content: {
              "application/json": {
                schema: {
                  $ref: "#/components/schemas/TurnRequest"
                }
              }
            }
          },
          responses: {
            "200": {
              description: "Turn intake response",
              content: {
                "application/json": {
                  schema: {
                    $ref: "#/components/schemas/TurnAuthoritativeResponse"
                  }
                }
              }
            },
            "400": {
              description: "Invalid request payload",
              content: {
                "application/json": {
                  schema: {
                    $ref: "#/components/schemas/ErrorResponse"
                  }
                }
              }
            },
            "409": {
              description: "Idempotency conflict",
              content: {
                "application/json": {
                  schema: {
                    $ref: "#/components/schemas/ErrorResponse"
                  }
                }
              }
            }
          }
        }
      },
      "/v1/saves/manual": {
        post: {
          summary: "Create a manual save from the active authoritative revision",
          requestBody: {
            required: true,
            content: {
              "application/json": {
                schema: {
                  $ref: "#/components/schemas/ManualSaveRequest"
                }
              }
            }
          },
          responses: {
            "200": {
              description: "Manual save created",
              content: {
                "application/json": {
                  schema: {
                    $ref: "#/components/schemas/ManualSaveResponse"
                  }
                }
              }
            },
            "400": {
              description: "Invalid request payload",
              content: {
                "application/json": {
                  schema: {
                    $ref: "#/components/schemas/ErrorResponse"
                  }
                }
              }
            }
          }
        }
      },
      "/v1/saves/rollback": {
        post: {
          summary: "Restore a revision, checkpoint, or saved snapshot into the active save slot",
          requestBody: {
            required: true,
            content: {
              "application/json": {
                schema: {
                  $ref: "#/components/schemas/RollbackRequest"
                }
              }
            }
          },
          responses: {
            "200": {
              description: "Rollback committed",
              content: {
                "application/json": {
                  schema: {
                    $ref: "#/components/schemas/RollbackResponse"
                  }
                }
              }
            },
            "400": {
              description: "Invalid request payload",
              content: {
                "application/json": {
                  schema: {
                    $ref: "#/components/schemas/ErrorResponse"
                  }
                }
              }
            },
            "404": {
              description: "Requested rollback target not found",
              content: {
                "application/json": {
                  schema: {
                    $ref: "#/components/schemas/ErrorResponse"
                  }
                }
              }
            },
            "422": {
              description: "Save migration failed safely",
              content: {
                "application/json": {
                  schema: {
                    $ref: "#/components/schemas/ErrorResponse"
                  }
                }
              }
            }
          }
        }
      },
      "/v1/runs/{runId}/save-slots/{saveSlotId}/history": {
        get: {
          summary: "List revision history, manual saves, autosaves, and checkpoints",
          parameters: [
            {
              name: "runId",
              in: "path",
              required: true,
              schema: {
                type: "string"
              }
            },
            {
              name: "saveSlotId",
              in: "path",
              required: true,
              schema: {
                type: "string"
              }
            },
            {
              name: "playerId",
              in: "query",
              required: true,
              schema: {
                type: "string"
              }
            }
          ],
          responses: {
            "200": {
              description: "History loaded",
              content: {
                "application/json": {
                  schema: {
                    $ref: "#/components/schemas/RevisionHistoryResponse"
                  }
                }
              }
            },
            "400": {
              description: "Invalid request payload",
              content: {
                "application/json": {
                  schema: {
                    $ref: "#/components/schemas/ErrorResponse"
                  }
                }
              }
            }
          }
        }
      }
    },
    components: {
      schemas: Object.fromEntries(schemaEntries)
    }
  };

  return {
    jsonSchemaDocument,
    openApiDocument
  };
}
