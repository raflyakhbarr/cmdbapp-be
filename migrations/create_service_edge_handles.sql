-- Create table for service edge handles
CREATE TABLE IF NOT EXISTS service_edge_handles (
  id SERIAL PRIMARY KEY,
  edge_id VARCHAR(255) UNIQUE NOT NULL,
  source_handle VARCHAR(50) NOT NULL,
  target_handle VARCHAR(50) NOT NULL,
  service_id INTEGER NOT NULL,
  workspace_id INTEGER NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_service_edge_handles_service_workspace
  ON service_edge_handles(service_id, workspace_id);

-- Create index for edge_id lookups
CREATE INDEX IF NOT EXISTS idx_service_edge_handles_edge_id
  ON service_edge_handles(edge_id);

-- Add comment
COMMENT ON TABLE service_edge_handles IS 'Stores handle positions (top, bottom, left, right) for service item connections';
COMMENT ON COLUMN service_edge_handles.edge_id IS 'Unique identifier for the edge (format: e{source_id}-{target_id})';
COMMENT ON COLUMN service_edge_handles.source_handle IS 'Source handle position (source-top, source-right, source-bottom, source-left)';
COMMENT ON COLUMN service_edge_handles.target_handle IS 'Target handle position (target-top, target-right, target-bottom, target-left)';
