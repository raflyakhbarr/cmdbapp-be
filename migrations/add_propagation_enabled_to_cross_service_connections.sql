-- Migration: Add propagation_enabled to cross_service_connections
-- Menambahkan field propagation_enabled untuk mengontrol apakah status harus di-propagate melalui koneksi ini

-- Add propagation_enabled column
ALTER TABLE cross_service_connections ADD COLUMN IF NOT EXISTS propagation_enabled BOOLEAN DEFAULT true;

-- Add comment for documentation
COMMENT ON COLUMN cross_service_connections.propagation_enabled IS 'Enable/disable status propagation through this connection (default: true)';

-- Update existing records to have propagation_enabled = true
UPDATE cross_service_connections SET propagation_enabled = true WHERE propagation_enabled IS NULL;
