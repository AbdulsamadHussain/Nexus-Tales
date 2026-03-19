import fs from "node:fs";
import path from "node:path";
import { z } from "zod";

function parseDotEnv(content: string) {
  const values: Record<string, string> = {};

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

function loadDotEnv() {
  const candidates = [
    path.resolve(process.cwd(), ".env"),
    path.resolve(process.cwd(), "../../.env"),
    path.resolve(process.cwd(), "../../../.env")
  ];

  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) {
      return parseDotEnv(fs.readFileSync(candidate, "utf8"));
    }
  }

  return {};
}

const fileEnv = loadDotEnv();

const EnvSchema = z.object({
  DATABASE_URL: z.string().url().or(z.string().startsWith("postgres://")),
  PORT: z.coerce.number().int().positive().default(3000),
  ENABLE_PARSER_ASSISTANCE: z
    .enum(["true", "false"])
    .optional()
    .transform((value) => value === "true"),
  SUPABASE_URL: z.string().url().optional(),
  SUPABASE_ANON_KEY: z.string().optional()
});

export const env = EnvSchema.parse({
  DATABASE_URL:
    process.env.DATABASE_URL ??
    fileEnv.DATABASE_URL ??
    "postgres://postgres:postgres@localhost:5432/nexus_tales",
  PORT: process.env.PORT ?? fileEnv.PORT ?? "3000",
  ENABLE_PARSER_ASSISTANCE:
    process.env.ENABLE_PARSER_ASSISTANCE ?? fileEnv.ENABLE_PARSER_ASSISTANCE,
  SUPABASE_URL: process.env.SUPABASE_URL ?? fileEnv.SUPABASE_URL,
  SUPABASE_ANON_KEY: process.env.SUPABASE_ANON_KEY ?? fileEnv.SUPABASE_ANON_KEY
});
