-- Migration: Add Layanan Service Connections Feature
-- This allows layanan nodes to connect to specific service items within CMDB items
-- with status propagation from service item to layanan node

-- 1. Create layanan_service_connections table
CREATE TABLE IF NOT EXISTS layanan_service_connections (
    id SERIAL PRIMARY KEY,
    layanan_id INTEGER NOT NULL,
    service_id INTEGER NOT NULL,
    service_item_id INTEGER NOT NULL,
    workspace_id INTEGER NOT NULL,
    connection_type VARCHAR(50) DEFAULT 'depends_on',
    propagation_enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Foreign keys
    CONSTRAINT fk_layanan_service_layanan FOREIGN KEY (layanan_id)
        REFERENCES layanan(id) ON DELETE CASCADE,
    CONSTRAINT fk_layanan_service_service FOREIGN KEY (service_id)
        REFERENCES services(id) ON DELETE CASCADE,
    CONSTRAINT fk_layanan_service_service_item FOREIGN KEY (service_item_id)
        REFERENCES service_items(id) ON DELETE CASCADE,
    CONSTRAINT fk_layanan_service_workspace FOREIGN KEY (workspace_id)
        REFERENCES workspaces(id) ON DELETE CASCADE,

    -- Ensure unique connection per layanan-service_item combination
    UNIQUE (layanan_id, service_item_id)
);

-- 2. Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_layanan_service_conn_layanan ON layanan_service_connections(layanan_id);
CREATE INDEX IF NOT EXISTS idx_layanan_service_conn_service ON layanan_service_connections(service_id);
CREATE INDEX IF NOT EXISTS idx_layanan_service_conn_service_item ON layanan_service_connections(service_item_id);
CREATE INDEX IF NOT EXISTS idx_layanan_service_conn_workspace ON layanan_service_connections(workspace_id);

-- 3. Add trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_layanan_service_conn_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_layanan_service_conn_updated_at ON layanan_service_connections;
CREATE TRIGGER update_layanan_service_conn_updated_at
    BEFORE UPDATE ON layanan_service_connections
    FOR EACH ROW
    EXECUTE FUNCTION update_layanan_service_conn_updated_at();

-- Migration completed successfully
