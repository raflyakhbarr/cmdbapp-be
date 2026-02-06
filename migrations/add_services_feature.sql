-- Migration: Add Services Feature to CMDB
-- This migration replaces the images column with a structured services system
-- Each CMDB item can have multiple services, and each service has its own canvas

-- 1. Create services table
CREATE TABLE IF NOT EXISTS services (
    id SERIAL PRIMARY KEY,
    cmdb_item_id INTEGER NOT NULL,
    name VARCHAR(100) NOT NULL,
    status VARCHAR(30) DEFAULT 'active',
    icon_type VARCHAR(20) DEFAULT 'preset', -- 'preset' or 'upload'
    icon_path VARCHAR(255), -- for uploaded icons
    icon_name VARCHAR(50), -- for preset icons (e.g., 'citrix', 'oracle')
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_services_cmdb_item FOREIGN KEY (cmdb_item_id)
        REFERENCES cmdb_items(id) ON DELETE CASCADE
);

-- 2. Create service_items table for service canvas
CREATE TABLE IF NOT EXISTS service_items (
    id SERIAL PRIMARY KEY,
    service_id INTEGER NOT NULL,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50),
    description TEXT,
    position JSONB DEFAULT '{"x": 0, "y": 0}'::jsonb,
    status VARCHAR(30) DEFAULT 'active',
    ip VARCHAR(45),
    category VARCHAR(12),
    location VARCHAR(50),
    workspace_id INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_service_items_service FOREIGN KEY (service_id)
        REFERENCES services(id) ON DELETE CASCADE,
    CONSTRAINT fk_service_items_workspace FOREIGN KEY (workspace_id)
        REFERENCES workspaces(id) ON DELETE CASCADE
);

-- 3. Create service_connections table
CREATE TABLE IF NOT EXISTS service_connections (
    id SERIAL PRIMARY KEY,
    service_id INTEGER NOT NULL,
    source_id INTEGER NOT NULL,
    target_id INTEGER NOT NULL,
    workspace_id INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_service_conn_service FOREIGN KEY (service_id)
        REFERENCES services(id) ON DELETE CASCADE,
    CONSTRAINT fk_service_conn_source FOREIGN KEY (source_id)
        REFERENCES service_items(id) ON DELETE CASCADE,
    CONSTRAINT fk_service_conn_target FOREIGN KEY (target_id)
        REFERENCES service_items(id) ON DELETE CASCADE,
    CONSTRAINT fk_service_conn_workspace FOREIGN KEY (workspace_id)
        REFERENCES workspaces(id) ON DELETE CASCADE,
    CONSTRAINT unique_service_connection UNIQUE (service_id, source_id, target_id)
);

-- 4. Drop images column from cmdb_items (no migration - starting fresh)
ALTER TABLE cmdb_items DROP COLUMN IF EXISTS images;

-- 5. Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_services_cmdb_item ON services(cmdb_item_id);
CREATE INDEX IF NOT EXISTS idx_services_status ON services(status);
CREATE INDEX IF NOT EXISTS idx_service_items_service ON service_items(service_id);
CREATE INDEX IF NOT EXISTS idx_service_items_workspace ON service_items(workspace_id);
CREATE INDEX IF NOT EXISTS idx_service_conn_service ON service_connections(service_id);
CREATE INDEX IF NOT EXISTS idx_service_conn_workspace ON service_connections(workspace_id);

-- Migration completed successfully
