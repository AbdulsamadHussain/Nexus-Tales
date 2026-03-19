import fs from "node:fs";
import path from "node:path";

const rootDir = process.cwd();
const allowedDir = path.join(rootDir, "packages", "contracts");
const ignoredDirs = new Set([
  ".git",
  "node_modules",
  "dist",
  ".dart_tool",
  "build"
]);
const canonicalSchemaNames = [
  "SafetyDecisionSchema",
  "RouteCategorySchema",
  "ActionPacketSchema",
  "SimulationResultSchema",
  "CanonicalEventSchema",
  "RevisionRecordSchema",
  "SaveSnapshotSchema",
  "SummaryJobSchema",
  "ImageJobSchema",
  "TurnRequestSchema",
  "TurnAuthoritativeResponseSchema"
];

const offenses = [];

function visitDir(dirPath) {
  for (const entry of fs.readdirSync(dirPath, { withFileTypes: true })) {
    if (ignoredDirs.has(entry.name)) {
      continue;
    }

    const fullPath = path.join(dirPath, entry.name);
    if (fullPath.startsWith(allowedDir)) {
      continue;
    }

    if (entry.isDirectory()) {
      visitDir(fullPath);
      continue;
    }

    if (!/\.(ts|tsx|js|mjs|cjs)$/.test(entry.name)) {
      continue;
    }

    const source = fs.readFileSync(fullPath, "utf8");

    for (const schemaName of canonicalSchemaNames) {
      const exportedPattern = new RegExp(`export\\s+const\\s+${schemaName}\\b`);
      const assignedPattern = new RegExp(`\\b${schemaName}\\s*=\\s*z\\.`);

      if (exportedPattern.test(source) || assignedPattern.test(source)) {
        offenses.push(path.relative(rootDir, fullPath));
        break;
      }
    }
  }
}

visitDir(rootDir);

if (offenses.length > 0) {
  console.error("Canonical contract schemas must only exist in packages/contracts.");
  for (const offense of offenses) {
    console.error(` - ${offense}`);
  }
  process.exit(1);
}

console.log("Canonical contract authority check passed.");
