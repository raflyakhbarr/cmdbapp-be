require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });

const { Pool } = require('pg');

const pool = new Pool({
  host: String(process.env.DB_HOST),
  port: parseInt(process.env.DB_PORT),
  user: String(process.env.DB_USER),
  password: String(process.env.DB_PASSWORD),
  database: String(process.env.DB_NAME),
});

async function checkConnections() {
  const client = await pool.connect();

  try {
    // Get workspace test 2
    const workspaces = await client.query(`
      SELECT id, name FROM workspaces
      WHERE name ILIKE '%test 2%' OR id = 2
      LIMIT 5
    `);

    console.log('\n=== Workspaces ===');
    workspaces.rows.forEach(w => {
      console.log(`  ID: ${w.id}, Name: ${w.name}`);
    });

    if (workspaces.rows.length === 0) {
      console.log('No workspace found. Listing all workspaces:');
      const allWorkspaces = await client.query('SELECT id, name FROM workspaces LIMIT 10');
      allWorkspaces.rows.forEach(w => {
        console.log(`  ID: ${w.id}, Name: ${w.name}`);
      });
    }

    // Get connections from workspace 2 (or test 2)
    const workspaceId = workspaces.rows.length > 0 ? workspaces.rows[0].id : 2;

    const connections = await client.query(`
      SELECT c.id, c.source_id, c.target_id, c.connection_type, c.direction, c.workspace_id,
             i1.name as source_name, i2.name as target_name
      FROM connections c
      LEFT JOIN cmdb_items i1 ON c.source_id = i1.id
      LEFT JOIN cmdb_items i2 ON c.target_id = i2.id
      WHERE c.workspace_id = $1
      ORDER BY c.id DESC
      LIMIT 10
    `, [workspaceId]);

    console.log(`\n=== Connections from workspace ID ${workspaceId} ===`);
    if (connections.rows.length === 0) {
      console.log('  No connections found');
    } else {
      connections.rows.forEach(c => {
        console.log(`  ${c.source_name} -> ${c.target_name}`);
        console.log(`    Type: ${c.connection_type}, Direction: ${c.direction}`);
        console.log(`    Source ID: ${c.source_id}, Target ID: ${c.target_id}`);
        console.log('');
      });
    }

  } catch (err) {
    console.error('Error:', err.message);
  } finally {
    client.release();
    await pool.end();
  }
}

checkConnections();
