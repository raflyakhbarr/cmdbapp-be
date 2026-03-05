const pool = require('../db');
const fs = require('fs');
const path = require('path');

async function runMigration() {
  const client = await pool.connect();

  try {
    console.log('Starting migration: Add alias and port to cmdb_items...');

    // Read the SQL file
    const sqlPath = path.join(__dirname, 'add_alias_port_to_cmdb_items.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');

    // Execute the migration
    await client.query(sql);

    console.log('✅ Migration completed successfully!');
    console.log('Added columns: alias, port');
  } catch (err) {
    console.error('❌ Migration failed:', err);
    throw err;
  } finally {
    client.release();
    await pool.end();
  }
}

// Run the migration
runMigration()
  .then(() => {
    console.log('Migration process finished.');
    process.exit(0);
  })
  .catch((err) => {
    console.error('Migration process failed:', err);
    process.exit(1);
  });
