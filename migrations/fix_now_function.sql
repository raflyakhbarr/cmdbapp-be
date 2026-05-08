-- Fix: Change 'now' to 'now()' in create_default_external_positions function
-- Error: kolom « now » tidak ada (column 'now' does not exist)
-- Error: column reference "external_service_item_id" is ambiguous

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
      md5(p_service_id || '-' || v_item_id || '-' || extract(epoch from now()))
    )
    ON CONFLICT (workspace_id, service_id, external_service_item_id)
    DO NOTHING;

    v_index := v_index + 1;
  END LOOP;

  -- Return semua positions setelah loop selesai (hanya sekali!)
  -- Note: Don't use table alias for the column to avoid ambiguity with RETURNS TABLE
  RETURN QUERY
  SELECT
    eip.id,
    eip.external_service_item_id AS external_service_item_id,
    eip.position AS item_position
  FROM external_item_positions eip
  WHERE eip.workspace_id = p_workspace_id
    AND eip.service_id = p_service_id
    AND eip.external_service_item_id = ANY(p_external_item_ids)
  ORDER BY array_position(p_external_item_ids, eip.external_service_item_id);
END;
$$ LANGUAGE plpgsql;
