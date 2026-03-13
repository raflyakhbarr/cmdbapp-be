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
  saveExternalItemPosition,
  deleteExternalItemPosition,
  clearExternalPositionsByService,
  getCrossServiceEdgeHandle,
  getCrossServiceEdgeHandlesByService,
  saveCrossServiceEdgeHandle,
};
