import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { buildArtifacts } from "./artifacts.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const generatedDir = path.resolve(__dirname, "../generated");
const { jsonSchemaDocument, openApiDocument } = buildArtifacts();

await fs.mkdir(generatedDir, { recursive: true });
await fs.writeFile(
  path.join(generatedDir, "json-schemas.json"),
  `${JSON.stringify(jsonSchemaDocument, null, 2)}\n`,
  "utf8"
);
await fs.writeFile(
  path.join(generatedDir, "openapi.json"),
  `${JSON.stringify(openApiDocument, null, 2)}\n`,
  "utf8"
);

console.log("Generated contracts artifacts.");
