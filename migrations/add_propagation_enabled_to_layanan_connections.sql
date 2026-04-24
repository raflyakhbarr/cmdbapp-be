-- Migration: Add propagation_enabled column to layanan_connections table
-- This allows layana ↔ service connections to optionally disable status propagation

-- Add propagation_enabled column with default value true
ALTER TABLE layanan_connections
ADD COLUMN IF NOT EXISTS propagation_enabled BOOLEAN DEFAULT true NOT NULL;

-- Add index for faster queries on propagation_enabled
CREATE INDEX IF NOT EXISTS idx_layanan_conn_propagation
ON layanan_connections(propagation_enabled);

-- Add comment
COMMENT ON COLUMN layanan_connections.propagation_enabled IS 'Enable status propagation from source to target. When true, status changes propagate through the connection.';

-- Update existing records to have propagation_enabled = true
UPDATE layanan_connections
SET propagation_enabled = true
WHERE propagation_enabled IS NULL;

-- Migration completed successfully
