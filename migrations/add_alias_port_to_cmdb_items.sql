-- Migration: Add alias and port columns to cmdb_items
-- Date: 2026-03-05
-- Description: Add alias and port fields for IP address configuration

-- Add alias column
ALTER TABLE cmdb_items
ADD COLUMN IF NOT EXISTS alias VARCHAR(255);

-- Add port column
ALTER TABLE cmdb_items
ADD COLUMN IF NOT EXISTS port INTEGER;

-- Add comments for documentation
COMMENT ON COLUMN cmdb_items.alias IS 'Alias name for the IP address or host';
COMMENT ON COLUMN cmdb_items.port IS 'Port number for the service or application';

-- Create index on alias for faster searches
CREATE INDEX IF NOT EXISTS idx_cmdb_items_alias ON cmdb_items(alias);

-- Create index on port for filtering
CREATE INDEX IF NOT EXISTS idx_cmdb_items_port ON cmdb_items(port);
