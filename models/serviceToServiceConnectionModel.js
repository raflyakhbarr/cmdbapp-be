const pool = require('../db');

// ==================== SERVICE TO SERVICE CONNECTIONS ====================
// These are direct connections between services (not service items)
// Both services must belong to the same CMDB item

// Get all service-to-service connections for a specific CMDB item
const getServiceToServiceConnectionsByItemId = (itemId) => {
  return pool.query(
    `SELECT
      stsc.*,
      s1.name as source_service_name,
      s2.name as target_service_name,
      s1.status as source_service_status,
      s2.status as target_service_status
    FROM service_to_service_connections stsc
    INNER JOIN services s1 ON stsc.source_service_id = s1.id
    INNER JOIN services s2 ON stsc.target_service_id = s2.id
    WHERE stsc.cmdb_item_id = $1
    ORDER BY stsc.created_at`,
    [itemId]
  );
};

// Get all service-to-service connections for a workspace
const getServiceToServiceConnectionsByWorkspace = (workspaceId) => {
  return pool.query(
    `SELECT
      stsc.*,
      s1.name as source_service_name,
      s2.name as target_service_name,
      s1.status as source_service_status,
      s2.status as target_service_status,
      ci.name as cmdb_item_name
    FROM service_to_service_connections stsc
    INNER JOIN services s1 ON stsc.source_service_id = s1.id
    INNER JOIN services s2 ON stsc.target_service_id = s2.id
    INNER JOIN cmdb_items ci ON stsc.cmdb_item_id = ci.id
    WHERE stsc.workspace_id = $1
    ORDER BY stsc.cmdb_item_id, stsc.created_at`,
    [workspaceId]
  );
};

// Get a specific service-to-service connection by source and target service IDs
const getServiceToServiceConnection = (sourceServiceId, targetServiceId) => {
  return pool.query(
    'SELECT * FROM service_to_service_connections WHERE source_service_id = $1 AND target_service_id = $2',
    [sourceServiceId, targetServiceId]
  );
};

// Get a specific service-to-service connection by ID
const getServiceToServiceConnectionById = (id) => {
  return pool.query(
    'SELECT * FROM service_to_service_connections WHERE id = $1',
    [id]
  );
};

// Create a new service-to-service connection
const createServiceToServiceConnection = (
  cmdbItemId,
  sourceServiceId,
  targetServiceId,
  workspaceId,
  connectionType = 'connects_to',
  direction = 'forward',
  propagation = 'source_to_target'
) => {
  return pool.query(
    `INSERT INTO service_to_service_connections (
      cmdb_item_id,
      source_service_id,
      target_service_id,
      workspace_id,
      connection_type,
      direction,
      propagation
    )
    VALUES ($1, $2, $3, $4, $5, $6, $7)
    RETURNING *`,
    [cmdbItemId, sourceServiceId, targetServiceId, workspaceId, connectionType, direction, propagation]
  );
};

// Update service-to-service connection type, direction, and propagation
const updateServiceToServiceConnection = (id, connectionType, direction, propagation) => {
  return pool.query(
    `UPDATE service_to_service_connections
     SET connection_type = $1,
         direction = $2,
         propagation = $3,
         updated_at = CURRENT_TIMESTAMP
     WHERE id = $4
     RETURNING *`,
    [connectionType, direction, propagation, id]
  );
};

// Delete service-to-service connection by ID
const deleteServiceToServiceConnection = (id) => {
  return pool.query(
    'DELETE FROM service_to_service_connections WHERE id = $1 RETURNING *',
    [id]
  );
};

// Delete service-to-service connection by source and target service IDs
const deleteServiceToServiceConnectionByServices = (sourceServiceId, targetServiceId) => {
  return pool.query(
    'DELETE FROM service_to_service_connections WHERE source_service_id = $1 AND target_service_id = $2 RETURNING *',
    [sourceServiceId, targetServiceId]
  );
};

// Delete all service-to-service connections for a specific CMDB item
const deleteServiceToServiceConnectionsByItemId = (itemId) => {
  return pool.query(
    'DELETE FROM service_to_service_connections WHERE cmdb_item_id = $1 RETURNING *',
    [itemId]
  );
};

// Delete all service-to-service connections for a specific service
const deleteServiceToServiceConnectionsByServiceId = (serviceId) => {
  return pool.query(
    'DELETE FROM service_to_service_connections WHERE source_service_id = $1 OR target_service_id = $1 RETURNING *',
    [serviceId]
  );
};

// Get all connections for a specific service (both as source and target)
const getServiceConnections = (serviceId) => {
  return pool.query(
    `SELECT
      stsc.*,
      s1.name as source_service_name,
      s2.name as target_service_name
    FROM service_to_service_connections stsc
    INNER JOIN services s1 ON stsc.source_service_id = s1.id
    INNER JOIN services s2 ON stsc.target_service_id = s2.id
    WHERE stsc.source_service_id = $1 OR stsc.target_service_id = $1
    ORDER BY stsc.created_at`,
    [serviceId]
  );
};

module.exports = {
  getServiceToServiceConnectionsByItemId,
  getServiceToServiceConnectionsByWorkspace,
  getServiceToServiceConnection,
  getServiceToServiceConnectionById,
  createServiceToServiceConnection,
  updateServiceToServiceConnection,
  deleteServiceToServiceConnection,
  deleteServiceToServiceConnectionByServices,
  deleteServiceToServiceConnectionsByItemId,
  deleteServiceToServiceConnectionsByServiceId,
  getServiceConnections
};
