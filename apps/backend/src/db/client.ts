import { Pool } from "pg";
import { drizzle } from "drizzle-orm/node-postgres";

import { env } from "../config/env.js";
import * as schema from "./schema.js";

export function createDb() {
  const pool = new Pool({
    connectionString: env.DATABASE_URL
  });

  return drizzle(pool, { schema });
}

