-- Migration: Add viewing_service_id to cross_service_edge_handles
-- Purpose: Memungkinkan setiap service visualization memiliki edge handle position sendiri
-- Date: 2026-04-01

-- 1. Add viewing_service_id column
ALTER TABLE cross_service_edge_handles
ADD COLUMN IF NOT EXISTS viewing_service_id INTEGER;

-- 2. Add index untuk query performance
CREATE INDEX IF NOT EXISTS idx_cross_service_edge_handles_viewing_service
ON cross_service_edge_handles(viewing_service_id, workspace_id)
WHERE viewing_service_id IS NOT NULL;

-- 3. Update unique constraint untuk memasukkan viewing_service_id
-- Drop constraint lama jika ada
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'cross_edge_unique'
    ) THEN
        ALTER TABLE cross_service_edge_handles
        DROP CONSTRAINT cross_edge_unique;
    END IF;
END $$;

-- Create unique constraint baru dengan viewing_service_id
ALTER TABLE cross_service_edge_handles
ADD CONSTRAINT cross_edge_unique
UNIQUE (edge_id, source_service_id, target_service_id, viewing_service_id);

-- 4. Add comment untuk dokumentasi
COMMENT ON COLUMN cross_service_edge_handles.viewing_service_id IS 'Service yang sedang melihat/viewing edge handle. Memungkinkan setiap service visualization memiliki handle position sendiri.';

-- 5. Create trigger untuk updated_at pada cross_service_edge_handles
CREATE OR REPLACE FUNCTION update_cross_service_edge_handles_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_cross_service_edge_handles_updated_at ON cross_service_edge_handles;

CREATE TRIGGER trigger_update_cross_service_edge_handles_updated_at
    BEFORE UPDATE ON cross_service_edge_handles
    FOR EACH ROW
    EXECUTE FUNCTION update_cross_service_edge_handles_updated_at();
