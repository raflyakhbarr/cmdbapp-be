const { Client } = require('pg');

const dbConfig = {
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME
};

const migrationSQL = `
-- Create service_groups table
CREATE TABLE IF NOT EXISTS service_groups (
    id SERIAL PRIMARY KEY,
    service_id INTEGER NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    color VARCHAR(7) DEFAULT '#e0e7ff',
    position JSONB,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
    workspace_id INTEGER NOT NULL,
    CONSTRAINT fk_service_groups_service FOREIGN KEY (service_id)
        REFERENCES services(id) ON DELETE CASCADE,
    CONSTRAINT fk_service_groups_workspace FOREIGN KEY (workspace_id)
        REFERENCES workspaces(id) ON DELETE CASCADE
);

-- Add group_id and order_in_group columns to service_items
ALTER TABLE service_items
ADD COLUMN IF NOT EXISTS group_id INTEGER,
ADD COLUMN IF NOT EXISTS order_in_group INTEGER DEFAULT 0;

-- Add foreign key constraint for group_id
ALTER TABLE service_items
ADD CONSTRAINT fk_service_items_group FOREIGN KEY (group_id)
    REFERENCES service_groups(id) ON DELETE SET NULL;

-- Create service_group_connections table
CREATE TABLE IF NOT EXISTS service_group_connections (
    id SERIAL PRIMARY KEY,
    service_id INTEGER NOT NULL,
    source_id INTEGER,
    target_id INTEGER,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
    workspace_id INTEGER NOT NULL,
    source_group_id INTEGER,
    target_group_id INTEGER,
    CONSTRAINT fk_service_group_conn_service FOREIGN KEY (service_id)
        REFERENCES services(id) ON DELETE CASCADE,
    CONSTRAINT fk_service_group_conn_workspace FOREIGN KEY (workspace_id)
        REFERENCES workspaces(id) ON DELETE CASCADE,
    CONSTRAINT fk_service_group_conn_source_group FOREIGN KEY (source_id)
        REFERENCES service_groups(id) ON DELETE CASCADE,
    CONSTRAINT fk_service_group_conn_target_group FOREIGN KEY (target_id)
        REFERENCES service_groups(id) ON DELETE CASCADE,
    CONSTRAINT fk_service_group_conn_source_group_2 FOREIGN KEY (source_group_id)
        REFERENCES service_groups(id) ON DELETE CASCADE,
    CONSTRAINT fk_service_group_conn_target_group_2 FOREIGN KEY (target_group_id)
        REFERENCES service_groups(id) ON DELETE CASCADE,
    CONSTRAINT fk_service_group_conn_target_item FOREIGN KEY (target_id)
        REFERENCES service_items(id) ON DELETE CASCADE,
    CONSTRAINT check_service_group_source EXISTS CHECK (
        ((source_id IS NOT NULL) AND (source_group_id IS NULL)) OR
        ((source_id IS NULL) AND (source_group_id IS NOT NULL))
    ),
    CONSTRAINT check_service_group_target_correct CHECK (
        (target_id IS NOT NULL AND target_group_id IS NULL) OR
        (target_id IS NULL AND target_group_id IS NOT NULL) OR
        (target_id IS NULL AND target_group_id IS NULL)
    ),
    CONSTRAINT unique_service_group_connection UNIQUE (service_id, source_id, target_id, source_group_id, target_group_id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_service_groups_service ON service_groups(service_id);
CREATE INDEX IF NOT EXISTS idx_service_groups_workspace ON service_groups(workspace_id);
CREATE INDEX IF NOT EXISTS idx_service_items_group_order ON service_items(group_id, order_in_group);
CREATE INDEX IF NOT EXISTS idx_service_group_conn_service ON service_group_connections(service_id);
CREATE INDEX IF NOT EXISTS idx_service_group_conn_workspace ON service_group_connections(workspace_id);
CREATE INDEX IF NOT EXISTS idx_service_group_conn_source ON service_group_connections(source_id);
CREATE INDEX IF NOT EXISTS idx_service_group_conn_target ON service_group_connections(target_id);
CREATE INDEX IF NOT EXISTS idx_service_group_conn_source_group ON service_group_connections(source_group_id);
CREATE INDEX IF NOT EXISTS idx_service_group_conn_target_group ON service_group_connections(target_group_id);
`;

async function runMigration() {
  const client = new Client(dbConfig);

  try {
    console.log('Connecting to database...');
    await client.connect();
    console.log('Connected to database');

    console.log('Starting service group migration...');
    await client.query(migrationSQL);
    console.log('Service group migration completed successfully!');

    // Verify tables were created
    const result = await client.query(`
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = 'public'
      AND table_name IN ('service_groups', 'service_group_connections')
      ORDER BY table_name;
    `);

    console.log('\nService group tables created:');
    if (result.rows.length === 0) {
      console.log('  (Tables may already exist)');
    } else {
      result.rows.forEach(row => {
        console.log(`  - ${row.table_name}`);
      });
    }

    // Check columns were added to service_items
    const columns = await client.query(`
      SELECT column_name, data_type
      FROM information_schema.columns
      WHERE table_name = 'service_items'
      AND column_name IN ('group_id', 'order_in_group')
      ORDER BY column_name;
    `);

    console.log('\nColumns added to service_items table:');
    if (columns.rows.length === 0) {
      console.log('  (Columns may already exist)');
    } else {
      columns.rows.forEach(row => {
        console.log(`  - ${row.column_name} (${row.data_type})`);
      });
    }

  } catch (error) {
    console.error('Migration failed:', error.message);
    console.error(error);
    process.exit(1);
  } finally {
    await client.end();
    console.log('\nDatabase connection closed');
  }
}

runMigration();
