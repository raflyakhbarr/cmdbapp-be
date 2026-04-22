-- Migration: Service to Service Connections
-- This migration adds support for direct connections between services (not service items)
-- These connections are visualized within the parent CMDB item node

-- Create service_to_service_connections table
CREATE TABLE IF NOT EXISTS service_to_service_connections (
    id SERIAL PRIMARY KEY,
    cmdb_item_id INTEGER NOT NULL,
    source_service_id INTEGER NOT NULL,
    target_service_id INTEGER NOT NULL,
    connection_type connection_type_enum DEFAULT 'connects_to',
    direction VARCHAR(20) DEFAULT 'forward',
    propagation VARCHAR(20) DEFAULT 'source_to_target',
    workspace_id INTEGER NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Foreign Keys
    CONSTRAINT fk_stsc_source_service
        FOREIGN KEY (source_service_id)
        REFERENCES services(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_stsc_target_service
        FOREIGN KEY (target_service_id)
        REFERENCES services(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_stsc_cmdb_item
        FOREIGN KEY (cmdb_item_id)
        REFERENCES cmdb_items(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_stsc_workspace
        FOREIGN KEY (workspace_id)
        REFERENCES workspaces(id)
        ON DELETE CASCADE,

    -- Constraints
    CONSTRAINT no_self_service_connection
        CHECK (source_service_id != target_service_id),

    CONSTRAINT valid_service_direction
        CHECK (direction IN ('forward', 'backward', 'bidirectional')),

    CONSTRAINT valid_service_propagation
        CHECK (propagation IN ('source_to_target', 'target_to_source', 'both'))
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_stsc_cmdb_item ON service_to_service_connections(cmdb_item_id);
CREATE INDEX IF NOT EXISTS idx_stsc_source_service ON service_to_service_connections(source_service_id);
CREATE INDEX IF NOT EXISTS idx_stsc_target_service ON service_to_service_connections(target_service_id);
CREATE INDEX IF NOT EXISTS idx_stsc_workspace ON service_to_service_connections(workspace_id);
CREATE INDEX IF NOT EXISTS idx_stsc_services_pair ON service_to_service_connections(source_service_id, target_service_id);

-- Add comment for documentation
COMMENT ON TABLE service_to_service_connections IS 'Stores direct connections between services within the same CMDB item. These connections are visualized as internal edges within the CMDB item node.';

COMMENT ON COLUMN service_to_service_connections.cmdb_item_id IS 'Parent CMDB item that contains both services';
COMMENT ON COLUMN service_to_service_connections.source_service_id IS 'Source service ID (must belong to cmdb_item_id)';
COMMENT ON COLUMN service_to_service_connections.target_service_id IS 'Target service ID (must belong to cmdb_item_id)';
COMMENT ON COLUMN service_to_service_connections.direction IS 'Connection direction: forward, backward, or bidirectional';
COMMENT ON COLUMN service_to_service_connections.propagation IS 'Status propagation direction: source_to_target, target_to_source, or both';

-- Create trigger for updated_at
CREATE OR REPLACE FUNCTION update_service_to_service_connections_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS service_to_service_connections_updated_at ON service_to_service_connections;
CREATE TRIGGER service_to_service_connections_updated_at
    BEFORE UPDATE ON service_to_service_connections
    FOR EACH ROW
    EXECUTE FUNCTION update_service_to_service_connections_updated_at();

-- ====================================================================
-- NOTE: Service-to-CMDB-Item Validation
-- ====================================================================
-- PostgreSQL does NOT allow subqueries in CHECK constraints.
-- Validation that both services belong to the same cmdb_item_id is done
-- at the application level in:
--   - routes/serviceToServiceConnectionRoutes.js (POST endpoint)
--
-- This ensures data integrity while working within PostgreSQL's limitations.
-- ====================================================================
