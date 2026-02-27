require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });

const { Pool } = require('pg');

const pool = new Pool({
  host: String(process.env.DB_HOST),
  port: parseInt(process.env.DB_PORT),
  user: String(process.env.DB_USER),
  password: String(process.env.DB_PASSWORD),
  database: String(process.env.DB_NAME),
});

async function checkSchema() {
  const client = await pool.connect();

  try {
    // Check if connection_type column exists
    const columnCheck = await client.query(`
      SELECT column_name, data_type, column_default
      FROM information_schema.columns
      WHERE table_name = 'connections'
      AND column_name IN ('connection_type', 'direction')
    `);

    console.log('\n=== New columns in connections table ===');
    columnCheck.rows.forEach(row => {
      console.log(`${row.column_name}: ${row.data_type} (default: ${row.column_default})`);
    });

    // Check if connection_type_definitions table exists
    const tableCheck = await client.query(`
      SELECT table_name
      FROM information_schema.tables
      WHERE table_name = 'connection_type_definitions'
    `);

    console.log('\n=== Connection type definitions table ===');
    console.log(tableCheck.rows.length > 0 ? '✓ Table exists' : '✗ Table not found');

    // Get connection type definitions
    const typeDefs = await client.query(`
      SELECT type_slug, label, description, default_direction, color
      FROM connection_type_definitions
      ORDER BY id
    `);

    console.log('\n=== Connection type definitions ===');
    typeDefs.rows.forEach(row => {
      console.log(`  ${row.type_slug}: ${row.label} (${row.default_direction}) - ${row.color}`);
    });

  } catch (err) {
    console.error('Error checking schema:', err.message);
  } finally {
    client.release();
    await pool.end();
  }
}

checkSchema();
