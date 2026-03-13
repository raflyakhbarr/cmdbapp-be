-- Migration: Add External Item Positions and Cross-Service Edge Handles
-- Menambahkan tracking posisi external items dan edge handles untuk cross-service connections

-- 1. Create table for external service item positions per workspace
CREATE TABLE IF NOT EXISTS external_item_positions (
    id SERIAL PRIMARY KEY,
    workspace_id INTEGER NOT NULL,
    service_id INTEGER NOT NULL,
    external_service_item_id INTEGER NOT NULL,
    position JSONB NOT NULL DEFAULT '{"x": 0, "y": 0}',
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT external_item_unique UNIQUE (workspace_id, service_id, external_service_item_id),
    CONSTRAINT external_item_position_service_fk FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE,
    CONSTRAINT external_item_position_item_fk FOREIGN KEY (external_service_item_id) REFERENCES service_items(id) ON DELETE CASCADE
);

-- 2. Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_external_item_positions_workspace ON external_item_positions(workspace_id);
CREATE INDEX IF NOT EXISTS idx_external_item_positions_service ON external_item_positions(service_id);
CREATE INDEX IF NOT EXISTS idx_external_item_positions_item ON external_item_positions(external_service_item_id);

-- 3. Create table for cross-service edge handles
CREATE TABLE IF NOT EXISTS cross_service_edge_handles (
    id SERIAL PRIMARY KEY,
    edge_id VARCHAR(255) NOT NULL,
    source_service_id INTEGER NOT NULL,
    target_service_id INTEGER NOT NULL,
    source_handle VARCHAR(50) NOT NULL DEFAULT 'source-right',
    target_handle VARCHAR(50) NOT NULL DEFAULT 'target-left',
    workspace_id INTEGER NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT cross_edge_unique UNIQUE (edge_id, source_service_id, target_service_id)
);

-- 4. Create index for edge handles
CREATE INDEX IF NOT EXISTS idx_cross_service_edge_handles_edge ON cross_service_edge_handles(edge_id);
CREATE INDEX IF NOT EXISTS idx_cross_service_edge_handles_workspace ON cross_service_edge_handles(workspace_id);

-- 5. Add comments for documentation
COMMENT ON TABLE external_item_positions IS 'Stores custom positions for external service items in each service visualization';
COMMENT ON COLUMN external_item_positions.position IS 'Position coordinates {x, y} for the external item';
COMMENT ON TABLE cross_service_edge_handles IS 'Stores edge handle positions for cross-service connections';
COMMENT ON COLUMN cross_service_edge_handles.source_handle IS 'Source handle position (source-right, source-bottom, etc.)';
COMMENT ON COLUMN cross_service_edge_handles.target_handle IS 'Target handle position (target-left, target-top, etc.)';

-- 6. Create trigger for updated_at on external_item_positions
CREATE OR REPLACE FUNCTION update_external_item_positions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_external_item_positions_updated_at
    BEFORE UPDATE ON external_item_positions
    FOR EACH ROW
    EXECUTE FUNCTION update_external_item_positions_updated_at();

-- 7. Create trigger for updated_at on cross_service_edge_handles
CREATE OR REPLACE FUNCTION update_cross_service_edge_handles_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_cross_service_edge_handles_updated_at
    BEFORE UPDATE ON cross_service_edge_handles
    FOR EACH ROW
    EXECUTE FUNCTION update_cross_service_edge_handles_updated_at();
