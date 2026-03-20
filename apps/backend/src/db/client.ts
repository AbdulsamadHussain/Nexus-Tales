import { Pool } from "pg";
import { drizzle } from "drizzle-orm/node-postgres";

import { env } from "../config/env.js";
import * as schema from "./schema.js";

function createDbInstance() {
  const pool = new Pool({
    connectionString: env.DATABASE_URL
  });

  return drizzle(pool, { schema });
}

export const db = createDbInstance();

export function createDb() {
  return createDbInstance();
}

