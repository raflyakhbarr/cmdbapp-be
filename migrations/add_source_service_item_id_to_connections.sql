-- Migration: Add source_service_item_id support to connections table
-- This allows service items to be the source of connections

-- 1. Add source_service_item_id column
ALTER TABLE connections ADD COLUMN source_service_item_id INTEGER;

-- 2. Add foreign key constraint
ALTER TABLE connections ADD CONSTRAINT connections_source_service_item_id_fkey
    FOREIGN KEY (source_service_item_id) REFERENCES service_items(id) ON DELETE CASCADE;

-- 3. Drop the old check_source_exists constraint
ALTER TABLE connections DROP CONSTRAINT check_source_exists;

-- 4. Add the updated check_source_exists constraint that allows source_service_item_id
ALTER TABLE connections ADD CONSTRAINT check_source_exists CHECK (
    ((source_id IS NOT NULL) AND (source_group_id IS NULL) AND (source_service_id IS NULL) AND (source_service_item_id IS NULL)) OR
    ((source_group_id IS NOT NULL) AND (source_id IS NULL) AND (source_service_id IS NULL) AND (source_service_item_id IS NULL)) OR
    ((source_service_id IS NOT NULL) AND (source_id IS NULL) AND (source_group_id IS NULL) AND (source_service_item_id IS NULL)) OR
    ((source_service_item_id IS NOT NULL) AND (source_id IS NULL) AND (source_group_id IS NULL) AND (source_service_id IS NULL))
);

-- 5. Create index for better query performance
CREATE INDEX idx_connections_source_service_item_id ON connections(source_service_item_id) WHERE source_service_item_id IS NOT NULL;

-- Migration completed successfully
