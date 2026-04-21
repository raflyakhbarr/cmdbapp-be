-- Migration: Add Layanan Feature to CMDB
-- Layanan (Business Service) adalah entitas baru yang levelnya sama dengan CMDB Items
-- Bisa dikoneksikan dengan CMDB Items dan Layanan lainnya di ReactFlow canvas

-- 1. Create layanan table
CREATE TABLE IF NOT EXISTS layanan (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    status VARCHAR(30) DEFAULT 'active',
    position JSONB DEFAULT '{"x": 0, "y": 0}'::jsonb,
    workspace_id INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_layanan_workspace FOREIGN KEY (workspace_id)
        REFERENCES workspaces(id) ON DELETE CASCADE
);

-- 2. Create layanan_connections table for connections between layanan and cmdb items or other layanan
CREATE TABLE IF NOT EXISTS layanan_connections (
    id SERIAL PRIMARY KEY,
    source_type VARCHAR(20) NOT NULL, -- 'layanan' or 'cmdb'
    source_id INTEGER NOT NULL,
    target_type VARCHAR(20) NOT NULL, -- 'layanan' or 'cmdb'
    target_id INTEGER NOT NULL,
    workspace_id INTEGER NOT NULL,
    connection_type VARCHAR(50) DEFAULT 'connects_to',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_layanan_conn_workspace FOREIGN KEY (workspace_id)
        REFERENCES workspaces(id) ON DELETE CASCADE
);

-- 3. Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_layanan_workspace ON layanan(workspace_id);
CREATE INDEX IF NOT EXISTS idx_layanan_status ON layanan(status);
CREATE INDEX IF NOT EXISTS idx_layanan_conn_workspace ON layanan_connections(workspace_id);
CREATE INDEX IF NOT EXISTS idx_layanan_conn_source ON layanan_connections(source_type, source_id);
CREATE INDEX IF NOT EXISTS idx_layanan_conn_target ON layanan_connections(target_type, target_id);

-- Migration completed successfully
