import { z } from "zod";

const EnvSchema = z.object({
  DATABASE_URL: z.string().url().or(z.string().startsWith("postgres://")),
  PORT: z.coerce.number().int().positive().default(3000),
  SUPABASE_URL: z.string().url().optional(),
  SUPABASE_ANON_KEY: z.string().optional()
});

export const env = EnvSchema.parse({
  DATABASE_URL:
    process.env.DATABASE_URL ?? "postgres://postgres:postgres@localhost:5432/nexus_tales",
  PORT: process.env.PORT ?? "3000",
  SUPABASE_URL: process.env.SUPABASE_URL,
  SUPABASE_ANON_KEY: process.env.SUPABASE_ANON_KEY
});

