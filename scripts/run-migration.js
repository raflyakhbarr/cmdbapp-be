const fs = require('fs');
const path = require('path');
const pool = require('../db');

async function runMigration() {
  const client = await pool.connect();

  try {
    console.log('Starting migration: create_service_edge_handles');

    // Read migration file
    const migrationPath = path.join(__dirname, '../migrations/create_service_edge_handles.sql');
    const sql = fs.readFileSync(migrationPath, 'utf8');

    console.log('Executing SQL...');
    await client.query(sql);

    console.log('✅ Migration completed successfully!');
    console.log('Table "service_edge_handles" has been created.');
  } catch (err) {
    console.error('❌ Migration failed:', err.message);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

runMigration();
