const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  port: 5432,
  user: 'postgres',
  password: '123111',
  database: 'cmdb_db'
});

async function fixForeignKey() {
  const client = await pool.connect();
  try {
    console.log('🔌 Connected to database');

    // Drop the problematic foreign key constraint on source_id
    console.log('\n🔧 Dropping fk_service_group_conn_source constraint...');
    await client.query(`
      ALTER TABLE service_group_connections
      DROP CONSTRAINT IF EXISTS fk_service_group_conn_source;
    `);
    console.log('✅ Dropped fk_service_group_conn_source');

    // Drop the old target_id constraint that points to service_groups
    console.log('\n🔧 Dropping fk_sgc_target_group constraint (old target_id → service_groups)...');
    await client.query(`
      ALTER TABLE service_group_connections
      DROP CONSTRAINT IF EXISTS fk_sgc_target_group;
    `);
    console.log('✅ Dropped fk_sgc_target_group');

    // Create proper foreign keys for each column
    console.log('\n🔧 Creating proper foreign key for target_item_id → service_items...');
    await client.query(`
      ALTER TABLE service_group_connections
      ADD CONSTRAINT fk_sgc_target_item_item
      FOREIGN KEY (target_item_id)
      REFERENCES service_items(id)
      ON DELETE CASCADE;
    `);
    console.log('✅ Created fk_sgc_target_item_item');

    console.log('\n🔧 Creating proper foreign key for target_group_id → service_groups...');
    await client.query(`
      ALTER TABLE service_group_connections
      ADD CONSTRAINT fk_sgc_target_group_group
      FOREIGN KEY (target_group_id)
      REFERENCES service_groups(id)
      ON DELETE CASCADE;
    `);
    console.log('✅ Created fk_sgc_target_group_group');

    console.log('\n🔧 Creating proper foreign key for source_group_id → service_groups...');
    await client.query(`
      ALTER TABLE service_group_connections
      ADD CONSTRAINT fk_sgc_source_group
      FOREIGN KEY (source_group_id)
      REFERENCES service_groups(id)
      ON DELETE CASCADE;
    `);
    console.log('✅ Created fk_sgc_source_group');

    // Verify all foreign keys
    console.log('\n📊 Verifying foreign keys...');
    const result = await client.query(`
      SELECT
        tc.constraint_name,
        kcu.column_name,
        ccu.table_name AS foreign_table_name,
        ccu.column_name AS foreign_column_name
      FROM information_schema.table_constraints AS tc
      JOIN information_schema.key_column_usage AS kcu
        ON tc.constraint_name = kcu.constraint_name
      JOIN information_schema.constraint_column_usage AS ccu
        ON ccu.constraint_name = tc.constraint_name
      WHERE tc.table_name = 'service_group_connections'
        AND tc.constraint_type = 'FOREIGN KEY'
        AND kcu.column_name IN ('source_id', 'source_group_id', 'target_id', 'target_item_id', 'target_group_id')
      ORDER BY tc.constraint_name, kcu.ordinal_position
    `);

    console.log('\n📋 Current Foreign Keys for connection columns:');
    result.rows.forEach(row => {
      console.log(`  ${row.constraint_name}`);
      console.log(`    ${row.column_name} → ${row.foreign_table_name}.${row.foreign_column_name}`);
    });

    console.log('\n✅ Fix completed successfully!');
    console.log('\n📝 Notes:');
    console.log('  - source_id has NO foreign key (can be item or group)');
    console.log('  - source_group_id → service_groups.id');
    console.log('  - target_id → service_groups.id (for group-to-group)');
    console.log('  - target_item_id → service_items.id');
    console.log('  - target_group_id → service_groups.id');

  } catch (err) {
    console.error('❌ Error:', err.message);
    console.error(err.stack);
  } finally {
    await client.end();
    console.log('\n🔌 Connection closed');
    process.exit(0);
  }
}

fixForeignKey();
