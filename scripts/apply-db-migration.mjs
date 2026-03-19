import fs from "node:fs/promises";
import path from "node:path";

import pg from "pg";

function parseDotEnv(content) {
  const values = {};

  for (const rawLine of content.split(/\r?\n/)) {
    const line = rawLine.trim();

    if (!line || line.startsWith("#")) {
      continue;
    }

    const separatorIndex = line.indexOf("=");

    if (separatorIndex <= 0) {
      continue;
    }

    const key = line.slice(0, separatorIndex).trim();
    let value = line.slice(separatorIndex + 1).trim();

    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }

    values[key] = value;
  }

  return values;
}

async function loadEnv(workspaceRoot) {
  const envPath = path.resolve(workspaceRoot, ".env");
  const envContents = await fs.readFile(envPath, "utf8");

  return parseDotEnv(envContents);
}

async function loadStatements(workspaceRoot) {
  const migrationPath = path.resolve(
    workspaceRoot,
    "apps/backend/drizzle/0000_sticky_violations.sql"
  );
  const sql = await fs.readFile(migrationPath, "utf8");

  return sql
    .split("--> statement-breakpoint")
    .map((statement) => statement.trim())
    .filter(Boolean);
}

async function main() {
  const workspaceRoot = process.cwd();
  const env = await loadEnv(workspaceRoot);
  const connectionString = process.env.DATABASE_URL ?? env.DATABASE_URL;

  if (!connectionString) {
    throw new Error("DATABASE_URL is not set.");
  }

  const statements = await loadStatements(workspaceRoot);
  const client = new pg.Client({
    connectionString,
    ssl: {
      rejectUnauthorized: false
    }
  });

  await client.connect();

  try {
    await client.query("begin");

    for (const statement of statements) {
      await client.query(statement);
    }

    await client.query("commit");
    console.log(`Applied ${statements.length} migration statements.`);
  } catch (error) {
    await client.query("rollback").catch(() => undefined);
    throw error;
  } finally {
    await client.end();
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
