require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });

const { Pool } = require('pg');

const pool = new Pool({
  host: String(process.env.DB_HOST),
  port: parseInt(process.env.DB_PORT),
  user: String(process.env.DB_USER),
  password: String(process.env.DB_PASSWORD),
  database: String(process.env.DB_NAME),
});

async function verifyConnectionData() {
  const client = await pool.connect();

  try {
    // Test the exact query that the backend uses
    const result = await client.query(`
      SELECT * FROM connections
      WHERE workspace_id = 10
      LIMIT 5
    `);

    console.log('\n=== Raw connection data from workspace 10 ===');
    if (result.rows.length === 0) {
      console.log('No connections found');
    } else {
      result.rows.forEach(row => {
        console.log('\nConnection ID:', row.id);
        console.log('  source_id:', row.source_id);
        console.log('  target_id:', row.target_id);
        console.log('  connection_type:', row.connection_type);
        console.log('  direction:', row.direction);
        console.log('  workspace_id:', row.workspace_id);
        console.log('  All columns:', Object.keys(row));
      });
    }

  } catch (err) {
    console.error('Error:', err.message);
  } finally {
    client.release();
    await pool.end();
  }
}

verifyConnectionData();
