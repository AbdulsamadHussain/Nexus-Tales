import pg from 'pg';
import fs from 'fs';
import path from 'path';

// Parse .env from workspace root
const envPath = 'C:\\Users\\khans\\Nexus-Tales\\.env';
const envContent = fs.readFileSync(envPath, 'utf8');
const DATABASE_URL = envContent.split('\n').find(line => line.startsWith('DATABASE_URL=')).split('=')[1];

const client = new pg.Client({ connectionString: DATABASE_URL, ssl: { rejectUnauthorized: false } });

(async () => {
  try {
    await client.connect();
    console.log('✓ Connected\n');

    // Create save_snapshots
    await client.query(`
      CREATE TABLE IF NOT EXISTS save_snapshots (
        id text PRIMARY KEY NOT NULL,
        revision_id text NOT NULL,
        created_at timestamp with time zone DEFAULT now() NOT NULL
      );
    `);
    console.log('✓ Created save_snapshots');

    // Create migration_records
    await client.query(`
      CREATE TABLE IF NOT EXISTS migration_records (
        id text PRIMARY KEY NOT NULL,
        migration_key text NOT NULL,
        executed_at timestamp with time zone DEFAULT now() NOT NULL,
        CONSTRAINT migration_records_migration_key_unique UNIQUE(migration_key)
      );
    `);
    console.log('✓ Created migration_records\n');

    // Verify all tables
    const res = await client.query(`
      SELECT table_name FROM information_schema.tables 
      WHERE table_schema='public' ORDER BY table_name
    `);
    console.log(`Database has ${res.rows.length} tables:`);
    res.rows.forEach(r => console.log(`  - ${r.table_name}`));

  } catch (e) {
    console.error('ERROR:', e.message);
  } finally {
    await client.end();
  }
})();
