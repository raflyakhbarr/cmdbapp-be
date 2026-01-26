const { Client } = require('pg');

const dbConfig = {
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME
};

const migrationSQL = `
-- Create workspaces table
CREATE TABLE IF NOT EXISTS workspaces (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create cmdb_groups table
CREATE TABLE IF NOT EXISTS cmdb_groups (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    color VARCHAR(7) DEFAULT '#e0e7ff',
    position JSONB,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
    workspace_id INTEGER NOT NULL,
    CONSTRAINT fk_groups_workspace FOREIGN KEY (workspace_id) 
        REFERENCES workspaces(id) ON DELETE CASCADE
);

-- Create cmdb_items table
CREATE TABLE IF NOT EXISTS cmdb_items (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50),
    description TEXT,
    position JSONB DEFAULT '{"x": 0, "y": 0}'::jsonb,
    status VARCHAR(30) DEFAULT 'active',
    ip VARCHAR(45),
    category VARCHAR(12),
    location VARCHAR(50),
    images JSONB DEFAULT '[]'::jsonb,
    group_id INTEGER,
    order_in_group INTEGER,
    env_type VARCHAR(12),
    workspace_id INTEGER NOT NULL,
    CONSTRAINT fk_items_group FOREIGN KEY (group_id) 
        REFERENCES cmdb_groups(id) ON DELETE SET NULL,
    CONSTRAINT fk_items_workspace FOREIGN KEY (workspace_id) 
        REFERENCES workspaces(id) ON DELETE CASCADE
);

-- Create connections table
CREATE TABLE IF NOT EXISTS connections (
    id SERIAL PRIMARY KEY,
    source_id INTEGER,
    target_id INTEGER,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    target_group_id INTEGER,
    source_group_id INTEGER,
    workspace_id INTEGER NOT NULL,
    CONSTRAINT fk_connections_source FOREIGN KEY (source_id) 
        REFERENCES cmdb_items(id) ON DELETE CASCADE,
    CONSTRAINT fk_connections_target FOREIGN KEY (target_id) 
        REFERENCES cmdb_items(id) ON DELETE CASCADE,
    CONSTRAINT fk_connections_source_group FOREIGN KEY (source_group_id) 
        REFERENCES cmdb_groups(id) ON DELETE CASCADE,
    CONSTRAINT fk_connections_target_group FOREIGN KEY (target_group_id) 
        REFERENCES cmdb_groups(id) ON DELETE CASCADE,
    CONSTRAINT fk_connections_workspace FOREIGN KEY (workspace_id) 
        REFERENCES workspaces(id) ON DELETE CASCADE,
    CONSTRAINT check_source_exists CHECK (
        ((source_id IS NOT NULL) AND (source_group_id IS NULL)) OR 
        ((source_id IS NULL) AND (source_group_id IS NOT NULL))
    ),
    CONSTRAINT check_target CHECK (
        ((target_id IS NOT NULL) AND (target_group_id IS NULL)) OR 
        ((target_id IS NULL) AND (target_group_id IS NOT NULL))
    ),
    CONSTRAINT unique_connection UNIQUE (source_id, target_id)
);

-- Create edge_handles table
CREATE TABLE IF NOT EXISTS edge_handles (
    id SERIAL PRIMARY KEY,
    edge_id VARCHAR(255) NOT NULL UNIQUE,
    source_handle VARCHAR(50) NOT NULL,
    target_handle VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    workspace_id INTEGER NOT NULL,
    CONSTRAINT fk_edge_handles_workspace FOREIGN KEY (workspace_id) 
        REFERENCES workspaces(id) ON DELETE CASCADE
);

-- Create group_connections table
CREATE TABLE IF NOT EXISTS group_connections (
    id SERIAL PRIMARY KEY,
    source_id INTEGER,
    target_id INTEGER,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
    workspace_id INTEGER NOT NULL,
    CONSTRAINT fk_group_connections_source FOREIGN KEY (source_id) 
        REFERENCES cmdb_groups(id) ON DELETE CASCADE,
    CONSTRAINT fk_group_connections_target FOREIGN KEY (target_id) 
        REFERENCES cmdb_groups(id) ON DELETE CASCADE,
    CONSTRAINT fk_group_connections_workspace FOREIGN KEY (workspace_id) 
        REFERENCES workspaces(id) ON DELETE CASCADE,
    CONSTRAINT unique_group_connection UNIQUE (source_id, target_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_cmdb_groups_workspace ON cmdb_groups(workspace_id);
CREATE INDEX IF NOT EXISTS idx_cmdb_items_workspace ON cmdb_items(workspace_id);
CREATE INDEX IF NOT EXISTS idx_cmdb_items_group_order ON cmdb_items(group_id, order_in_group);
CREATE INDEX IF NOT EXISTS idx_cmdb_items_images ON cmdb_items USING gin(images);
CREATE INDEX IF NOT EXISTS idx_connections_workspace ON connections(workspace_id);
CREATE INDEX IF NOT EXISTS idx_connections_source ON connections(source_id);
CREATE INDEX IF NOT EXISTS idx_connections_target ON connections(target_id);
CREATE INDEX IF NOT EXISTS idx_connections_source_group ON connections(source_group_id);
CREATE INDEX IF NOT EXISTS idx_edge_handles_workspace ON edge_handles(workspace_id);
CREATE INDEX IF NOT EXISTS idx_edge_handles_edge_id ON edge_handles(edge_id);
CREATE INDEX IF NOT EXISTS idx_group_connections_workspace ON group_connections(workspace_id);
`;

async function runMigration() {
  const client = new Client(dbConfig);
  
  try {
    console.log('🔌 Connecting to database...');
    await client.connect();
    console.log('✅ Connected to database');
    
    console.log('🚀 Starting migration...');
    await client.query(migrationSQL);
    console.log('✅ Migration completed successfully!');
    
    const result = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_type = 'BASE TABLE'
      ORDER BY table_name;
    `);
    
    console.log('\n📊 Tables created:');
    result.rows.forEach(row => {
      console.log(`  - ${row.table_name}`);
    });
    
  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    console.error(error);
    process.exit(1);
  } finally {
    await client.end();
    console.log('\n🔌 Database connection closed');
  }
}

runMigration();