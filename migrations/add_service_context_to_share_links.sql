-- Migration: Add service_id and cmdb_item_id to share_links table
-- This allows filtering external_item_positions by the viewing service
-- Date: 2026-05-05

-- Add columns to track which service/CMDB item is being shared
ALTER TABLE share_links
ADD COLUMN IF NOT EXISTS service_id INTEGER,
ADD COLUMN IF NOT EXISTS cmdb_item_id INTEGER;

-- Add foreign key constraints
ALTER TABLE share_links
ADD CONSTRAINT fk_service
FOREIGN KEY (service_id)
REFERENCES services(id)
ON DELETE SET NULL;

ALTER TABLE share_links
ADD CONSTRAINT fk_cmdb_item
FOREIGN KEY (cmdb_item_id)
REFERENCES cmdb_items(id)
ON DELETE SET NULL;

-- Add index for faster lookups
CREATE INDEX IF NOT EXISTS idx_share_links_service_id ON share_links(service_id);
CREATE INDEX IF NOT EXISTS idx_share_links_cmdb_item_id ON share_links(cmdb_item_id);

-- Add comment for documentation
COMMENT ON COLUMN share_links.service_id IS 'ID of the service being shared (for filtering external_item_positions)';
COMMENT ON COLUMN share_links.cmdb_item_id IS 'ID of the CMDB item being shared';
