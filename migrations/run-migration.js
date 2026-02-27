const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const { Pool } = require('pg');

// Create pool with explicit string conversion
const pool = new Pool({
  host: String(process.env.DB_HOST),
  port: parseInt(process.env.DB_PORT),
  user: String(process.env.DB_USER),
  password: String(process.env.DB_PASSWORD),
  database: String(process.env.DB_NAME),
});

async function runMigration() {
  const client = await pool.connect();

  try {
    console.log('Running migration: add_connection_types.sql');

    // Read the migration file
    const migrationPath = path.join(__dirname, 'add_connection_types.sql');
    const migrationSQL = fs.readFileSync(migrationPath, 'utf8');

    // Execute the migration
    await client.query(migrationSQL);

    console.log('Migration completed successfully!');
  } catch (err) {
    console.error('Migration failed:', err.message);
    console.error('Details:', err);
  } finally {
    client.release();
    await pool.end();
  }
}

runMigration();
