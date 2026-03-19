import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { buildArtifacts } from "./artifacts.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const generatedDir = path.resolve(__dirname, "../generated");
const jsonSchemaPath = path.join(generatedDir, "json-schemas.json");
const openApiPath = path.join(generatedDir, "openapi.json");

const { jsonSchemaDocument, openApiDocument } = buildArtifacts();

const expectedJsonSchemas = `${JSON.stringify(jsonSchemaDocument, null, 2)}\n`;
const expectedOpenApi = `${JSON.stringify(openApiDocument, null, 2)}\n`;

const [currentJsonSchemas, currentOpenApi] = await Promise.all([
  fs.readFile(jsonSchemaPath, "utf8"),
  fs.readFile(openApiPath, "utf8")
]);

if (currentJsonSchemas !== expectedJsonSchemas || currentOpenApi !== expectedOpenApi) {
  console.error("Generated contract artifacts are stale. Run npm run generate:contracts.");
  process.exit(1);
}

console.log("Generated contract artifacts are current.");
