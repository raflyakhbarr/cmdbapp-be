const pool = require('../db');

// Lazy load socket functions to avoid circular dependency
let socketFunctions = null;
const getSocketFunctions = () => {
  if (!socketFunctions) {
    socketFunctions = require('../socket');
  }
  return socketFunctions;
};

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

// Update service status only
const updateServiceStatus = async (id, status) => {
  // Update service status
  const result = await pool.query(
    'UPDATE services SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *',
    [status, id]
  );

  // Get workspace_id from service items to propagate status
  const itemsResult = await pool.query(
    'SELECT DISTINCT workspace_id FROM service_items WHERE service_id = $1 LIMIT 1',
    [id]
  );

  if (itemsResult.rows.length > 0) {
    const workspaceId = itemsResult.rows[0].workspace_id;

    // Propagate status to service items if status is 'inactive' or 'disabled'
    if (status === 'inactive' || status === 'disabled') {
      const updateResult = await pool.query(
        `UPDATE service_items
         SET status = $1, updated_at = CURRENT_TIMESTAMP
         WHERE service_id = $2 AND workspace_id = $3 AND status = 'active'
         RETURNING *`,
        [status, id, workspaceId]
      );

      // Emit socket events for each affected service item
      const { emitServiceItemStatusUpdate } = getSocketFunctions();
      for (const item of updateResult.rows) {
        await emitServiceItemStatusUpdate(item.id, status, workspaceId, id);
        console.log(`✅ Emitted service item status update: item=${item.id}, status=${status}, service=${id}`);
      }
    }
  }

  return result;
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
const createServiceItem = async (serviceId, name, type, description, position, status, ip, domain, port, category, location, workspaceId, groupId = null) => {
  // Calculate order_in_group if adding to a group
  let orderInGroup = null;
  if (groupId) {
    const maxOrderResult = await pool.query(
      'SELECT COALESCE(MAX(order_in_group), -1) as max FROM service_items WHERE group_id = $1 AND service_id = $2 AND workspace_id = $3',
      [groupId, serviceId, workspaceId]
    );
    orderInGroup = maxOrderResult.rows[0].max + 1;
  }

  return pool.query(
    `INSERT INTO service_items (
      service_id, name, type, description, position, status, ip, domain, port, category, location, workspace_id, group_id, order_in_group
    )
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
    RETURNING *`,
    [
      serviceId,
      name,
      type,
      description,
      position ? JSON.stringify(position) : null,
      status || 'active',
      ip,
      domain,
      port,
      category,
      location,
      workspaceId,
      groupId,
      orderInGroup
    ]
  );
};

// Update service item
const updateServiceItem = (id, name, type, description, status, ip, domain, port, category, location, groupId = null, orderInGroup = null) => {
  return pool.query(
    `UPDATE service_items
     SET name = $1, type = $2, description = $3, status = $4, ip = $5, domain = $6, port = $7, category = $8, location = $9, group_id = $10, order_in_group = $11, updated_at = CURRENT_TIMESTAMP
     WHERE id = $12
     RETURNING *`,
    [name, type, description, status, ip, domain, port, category, location, groupId, orderInGroup, id]
  );
};

// Update service item position
const updateServiceItemPosition = (id, position) => {
  return pool.query(
    'UPDATE service_items SET position = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *',
    [JSON.stringify(position), id]
  );
};

// Update service item status only
const updateServiceItemStatus = async (id, status) => {
  // First, get the service item info
  const itemResult = await pool.query('SELECT service_id, workspace_id FROM service_items WHERE id = $1', [id]);
  if (itemResult.rows.length === 0) {
    return pool.query(
      'UPDATE service_items SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *',
      [status, id]
    );
  }

  const { service_id, workspace_id } = itemResult.rows[0];

  // Update the service item status
  const result = await pool.query(
    'UPDATE service_items SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *',
    [status, id]
  );

  // Propagate status to other service items in the same service if status is 'inactive' or 'disabled'
  if (status === 'inactive' || status === 'disabled') {
    const propagateResult = await pool.query(
      `UPDATE service_items
       SET status = $1, updated_at = CURRENT_TIMESTAMP
       WHERE service_id = $2 AND workspace_id = $3 AND id != $4 AND status = 'active'
       RETURNING *`,
      [status, service_id, workspace_id, id]
    );

    // Emit socket events for each affected service item
    const { emitServiceItemStatusUpdate } = getSocketFunctions();
    for (const item of propagateResult.rows) {
      await emitServiceItemStatusUpdate(item.id, status, workspace_id, service_id);
      console.log(`✅ Emitted propagated service item status update: item=${item.id}, status=${status}, service=${service_id}`);
    }
  }

  return result;
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
const createServiceConnection = (serviceId, sourceId, targetId, workspaceId, connectionType = 'connects_to', propagation = 'source_to_target') => {
  return pool.query(
    `INSERT INTO service_connections (service_id, source_id, target_id, workspace_id, connection_type, propagation)
     VALUES ($1, $2, $3, $4, $5, $6)
     ON CONFLICT (service_id, source_id, target_id) DO UPDATE SET
       connection_type = EXCLUDED.connection_type,
       propagation = EXCLUDED.propagation,
       updated_at = CURRENT_TIMESTAMP
     RETURNING *`,
    [serviceId, sourceId, targetId, workspaceId, connectionType, propagation]
  );
};

// Delete service connection
const deleteServiceConnection = (serviceId, sourceId, targetId) => {
  return pool.query(
    'DELETE FROM service_connections WHERE service_id = $1 AND source_id = $2 AND target_id = $3 RETURNING *',
    [serviceId, sourceId, targetId]
  );
};

// Update service connection type and propagation
const updateServiceConnection = (serviceId, sourceId, targetId, connectionType, propagation) => {
  return pool.query(
    `UPDATE service_connections
     SET connection_type = $4, propagation = $5, updated_at = CURRENT_TIMESTAMP
     WHERE service_id = $1 AND source_id = $2 AND target_id = $3
     RETURNING *`,
    [serviceId, sourceId, targetId, connectionType, propagation]
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
  updateServiceStatus,
  deleteService,

  // Service Items
  getAllServiceItems,
  getServiceItemById,
  createServiceItem,
  updateServiceItem,
  updateServiceItemPosition,
  updateServiceItemStatus,
  deleteServiceItem,

  // Service Connections
  getAllServiceConnections,
  createServiceConnection,
  updateServiceConnection,
  deleteServiceConnection,
  deleteServiceConnectionsByItemId,
};
