// One-off database migration runner.
// Runs as an ECS task from the CD pipeline, BEFORE the new backend is deployed.
//
// Applies any new SQL files from ./migrations, in filename order, and records
// each one in the schema_migrations table so it only ever runs once.
// Connects with the same database credential the backend uses.
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { Pool } = require('pg');
const { loadDbConfig } = require('./db');

const MIGRATIONS_DIR = path.join(__dirname, 'migrations');
const LOCK_ID = 727274; // arbitrary constant: stops two migration runs overlapping

function readMigration(file) {
  // Normalise line endings so the checksum is the same on Windows and Linux checkouts.
  const sql = fs.readFileSync(path.join(MIGRATIONS_DIR, file), 'utf8').replace(/\r\n/g, '\n');
  const checksum = crypto.createHash('sha256').update(sql).digest('hex');
  return { sql, checksum };
}

async function applyMigrations(client) {
  await client.query(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      filename   VARCHAR(255) PRIMARY KEY,
      checksum   CHAR(64) NOT NULL,
      applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  `);

  const files = fs.readdirSync(MIGRATIONS_DIR).filter((f) => f.endsWith('.sql')).sort();
  const { rows } = await client.query('SELECT filename, checksum FROM schema_migrations');
  const applied = new Map(rows.map((r) => [r.filename, r.checksum]));

  let appliedNow = 0;
  for (const file of files) {
    const { sql, checksum } = readMigration(file);

    if (applied.has(file)) {
      if (applied.get(file) !== checksum) {
        throw new Error(`${file} was changed after it was applied. Never edit an applied migration - add a new one.`);
      }
      console.log(`skip    ${file}`);
      continue;
    }

    console.log(`apply   ${file}`);
    await client.query('BEGIN');
    try {
      await client.query(sql);
      await client.query('INSERT INTO schema_migrations (filename, checksum) VALUES ($1, $2)', [file, checksum]);
      await client.query('COMMIT');
    } catch (error) {
      await client.query('ROLLBACK');
      throw new Error(`${file} failed: ${error.message}`);
    }
    appliedNow += 1;
  }

  console.log(`${appliedNow} migration(s) applied, ${files.length - appliedNow} already up to date.`);
}

async function main() {
  const dbConfig = process.env.DATABASE_URL
    ? { connectionString: process.env.DATABASE_URL }
    : await loadDbConfig(process.env.DB_CREDENTIALS_SSM_NAME);

  const pool = new Pool({ ...dbConfig, max: 1 });
  const client = await pool.connect();

  try {
    await client.query('SELECT pg_advisory_lock($1)', [LOCK_ID]);
    await applyMigrations(client);
  } finally {
    await client.query('SELECT pg_advisory_unlock($1)', [LOCK_ID]).catch(() => {});
    client.release();
    await pool.end();
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(`Migration failed: ${error.message}`);
    process.exit(1);
  });