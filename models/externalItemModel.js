const pool = require('../db');

// Get position for an external item in a service visualization
const getExternalItemPosition = (workspaceId, serviceId, externalServiceItemId) => {
  return pool.query(
    `SELECT position FROM external_item_positions
     WHERE workspace_id = $1 AND service_id = $2 AND external_service_item_id = $3`,
    [workspaceId, serviceId, externalServiceItemId]
  );
};

// Get all external item positions for a service
const getExternalItemPositionsByService = (workspaceId, serviceId) => {
  return pool.query(
    `SELECT external_service_item_id, position
     FROM external_item_positions
     WHERE workspace_id = $1 AND service_id = $2`,
    [workspaceId, serviceId]
  );
};

// Get all external item positions for a workspace
// Returns positions grouped by external_service_item_id with service_id
// Frontend should filter by service_id when displaying
const getExternalItemPositionsByWorkspace = (workspaceId) => {
  return pool.query(
    `SELECT
       external_service_item_id,
       service_id,
       position,
       updated_at
     FROM external_item_positions
     WHERE workspace_id = $1
     ORDER BY external_service_item_id, updated_at DESC`,
    [workspaceId]
  );
};

// Save or update external item position
const saveExternalItemPosition = (workspaceId, serviceId, externalServiceItemId, position) => {
  return pool.query(
    `INSERT INTO external_item_positions (workspace_id, service_id, external_service_item_id, position)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (workspace_id, service_id, external_service_item_id)
     DO UPDATE SET position = $4, updated_at = CURRENT_TIMESTAMP
     RETURNING *`,
    [workspaceId, serviceId, externalServiceItemId, JSON.stringify(position)]
  );
};

// Delete external item position
const deleteExternalItemPosition = (workspaceId, serviceId, externalServiceItemId) => {
  return pool.query(
    `DELETE FROM external_item_positions
     WHERE workspace_id = $1 AND service_id = $2 AND external_service_item_id = $3`,
    [workspaceId, serviceId, externalServiceItemId]
  );
};

// Clear all external positions for a service
const clearExternalPositionsByService = (workspaceId, serviceId) => {
  return pool.query(
    `DELETE FROM external_item_positions
     WHERE workspace_id = $1 AND service_id = $2`,
    [workspaceId, serviceId]
  );
};

// Batch create default positions dengan auto-layout (grid pattern)
const batchCreateDefaultPositions = (workspaceId, serviceId, externalServiceItemIds) => {
  // Gunakan PostgreSQL function untuk efficient batch insert
  return pool.query(
    `SELECT
      id,
      external_service_item_id,
      item_position AS position
    FROM create_default_external_positions($1, $2, $3)`,
    [workspaceId, serviceId, externalServiceItemIds]
  );
};

// Get or create external item position (with auto-layout fallback)
const getOrCreateExternalItemPosition = async (workspaceId, serviceId, externalServiceItemId) => {
  // Coba ambil posisi yang sudah ada
  const existing = await pool.query(
    `SELECT position FROM external_item_positions
     WHERE workspace_id = $1 AND service_id = $2 AND external_service_item_id = $3`,
    [workspaceId, serviceId, externalServiceItemId]
  );

  if (existing.rows.length > 0) {
    return existing.rows[0];
  }

  // Jika belum ada, create default position dengan auto-layout
  const result = await pool.query(
    `INSERT INTO external_item_positions
       (workspace_id, service_id, external_service_item_id, position, is_auto_layouted, layout_hash)
     VALUES ($1, $2, $3,
       jsonb_build_object(
         'x', 500 + (floor(random() * 10)::int % 4) * 200,
         'y', 100 + floor(random() * 10)::int * 150
       ),
       true,
       md5($2 || '-' || $3 || '-' || extract(epoch from now()))
     )
     ON CONFLICT (workspace_id, service_id, external_service_item_id)
     DO UPDATE SET position = external_item_positions.position
     RETURNING *`,
    [workspaceId, serviceId, externalServiceItemId]
  );

  return result.rows[0];
};

// Cross-service edge handles functions
const getCrossServiceEdgeHandle = (edgeId, sourceServiceId, targetServiceId) => {
  return pool.query(
    `SELECT * FROM cross_service_edge_handles
     WHERE edge_id = $1 AND source_service_id = $2 AND target_service_id = $3`,
    [edgeId, sourceServiceId, targetServiceId]
  );
};

const getCrossServiceEdgeHandlesByService = (serviceId) => {
  return pool.query(
    `SELECT * FROM cross_service_edge_handles
     WHERE source_service_id = $1 OR target_service_id = $1`,
    [serviceId]
  );
};

const saveCrossServiceEdgeHandle = (edgeId, sourceServiceId, targetServiceId, sourceHandle, targetHandle, workspaceId) => {
  return pool.query(
    `INSERT INTO cross_service_edge_handles (edge_id, source_service_id, target_service_id, source_handle, target_handle, workspace_id)
     VALUES ($1, $2, $3, $4, $5, $6)
     ON CONFLICT (edge_id, source_service_id, target_service_id)
     DO UPDATE SET source_handle = $4, target_handle = $5, updated_at = CURRENT_TIMESTAMP
     RETURNING *`,
    [edgeId, sourceServiceId, targetServiceId, sourceHandle, targetHandle, workspaceId]
  );
};

module.exports = {
  getExternalItemPosition,
  getExternalItemPositionsByService,
  getExternalItemPositionsByWorkspace,
  saveExternalItemPosition,
  deleteExternalItemPosition,
  clearExternalPositionsByService,
  getOrCreateExternalItemPosition,
  batchCreateDefaultPositions,
  getCrossServiceEdgeHandle,
  getCrossServiceEdgeHandlesByService,
  saveCrossServiceEdgeHandle,
};
