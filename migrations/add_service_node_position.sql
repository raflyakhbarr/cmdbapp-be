-- Migration: Add position and dimensions to services table
-- Date: 2026-04-23
-- Description: Enable services to be independent ReactFlow nodes with position and size

-- Add workspace_id column first (needed for independent services)
ALTER TABLE services
ADD COLUMN IF NOT EXISTS workspace_id integer;

-- Set workspace_id from parent cmdb_item for existing records
UPDATE services s
SET workspace_id = (
  SELECT workspace_id FROM cmdb_items WHERE id = s.cmdb_item_id
)
WHERE workspace_id IS NULL;

-- Make workspace_id NOT NULL after setting values
ALTER TABLE services
ALTER COLUMN workspace_id SET NOT NULL;

-- Add position column (JSONB type for x, y coordinates)
ALTER TABLE services
ADD COLUMN IF NOT EXISTS position jsonb DEFAULT '{"x": 0, "y": 0}'::jsonb;

-- Add width and height columns for node dimensions
ALTER TABLE services
ADD COLUMN IF NOT EXISTS width integer DEFAULT 120;

ALTER TABLE services
ADD COLUMN IF NOT EXISTS height integer DEFAULT 80;

-- Add column to track if service is expanded (showing service items)
ALTER TABLE services
ADD COLUMN IF NOT EXISTS is_expanded boolean DEFAULT false;

-- Add foreign key constraint to workspaces
ALTER TABLE services
ADD CONSTRAINT fk_services_workspace
FOREIGN KEY (workspace_id) REFERENCES workspaces(id) ON DELETE CASCADE;

-- Add index for faster queries on workspace_id + cmdb_item_id
CREATE INDEX IF NOT EXISTS idx_services_workspace_item
ON services(workspace_id, cmdb_item_id);

-- Add index for workspace_id only
CREATE INDEX IF NOT EXISTS idx_services_workspace
ON services(workspace_id);

-- Add comments
COMMENT ON COLUMN services.workspace_id IS 'Workspace ID (inherited from parent cmdb_item)';
COMMENT ON COLUMN services.position IS 'Node position in ReactFlow {x, y}';
COMMENT ON COLUMN services.width IS 'Node width in pixels';
COMMENT ON COLUMN services.height IS 'Node height in pixels';
COMMENT ON COLUMN services.is_expanded IS 'Whether the service node is expanded to show service items';
