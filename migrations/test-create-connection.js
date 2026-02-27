require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });

const { Pool } = require('pg');

const pool = new Pool({
  host: String(process.env.DB_HOST),
  port: parseInt(process.env.DB_PORT),
  user: String(process.env.DB_USER),
  password: String(process.env.DB_PASSWORD),
  database: String(process.env.DB_NAME),
});

async function testCreateConnection() {
  const client = await pool.connect();

  try {
    const workspaceId = 10; // Workspace Test 2

    // Get items from workspace
    const items = await client.query(`
      SELECT id, name FROM cmdb_items
      WHERE workspace_id = $1
      LIMIT 5
    `, [workspaceId]);

    console.log('\n=== Items in Workspace Test 2 ===');
    if (items.rows.length < 2) {
      console.log('Need at least 2 items to create a connection');
      console.log('Found items:', items.rows);
      return;
    }

    items.rows.forEach(i => {
      console.log(`  ID: ${i.id}, Name: ${i.name}`);
    });

    const sourceId = items.rows[0].id;
    const targetId = items.rows[1].id;

    console.log(`\n=== Creating connection: ${items.rows[0].name} -> ${items.rows[1].name} ===`);

    // Create a test connection with consumed_by type
    const result = await client.query(`
      INSERT INTO connections (source_id, target_id, workspace_id, connection_type, direction)
      VALUES ($1, $2, $3, 'consumed_by', 'backward')
      RETURNING *
    `, [sourceId, targetId, workspaceId]);

    console.log('\n✓ Connection created successfully!');
    console.log('Connection details:', result.rows[0]);

    // Verify the connection was created
    const verify = await client.query(`
      SELECT c.id, c.source_id, c.target_id, c.connection_type, c.direction,
             i1.name as source_name, i2.name as target_name
      FROM connections c
      LEFT JOIN cmdb_items i1 ON c.source_id = i1.id
      LEFT JOIN cmdb_items i2 ON c.target_id = i2.id
      WHERE c.id = $1
    `, [result.rows[0].id]);

    console.log('\n=== Verification ===');
    console.log(`  ${verify.rows[0].source_name} -> ${verify.rows[0].target_name}`);
    console.log(`  Type: ${verify.rows[0].connection_type}`);
    console.log(`  Direction: ${verify.rows[0].direction}`);

  } catch (err) {
    console.error('Error:', err.message);
    console.error('Details:', err);
  } finally {
    client.release();
    await pool.end();
  }
}

testCreateConnection();
