const pool = require('../db');

// Get all cross-service connections for a workspace
const getCrossServiceConnectionsByWorkspace = (workspaceId) => {
  return pool.query(`
    SELECT
      csc.*,
      ssi.id as source_id,
      ssi.name as source_name,
      ssi.type as source_type,
      ssi.status as source_status,
      ss.cmdb_item_id as source_cmdb_item_id,
      ssi.service_id as source_service_id,
      tsi.id as target_id,
      tsi.name as target_name,
      tsi.type as target_type,
      tsi.status as target_status,
      ts.cmdb_item_id as target_cmdb_item_id,
      tsi.service_id as target_service_id
    FROM cross_service_connections csc
    INNER JOIN service_items ssi ON csc.source_service_item_id = ssi.id
    INNER JOIN services ss ON ssi.service_id = ss.id
    INNER JOIN service_items tsi ON csc.target_service_item_id = tsi.id
    INNER JOIN services ts ON tsi.service_id = ts.id
    WHERE csc.workspace_id = $1
    ORDER BY csc.created_at DESC
  `, [workspaceId]);
};

// Get connections for a specific service item (both as source and target)
const getCrossServiceConnectionsByServiceItemId = (serviceItemId) => {
  return pool.query(`
    SELECT
      csc.*,
      ssi.id as source_id,
      ssi.name as source_name,
      ssi.type as source_type,
      ssi.status as source_status,
      ss.cmdb_item_id as source_cmdb_item_id,
      ssi.service_id as source_service_id,
      tsi.id as target_id,
      tsi.name as target_name,
      tsi.type as target_type,
      tsi.status as target_status,
      ts.cmdb_item_id as target_cmdb_item_id,
      tsi.service_id as target_service_id
    FROM cross_service_connections csc
    INNER JOIN service_items ssi ON csc.source_service_item_id = ssi.id
    INNER JOIN services ss ON ssi.service_id = ss.id
    INNER JOIN service_items tsi ON csc.target_service_item_id = tsi.id
    INNER JOIN services ts ON tsi.service_id = ts.id
    WHERE csc.source_service_item_id = $1 OR csc.target_service_item_id = $1
    ORDER BY csc.created_at DESC
  `, [serviceItemId]);
};

// Get connections between two specific service items
const getCrossServiceConnectionBetweenItems = (sourceId, targetId) => {
  return pool.query(`
    SELECT * FROM cross_service_connections
    WHERE source_service_item_id = $1 AND target_service_item_id = $2
  `, [sourceId, targetId]);
};

// Get connection by ID
const getCrossServiceConnectionById = (id) => {
  return pool.query(`
    SELECT * FROM cross_service_connections
    WHERE id = $1
  `, [id]);
};

// Create a new cross-service connection
const createCrossServiceConnection = (
  sourceServiceItemId,
  targetServiceItemId,
  workspaceId,
  connectionType = 'connects_to',
  direction = 'forward'
) => {
  return pool.query(
    `INSERT INTO cross_service_connections
      (source_service_item_id, target_service_item_id, workspace_id, connection_type, direction)
     VALUES($1, $2, $3, $4, $5)
     RETURNING *`,
    [sourceServiceItemId, targetServiceItemId, workspaceId, connectionType, direction]
  );
};

// Update existing cross-service connection
const updateCrossServiceConnection = (
  sourceServiceItemId,
  targetServiceItemId,
  workspaceId,
  connectionType,
  direction
) => {
  return pool.query(
    `UPDATE cross_service_connections
     SET connection_type = $1, direction = $2, updated_at = CURRENT_TIMESTAMP
     WHERE source_service_item_id = $3 AND target_service_item_id = $4 AND workspace_id = $5
     RETURNING *`,
    [connectionType, direction, sourceServiceItemId, targetServiceItemId, workspaceId]
  );
};

// Update by ID
const updateCrossServiceConnectionById = (
  id,
  connectionType,
  direction
) => {
  return pool.query(
    `UPDATE cross_service_connections
     SET connection_type = $1, direction = $2, updated_at = CURRENT_TIMESTAMP
     WHERE id = $3
     RETURNING *`,
    [connectionType, direction, id]
  );
};

// Delete a cross-service connection
const deleteCrossServiceConnection = (sourceServiceItemId, targetServiceItemId) => {
  return pool.query(
    'DELETE FROM cross_service_connections WHERE source_service_item_id = $1 AND target_service_item_id = $2',
    [sourceServiceItemId, targetServiceItemId]
  );
};

// Delete by ID
const deleteCrossServiceConnectionById = (id) => {
  return pool.query(
    'DELETE FROM cross_service_connections WHERE id = $1',
    [id]
  );
};

// Delete all connections for a service item
const deleteCrossServiceConnectionsByServiceItemId = (serviceItemId) => {
  return pool.query(
    'DELETE FROM cross_service_connections WHERE source_service_item_id = $1 OR target_service_item_id = $1',
    [serviceItemId]
  );
};

// Get all available service items for connection (from all services in workspace)
const getAvailableServiceItemsForConnection = (workspaceId, currentServiceItemId) => {
  return pool.query(`
    SELECT
      si.id,
      si.name,
      si.type,
      si.status,
      s.cmdb_item_id,
      si.service_id,
      s.name as service_name,
      ci.name as cmdb_item_name
    FROM service_items si
    INNER JOIN services s ON si.service_id = s.id
    INNER JOIN cmdb_items ci ON s.cmdb_item_id = ci.id
    WHERE si.workspace_id = $1
      AND si.id != $2
    ORDER BY s.name, si.name
  `, [workspaceId, currentServiceItemId]);
};

module.exports = {
  getCrossServiceConnectionsByWorkspace,
  getCrossServiceConnectionsByServiceItemId,
  getCrossServiceConnectionBetweenItems,
  getCrossServiceConnectionById,
  createCrossServiceConnection,
  updateCrossServiceConnection,
  updateCrossServiceConnectionById,
  deleteCrossServiceConnection,
  deleteCrossServiceConnectionById,
  deleteCrossServiceConnectionsByServiceItemId,
  getAvailableServiceItemsForConnection,
};
