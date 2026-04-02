-- Migration: Improve External Item Positions for Cross-Service Connections
-- Purpose: Memastikan posisi external items terpisah per service visualization
-- Date: 2026-04-01

-- 1. Add unique constraint untuk memastikan satu posisi per workspace-service-item combo
-- Note: Constraint ini sudah ada, tapi kita pastikan lagi
-- Drop constraint lama jika ada (bukan index!)
DO $$
BEGIN
    -- Cek apakah constraint ada
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'external_item_unique'
    ) THEN
        -- Drop constraint dari tabel
        ALTER TABLE external_item_positions
        DROP CONSTRAINT external_item_unique;
    END IF;
END $$;

-- Create unique constraint baru
ALTER TABLE external_item_positions
ADD CONSTRAINT external_item_unique
UNIQUE (workspace_id, service_id, external_service_item_id);

-- 2. Add column untuk auto-layout tracking
ALTER TABLE external_item_positions
ADD COLUMN IF NOT EXISTS is_auto_layouted BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS layout_hash VARCHAR(255);

-- layout_hash digunakan untuk mendeteksi jika struktur berubah
-- Format: "{serviceId}-{itemCount}-{timestamp}"

-- 3. Add index untuk query performance
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE tablename = 'external_item_positions'
          AND indexname = 'idx_external_item_positions_auto_layout'
    ) THEN
        CREATE INDEX idx_external_item_positions_auto_layout
        ON external_item_positions(service_id, workspace_id)
        WHERE is_auto_layouted = true;
    END IF;
END $$;

-- 4. Create trigger untuk auto-create position entry saat external item pertama kali di-load
CREATE OR REPLACE FUNCTION ensure_external_item_position()
RETURNS TRIGGER AS $$
DECLARE
  target_workspace_id INTEGER;
  target_service_id INTEGER;
BEGIN
  -- Get workspace dan service dari context
  -- Trigger ini akan dipanggil manual melalui API endpoint
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. Create function untuk batch create default positions
CREATE OR REPLACE FUNCTION create_default_external_positions(
  p_workspace_id INTEGER,
  p_service_id INTEGER,
  p_external_item_ids INTEGER[]
)
RETURNS TABLE (
  id INTEGER,
  external_service_item_id INTEGER,
  item_position JSONB
) AS $$
DECLARE
  v_item_id INTEGER;
  v_index INTEGER := 0;
  v_offset_x INTEGER := 500;
  v_offset_y INTEGER := 100;
BEGIN
  -- Insert positions satu per satu dengan loop yang benar
  FOREACH v_item_id IN ARRAY p_external_item_ids
  LOOP
    INSERT INTO external_item_positions (
      workspace_id,
      service_id,
      external_service_item_id,
      position,
      is_auto_layouted,
      layout_hash
    )
    VALUES (
      p_workspace_id,
      p_service_id,
      v_item_id,
      jsonb_build_object(
        'x', v_offset_x + (v_index % 4) * 200,
        'y', v_offset_y + floor(v_index / 4.0) * 150
      ),
      true,
      md5(p_service_id || '-' || v_item_id || '-' || extract(epoch from now))
    )
    ON CONFLICT (workspace_id, service_id, external_service_item_id)
    DO NOTHING;

    v_index := v_index + 1;
  END LOOP;

  -- Return semua positions setelah loop selesai (hanya sekali!)
  RETURN QUERY
  SELECT
    eip.id,
    eip.external_service_item_id,
    eip.position AS item_position
  FROM external_item_positions eip
  WHERE eip.workspace_id = p_workspace_id
    AND eip.service_id = p_service_id
    AND eip.external_service_item_id = ANY(p_external_item_ids)
  ORDER BY array_position(p_external_item_ids, eip.external_service_item_id);
END;
$$ LANGUAGE plpgsql;

-- 6. Add comment untuk dokumentasi
COMMENT ON COLUMN external_item_positions.is_auto_layouted IS 'True jika posisi di-generate oleh auto-layout, False jika posisi di-set manual oleh user';
COMMENT ON COLUMN external_item_positions.layout_hash IS 'Hash untuk tracking layout changes dan detect re-layout needs';
COMMENT ON FUNCTION create_default_external_positions IS 'Batch create default positions untuk external items dengan grid pattern layout';

-- 7. Create view untuk easy lookup external positions dengan fallback ke service_items position
-- TAPI kita tidak akan gunakan service_items.position untuk external items!
-- Kita gunakan NULL sebagai indicator bahwa posisi belum diset
DROP VIEW IF EXISTS external_items_with_positions;

CREATE VIEW external_items_with_positions AS
SELECT
  eip.id as position_id,
  eip.workspace_id,
  eip.service_id,
  eip.external_service_item_id,
  eip.position,
  eip.is_auto_layouted,
  eip.layout_hash,
  eip.updated_at,
  si.name as item_name,
  si.type as item_type,
  si.status as item_status,
  s.name as source_service_name,
  s.id as source_service_id
FROM external_item_positions eip
INNER JOIN service_items si ON eip.external_service_item_id = si.id
INNER JOIN services s ON si.service_id = s.id;

COMMENT ON VIEW external_items_with_positions IS 'View untuk lookup external item positions dengan metadata';
