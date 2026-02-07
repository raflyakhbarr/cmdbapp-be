const pool = require('../db');

// ==================== SERVICES CRUD ====================

// Get all services for a specific CMDB item
const getServicesByItemId = (itemId) => {
  return pool.query(
    'SELECT * FROM services WHERE cmdb_item_id = $1 ORDER BY created_at',
    [itemId]
  );
};

// Get a specific service by ID
const getServiceById = (id) => {
  return pool.query(
    'SELECT * FROM services WHERE id = $1',
    [id]
  );
};

// Create a new service
const createService = (cmdbItemId, name, status = 'active', iconType = 'preset', iconPath = null, iconName = null, description = null) => {
  return pool.query(
    `INSERT INTO services (
      cmdb_item_id, name, status, icon_type, icon_path, icon_name, description
    )
    VALUES ($1, $2, $3, $4, $5, $6, $7)
    RETURNING *`,
    [cmdbItemId, name, status, iconType, iconPath, iconName, description]
  );
};

// Update service
const updateService = (id, name, status, description) => {
  return pool.query(
    `UPDATE services
     SET name = $1, status = $2, description = $3, updated_at = CURRENT_TIMESTAMP
     WHERE id = $4
     RETURNING *`,
    [name, status, description, id]
  );
};

// Update service icon
const updateServiceIcon = (id, iconType, iconPath = null, iconName = null) => {
  return pool.query(
    `UPDATE services
     SET icon_type = $1, icon_path = $2, icon_name = $3, updated_at = CURRENT_TIMESTAMP
     WHERE id = $4
     RETURNING *`,
    [iconType, iconPath, iconName, id]
  );
};

// Delete service (cascade will delete service_items and service_connections)
const deleteService = (id) => {
  return pool.query('DELETE FROM services WHERE id = $1 RETURNING *', [id]);
};

// ==================== SERVICE ITEMS CRUD ====================

// Get all service items for a specific service
const getAllServiceItems = (serviceId, workspaceId) => {
  return pool.query(
    'SELECT * FROM service_items WHERE service_id = $1 AND workspace_id = $2 ORDER BY created_at',
    [serviceId, workspaceId]
  );
};

// Get service item by ID
const getServiceItemById = (id) => {
  return pool.query('SELECT * FROM service_items WHERE id = $1', [id]);
};

// Create a new service item
const createServiceItem = (serviceId, name, type, description, position, status, ip, category, location, workspaceId) => {
  return pool.query(
    `INSERT INTO service_items (
      service_id, name, type, description, position, status, ip, category, location, workspace_id
    )
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
    RETURNING *`,
    [
      serviceId,
      name,
      type,
      description,
      position ? JSON.stringify(position) : null,
      status || 'active',
      ip,
      category,
      location,
      workspaceId
    ]
  );
};

// Update service item
const updateServiceItem = (id, name, type, description, status, ip, category, location) => {
  return pool.query(
    `UPDATE service_items
     SET name = $1, type = $2, description = $3, status = $4, ip = $5, category = $6, location = $7, updated_at = CURRENT_TIMESTAMP
     WHERE id = $8
     RETURNING *`,
    [name, type, description, status, ip, category, location, id]
  );
};

// Update service item position
const updateServiceItemPosition = (id, position) => {
  return pool.query(
    'UPDATE service_items SET position = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *',
    [JSON.stringify(position), id]
  );
};

// Delete service item
const deleteServiceItem = (id) => {
  return pool.query('DELETE FROM service_items WHERE id = $1 RETURNING *', [id]);
};

// ==================== SERVICE CONNECTIONS ====================

// Get all service connections for a specific service
const getAllServiceConnections = (serviceId, workspaceId) => {
  return pool.query(
    'SELECT * FROM service_connections WHERE service_id = $1 AND workspace_id = $2 ORDER BY created_at',
    [serviceId, workspaceId]
  );
};

// Create a new service connection
const createServiceConnection = (serviceId, sourceId, targetId, workspaceId) => {
  return pool.query(
    `INSERT INTO service_connections (service_id, source_id, target_id, workspace_id)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (service_id, source_id, target_id) DO NOTHING
     RETURNING *`,
    [serviceId, sourceId, targetId, workspaceId]
  );
};

// Delete service connection
const deleteServiceConnection = (serviceId, sourceId, targetId) => {
  return pool.query(
    'DELETE FROM service_connections WHERE service_id = $1 AND source_id = $2 AND target_id = $3 RETURNING *',
    [serviceId, sourceId, targetId]
  );
};

// Delete all connections for a service item (when item is deleted)
const deleteServiceConnectionsByItemId = (itemId) => {
  return pool.query('DELETE FROM service_connections WHERE source_id = $1 OR target_id = $1 RETURNING *', [itemId]);
};

module.exports = {
  // Services
  getServicesByItemId,
  getServiceById,
  createService,
  updateService,
  updateServiceIcon,
  deleteService,

  // Service Items
  getAllServiceItems,
  getServiceItemById,
  createServiceItem,
  updateServiceItem,
  updateServiceItemPosition,
  deleteServiceItem,

  // Service Connections
  getAllServiceConnections,
  createServiceConnection,
  deleteServiceConnection,
  deleteServiceConnectionsByItemId,
};
