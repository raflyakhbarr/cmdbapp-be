const pool = require('../db');

// Lazy load socket functions to avoid circular dependency
let socketFunctions = null;
const getSocketFunctions = () => {
  if (!socketFunctions) {
    socketFunctions = require('../socket');
  }
  return socketFunctions;
};

// Lazy load service-to-service connection model to avoid circular dependency
let serviceToServiceConnectionModel = null;
const getServiceToServiceConnectionModel = () => {
  if (!serviceToServiceConnectionModel) {
    serviceToServiceConnectionModel = require('./serviceToServiceConnectionModel');
  }
  return serviceToServiceConnectionModel;
};

// Lazy load cross-service connection model to avoid circular dependency
let crossServiceConnectionModel = null;
const getCrossServiceConnectionModel = () => {
  if (!crossServiceConnectionModel) {
    crossServiceConnectionModel = require('./crossServiceConnectionModel');
  }
  return crossServiceConnectionModel;
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
const createService = async (cmdbItemId, name, status = 'active', iconType = 'preset', iconPath = null, iconName = null, description = null) => {
  // Get workspace_id from parent cmdb_item
  const cmdbItemResult = await pool.query(
    'SELECT workspace_id FROM cmdb_items WHERE id = $1',
    [cmdbItemId]
  );

  if (cmdbItemResult.rows.length === 0) {
    throw new Error('CMDB item not found');
  }

  const workspaceId = cmdbItemResult.rows[0].workspace_id;

  return pool.query(
    `INSERT INTO services (
      cmdb_item_id, workspace_id, name, status, icon_type, icon_path, icon_name, description
    )
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
    RETURNING *`,
    [cmdbItemId, workspaceId, name, status, iconType, iconPath, iconName, description]
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

// Update service position (as independent node)
const updateServicePosition = (id, position) => {
  return pool.query(
    'UPDATE services SET position = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *',
    [JSON.stringify(position), id]
  );
};

// Update service dimensions
const updateServiceDimensions = (id, width, height) => {
  return pool.query(
    'UPDATE services SET width = $1, height = $2, updated_at = CURRENT_TIMESTAMP WHERE id = $3 RETURNING *',
    [width, height, id]
  );
};

// Toggle service expanded state
const toggleServiceExpanded = (id) => {
  return pool.query(
    'UPDATE services SET is_expanded = NOT is_expanded, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *',
    [id]
  );
};

// Get services with item counts for a workspace
const getServicesWithItemCounts = (workspaceId) => {
  return pool.query(
    `SELECT s.*,
            COUNT(si.id) FILTER (WHERE si.id IS NOT NULL) as service_items_count
     FROM services s
     LEFT JOIN service_items si ON s.id = si.service_id AND si.workspace_id = $1
     WHERE s.workspace_id = $1
     GROUP BY s.id
     ORDER BY s.created_at`,
    [workspaceId]
  );
};

// ==================== RECURSIVE SERVICE PROPAGATION ====================

/**
 * Recursively propagate status changes through service-to-service connections
 * @param {number} serviceId - The service whose status changed
 * @param {string} status - The new status to propagate
 * @param {number} workspaceId - The workspace ID
 * @param {Set} visitedServices - Set of already visited service IDs (to prevent cycles)
 * @param {number} depth - Current recursion depth (for safety)
 * @param {number} maxDepth - Maximum recursion depth (default: 10)
 * @returns {Array} - Array of affected service IDs
 */
const propagateStatusToConnectedServices = async (
  serviceId,
  status,
  workspaceId,
  visitedServices = new Set(),
  depth = 0,
  maxDepth = 10
) => {
  // Safety check: prevent infinite recursion
  if (depth >= maxDepth) {
    console.warn(`⚠️ Max recursion depth (${maxDepth}) reached for service ${serviceId}`);
    return [];
  }

  // Mark current service as visited
  visitedServices.add(serviceId);

  const affectedServices = [];
  const connectionModel = getServiceToServiceConnectionModel();

  try {
    // Get all outgoing connections from this service
    const connectionsResult = await pool.query(
      `SELECT stsc.target_service_id, s.name as target_service_name, s.status as target_service_status,
              stsc.connection_type, stsc.propagation
       FROM service_to_service_connections stsc
       INNER JOIN services s ON stsc.target_service_id = s.id
       WHERE stsc.source_service_id = $1 AND stsc.workspace_id = $2
       ORDER BY stsc.created_at`,
      [serviceId, workspaceId]
    );

    // Process each connection
    for (const connection of connectionsResult.rows) {
      const targetServiceId = connection.target_service_id;

      // Skip if already visited (prevent cycles)
      if (visitedServices.has(targetServiceId)) {
        console.log(`🔄 Skipping already visited service ${targetServiceId}`);
        continue;
      }

      // Check if propagation should happen based on propagation setting
      const shouldPropagate =
        (connection.propagation === 'source_to_target' || connection.propagation === 'both') &&
        (status === 'inactive' || status === 'disabled' || status === 'maintenance');

      if (!shouldPropagate) {
        console.log(`⏭️ Skipping propagation to ${connection.target_service_name} (propagation=${connection.propagation}, status=${status})`);
        continue;
      }

      // Only propagate if target service is currently active (to avoid overwriting manual changes)
      if (connection.target_service_status !== 'active') {
        console.log(`⏭️ Skipping ${connection.target_service_name} (current status: ${connection.target_service_status})`);
        continue;
      }

      // Update target service status
      console.log(`🔄 Propagating status ${status} from service ${serviceId} to ${connection.target_service_name} (${targetServiceId})`);

      await pool.query(
        'UPDATE services SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
        [status, targetServiceId]
      );

      // Also propagate to service items within the target service
      const serviceItemsResult = await pool.query(
        `UPDATE service_items
         SET status = $1, updated_at = CURRENT_TIMESTAMP
         WHERE service_id = $2 AND workspace_id = $3 AND status = 'active'
         RETURNING id`,
        [status, targetServiceId, workspaceId]
      );

      // Emit socket events for the target service
      const { emitServiceUpdate, emitServiceItemStatusUpdate } = getSocketFunctions();
      await emitServiceUpdate(targetServiceId, workspaceId);
      console.log(`✅ Emitted service update: service=${targetServiceId}, status=${status}`);

      // Emit socket events for affected service items
      for (const item of serviceItemsResult.rows) {
        await emitServiceItemStatusUpdate(item.id, status, workspaceId, targetServiceId);
        console.log(`✅ Emitted service item status update: item=${item.id}, status=${status}, service=${targetServiceId}`);
      }

      affectedServices.push(targetServiceId);

      // Recursively propagate to connected services
      const nestedAffectedServices = await propagateStatusToConnectedServices(
        targetServiceId,
        status,
        workspaceId,
        visitedServices,
        depth + 1,
        maxDepth
      );

      affectedServices.push(...nestedAffectedServices);
    }

    return affectedServices;
  } catch (error) {
    console.error(`❌ Error propagating status from service ${serviceId}:`, error);
    throw error;
  }
};

// Update service status only with recursive propagation
const updateServiceStatus = async (id, status) => {
  // Update service status
  const result = await pool.query(
    'UPDATE services SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *',
    [status, id]
  );

  // Get workspace_id - try service items first, fall back to service's workspace_id
  let workspaceId = null;
  const itemsResult = await pool.query(
    'SELECT DISTINCT workspace_id FROM service_items WHERE service_id = $1 LIMIT 1',
    [id]
  );

  if (itemsResult.rows.length > 0) {
    workspaceId = itemsResult.rows[0].workspace_id;
  } else {
    // If no service items, get workspace_id from the service itself
    const serviceResult = await pool.query(
      'SELECT workspace_id FROM services WHERE id = $1',
      [id]
    );
    if (serviceResult.rows.length > 0) {
      workspaceId = serviceResult.rows[0].workspace_id;
      console.log(`ℹ️ Service ${id} has no service items, using workspace_id from service: ${workspaceId}`);
    }
  }

  // Only propagate if we have a workspace_id and status is 'inactive' or 'disabled'
  if (workspaceId && (status === 'inactive' || status === 'disabled' || status === 'maintenance')) {
    // First propagate to service items if any exist
    if (itemsResult.rows.length > 0) {
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

    // NEW: Recursively propagate to connected services (even if no service items)
    console.log(`🔄 Starting recursive propagation from service ${id} with status ${status}`);
    const affectedServices = await propagateStatusToConnectedServices(
      id,
      status,
      workspaceId,
      new Set([id]), // Start with current service already visited
      0,
      10 // Max depth
    );

    console.log(`✅ Recursive propagation complete. Affected ${affectedServices.length} services:`, affectedServices);

    // NEW: Propagate to external service items via cross-service connections
    // When a service goes inactive, all its service items should propagate to connected external service items
    if (status === 'inactive' || status === 'maintenance' || status === 'decommissioned') {
      console.log(`\n🌐 ============================================`);
      console.log(`🌐 CROSS-SERVICE PROPAGATION FROM SERVICE LEVEL`);
      console.log(`🌐 ============================================`);
      console.log(`🌐 Service ID: ${id}, Status: ${status}, Workspace: ${workspaceId}`);

      try {
        // Get all service items in this service
        const serviceItemsResult = await pool.query(
          `SELECT id, name FROM service_items WHERE service_id = $1 AND workspace_id = $2`,
          [id, workspaceId]
        );

        console.log(`🌐 Service has ${serviceItemsResult.rows.length} service items`);

        const crossServiceModel = getCrossServiceConnectionModel();
        let totalAffectedExternalItems = [];

        // Propagate from each service item to external service items
        for (const item of serviceItemsResult.rows) {
          const affectedItems = await crossServiceModel.propagateStatusToConnectedServiceItems(
            item.id,
            status,
            workspaceId,
            new Set([item.id]), // Start with this item visited
            0,
            10
          );
          console.log(`🌐 From service item "${item.name}" (ID: ${item.id}): affected ${affectedItems.length} external items`);
          totalAffectedExternalItems.push(...affectedItems);
        }

        // Remove duplicates
        const uniqueAffectedItems = [...new Set(totalAffectedExternalItems)];

        console.log(`\n🌐 CROSS-SERVICE PROPAGATION FROM SERVICE ${id} COMPLETE`);
        console.log(`🌐 Total external service items affected: ${uniqueAffectedItems.length}`);
        if (uniqueAffectedItems.length > 0) {
          console.log(`🌐 Affected external item IDs:`, uniqueAffectedItems);
        }
        console.log(`🌐 ============================================\n`);
      } catch (error) {
        console.error(`❌ Error in cross-service propagation from service ${id}:`, error);
        // Don't throw - service-level propagation should continue even if cross-service fails
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
  console.log(`\n🎯 ============================================`);
  console.log(`🎯 UPDATE SERVICE ITEM STATUS STARTED`);
  console.log(`🎯 ============================================`);
  console.log(`🎯 Service Item ID: ${id}`);
  console.log(`🎯 New Status: ${status}`);

  // First, get the service item info
  const itemResult = await pool.query('SELECT service_id, workspace_id, name FROM service_items WHERE id = $1', [id]);
  if (itemResult.rows.length === 0) {
    console.log(`❌ Service item ${id} not found`);
    return pool.query(
      'UPDATE service_items SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *',
      [status, id]
    );
  }

  const { service_id, workspace_id, name: itemName } = itemResult.rows[0];
  console.log(`📋 Service Item: "${itemName}" (Service ID: ${service_id}, Workspace ID: ${workspace_id})`);

  // Update the service item status
  const result = await pool.query(
    'UPDATE service_items SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *',
    [status, id]
  );

  console.log(`✅ Updated service item "${itemName}" to status: ${status}`);

  // Emit socket event for the main service item status update
  const { emitServiceItemStatusUpdate } = getSocketFunctions();
  await emitServiceItemStatusUpdate(id, status, workspace_id, service_id);
  console.log(`✅ Emitted service item status update: item=${id}, status=${status}, service=${service_id}`);

  // NOTE: Internal propagation within same service has been REMOVED
  // Each service item should maintain independent status
  // Only cross-service propagation should affect external service items

  // Propagate to connected service items via cross-service connections
  // Only propagate if status is problematic (inactive, maintenance, decommissioned)
  if (status === 'inactive' || status === 'maintenance' || status === 'decommissioned') {
    console.log(`\n🌐 ============================================`);
    console.log(`🌐 CROSS-SERVICE PROPAGATION STARTED`);
    console.log(`🌐 ============================================`);
    console.log(`🌐 Source: "${itemName}" (ID: ${id})`);
    console.log(`🌐 Status: ${status}`);
    console.log(`🌐 Workspace ID: ${workspace_id}`);
    console.log(`🌐 --------------------------------------------`);

    try {
      const crossServiceModel = getCrossServiceConnectionModel();
      const affectedServiceItems = await crossServiceModel.propagateStatusToConnectedServiceItems(
        id,
        status,
        workspace_id,
        new Set([id]), // Start with current service item already visited
        0,
        10 // Max depth
      );

      console.log(`\n🌐 CROSS-SERVICE PROPAGATION SUMMARY`);
      console.log(`🌐 Total affected service items: ${affectedServiceItems.length}`);
      if (affectedServiceItems.length > 0) {
        console.log(`🌐 Affected service item IDs:`, affectedServiceItems);
      } else {
        console.log(`⚠️ No service items were affected by cross-service propagation`);
      }
      console.log(`🌐 --------------------------------------------`);

      // NEW: For each affected service item in different services, update their parent service status
      // This will trigger internal propagation within those services
      const affectedServiceItemsGrouped = {};

      console.log(`\n🔍 GROUPING AFFECTED SERVICE ITEMS BY PARENT SERVICE`);
      for (const affectedItemId of affectedServiceItems) {
        try {
          // Get the affected service item details
          const affectedItemResult = await pool.query(
            'SELECT service_id, status, name FROM service_items WHERE id = $1',
            [affectedItemId]
          );

          if (affectedItemResult.rows.length > 0) {
            const affectedItem = affectedItemResult.rows[0];
            console.log(`📋 Item "${affectedItem.name}" (ID: ${affectedItemId}) → Service ID: ${affectedItem.service_id}`);

            // Group by service_id
            if (!affectedServiceItemsGrouped[affectedItem.service_id]) {
              affectedServiceItemsGrouped[affectedItem.service_id] = [];
            }
            affectedServiceItemsGrouped[affectedItem.service_id].push(affectedItemId);
          }
        } catch (err) {
          console.error(`❌ Error getting service item ${affectedItemId} details:`, err);
        }
      }

      console.log(`\n🏢 AFFECTED SERVICES: ${Object.keys(affectedServiceItemsGrouped).length}`);
      console.log(`🏢 --------------------------------------------`);

      // Update parent services for affected service items (only if they're still active)
      for (const [affectedServiceId, affectedItemIds] of Object.entries(affectedServiceItemsGrouped)) {
        try {
          // Get service details for logging
          const serviceDetailsResult = await pool.query('SELECT name FROM services WHERE id = $1', [affectedServiceId]);
          const serviceName = serviceDetailsResult.rows[0]?.name || 'Unknown';

          console.log(`\n🏢 Processing Service: "${serviceName}" (ID: ${affectedServiceId})`);
          console.log(`🏢 Affected items in this service: ${affectedItemIds.length}`);

          const serviceUpdateResult = await pool.query(
            `UPDATE services
             SET status = $1, updated_at = CURRENT_TIMESTAMP
             WHERE id = $2 AND status = 'active'
             RETURNING *`,
            [status, affectedServiceId]
          );

          if (serviceUpdateResult.rows.length > 0) {
            await emitServiceUpdate(affectedServiceId, workspace_id);
            console.log(`✅ Updated service "${serviceName}" status to ${status}`);

            // Trigger internal service propagation within the affected service
            // This will propagate to other service items in the same service
            try {
              const internalPropagationResult = await pool.query(
                `UPDATE service_items
                 SET status = $1, updated_at = CURRENT_TIMESTAMP
                 WHERE service_id = $2 AND workspace_id = $3 AND status = 'active'
                 RETURNING *`,
                [status, affectedServiceId, workspaceId]
              );

              // Emit socket events for internally propagated service items
              for (const internalItem of internalPropagationResult.rows) {
                await emitServiceItemStatusUpdate(internalItem.id, status, workspaceId, affectedServiceId);
                console.log(`✅ Emitted internal service item status update: item=${internalItem.id}, status=${status}, service=${affectedServiceId}`);
              }

              console.log(`✅ Internal propagation in service ${affectedServiceId}: affected ${internalPropagationResult.rows.length} service items`);
            } catch (error) {
              console.error(`❌ Error in internal service propagation for service ${affectedServiceId}:`, error);
            }
          }
        } catch (err) {
          console.error(`❌ Error updating service ${affectedServiceId} due to cross-service propagation:`, err);
        }
      }
    } catch (error) {
      console.error(`❌ Error in cross-service propagation from service item ${id}:`, error);
      // Don't throw error, just log it - propagation failure shouldn't break the main update
    }
  }

  console.log(`\n🎯 ============================================`);
  console.log(`🎯 UPDATE SERVICE ITEM STATUS COMPLETED`);
  console.log(`🎯 ============================================\n`);

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
  updateServicePosition,
  updateServiceDimensions,
  toggleServiceExpanded,
  deleteService,
  getServicesWithItemCounts,

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

  // Recursive Propagation
  propagateStatusToConnectedServices,
};
