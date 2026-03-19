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
              description: "Authoritative turn response",
              content: {
                "application/json": {
                  schema: {
                    $ref: "#/components/schemas/TurnAuthoritativeResponse"
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

