-- Migration: Add target_service_id and target_service_item_id columns to connections table
-- This allows CMDB items to connect to services and service items

-- 1. First, drop the foreign key constraint on target_id
ALTER TABLE connections DROP CONSTRAINT IF EXISTS connections_target_id_fkey;

-- 2. Add the new columns
ALTER TABLE connections
ADD COLUMN IF NOT EXISTS target_service_id INTEGER,
ADD COLUMN IF NOT EXISTS target_service_item_id INTEGER;

-- 3. Modify the check constraint to allow target_id = null when target_service_id or target_service_item_id is set
ALTER TABLE connections DROP CONSTRAINT IF EXISTS check_target;

ALTER TABLE connections ADD CONSTRAINT check_target CHECK (
  (
    (source_id IS NOT NULL AND source_group_id IS NULL) OR
    (source_id IS NULL AND source_group_id IS NOT NULL)
  ) AND
  (
    (target_id IS NOT NULL AND target_group_id IS NULL AND target_service_id IS NULL AND target_service_item_id IS NULL) OR
    (target_id IS NULL AND target_group_id IS NOT NULL AND target_service_id IS NULL AND target_service_item_id IS NULL) OR
    (target_id IS NULL AND target_group_id IS NULL AND target_service_id IS NOT NULL) OR
    (target_id IS NULL AND target_group_id IS NULL AND target_service_item_id IS NOT NULL)
  )
);

-- 4. Add foreign key back for target_id (now with ON DELETE SET NULL)
ALTER TABLE connections
ADD CONSTRAINT connections_target_id_fkey
FOREIGN KEY (target_id) REFERENCES cmdb_items(id) ON DELETE SET NULL;

-- 5. Add comments for documentation
COMMENT ON COLUMN connections.target_service_id IS 'Stores the target service ID when source is a CMDB item and target is a service';
COMMENT ON COLUMN connections.target_service_item_id IS 'Stores the target service item ID when source is a CMDB item and target is a service item';

-- 6. Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_connections_target_service ON connections(target_service_id) WHERE target_service_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_connections_target_service_item ON connections(target_service_item_id) WHERE target_service_item_id IS NOT NULL;