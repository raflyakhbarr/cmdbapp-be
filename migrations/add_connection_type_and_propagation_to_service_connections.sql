-- Add connection_type and propagation columns to service_connections table
-- This allows service items to have typed connections with propagation rules like CMDB items

-- Add connection_type column with default 'connects_to'
ALTER TABLE service_connections
ADD COLUMN IF NOT EXISTS connection_type connection_type_enum DEFAULT 'connects_to';

-- Add propagation column with default 'source_to_target'
ALTER TABLE service_connections
ADD COLUMN IF NOT EXISTS propagation VARCHAR(20) DEFAULT 'source_to_target'
CHECK (propagation IN ('source_to_target', 'target_to_source', 'both'));

-- Add updated_at column if not exists
ALTER TABLE service_connections
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- Add index for better query performance
CREATE INDEX IF NOT EXISTS idx_service_connections_type
ON service_connections(connection_type);

-- Add comments for documentation
COMMENT ON COLUMN service_connections.connection_type IS 'Type of relationship between service items';
COMMENT ON COLUMN service_connections.propagation IS 'Status propagation direction: source_to_target (source affects target), target_to_source (target affects source), both (bidirectional)';
COMMENT ON COLUMN service_connections.updated_at IS 'Last update timestamp for the connection';
