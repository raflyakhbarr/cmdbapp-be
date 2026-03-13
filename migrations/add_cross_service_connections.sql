-- Migration: Add Cross-Service Connections
-- Menambahkan koneksi antar service item dari berbagai CMDB items

-- 1. Create table for cross-service connections
CREATE TABLE IF NOT EXISTS cross_service_connections (
    id SERIAL PRIMARY KEY,
    source_service_item_id INTEGER NOT NULL,
    target_service_item_id INTEGER NOT NULL,
    workspace_id INTEGER NOT NULL,
    connection_type connection_type_enum DEFAULT 'connects_to',
    direction VARCHAR(20) DEFAULT 'forward',
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT cross_service_unique_connection UNIQUE (source_service_item_id, target_service_item_id),
    CONSTRAINT cross_service_source_exists FOREIGN KEY (source_service_item_id) REFERENCES service_items(id) ON DELETE CASCADE,
    CONSTRAINT cross_service_target_exists FOREIGN KEY (target_service_item_id) REFERENCES service_items(id) ON DELETE CASCADE,
    CONSTRAINT cross_service_not_same CHECK (source_service_item_id != target_service_item_id)
);

-- 2. Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_cross_service_source ON cross_service_connections(source_service_item_id);
CREATE INDEX IF NOT EXISTS idx_cross_service_target ON cross_service_connections(target_service_item_id);
CREATE INDEX IF NOT EXISTS idx_cross_service_workspace ON cross_service_connections(workspace_id);
CREATE INDEX IF NOT EXISTS idx_cross_service_type ON cross_service_connections(connection_type);

-- 3. Add comments for documentation
COMMENT ON TABLE cross_service_connections IS 'Connections between service items from different CMDB items';
COMMENT ON COLUMN cross_service_connections.source_service_item_id IS 'Source service item ID';
COMMENT ON COLUMN cross_service_connections.target_service_item_id IS 'Target service item ID';
COMMENT ON COLUMN cross_service_connections.connection_type IS 'Type of relationship (uses connection_type_enum)';
COMMENT ON COLUMN cross_service_connections.direction IS 'Direction: forward, backward, or bidirectional';

-- 4. Create trigger for updated_at
CREATE OR REPLACE FUNCTION update_cross_service_connections_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_cross_service_connections_updated_at
    BEFORE UPDATE ON cross_service_connections
    FOR EACH ROW
    EXECUTE FUNCTION update_cross_service_connections_updated_at();
