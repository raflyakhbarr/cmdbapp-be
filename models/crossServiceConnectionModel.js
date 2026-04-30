const pool = require('../db');

// Lazy load socket functions to avoid circular dependency
let socketFunctions = null;
const getSocketFunctions = () => {
  if (!socketFunctions) {
    socketFunctions = require('../socket');
  }
  return socketFunctions;
};

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
      ss.name as source_service_name,
      cmi_source.name as source_cmdb_item_name,
      tsi.id as target_id,
      tsi.name as target_name,
      tsi.type as target_type,
      tsi.status as target_status,
      ts.cmdb_item_id as target_cmdb_item_id,
      tsi.service_id as target_service_id,
      ts.name as target_service_name,
      cmi_target.name as target_cmdb_item_name
    FROM cross_service_connections csc
    INNER JOIN service_items ssi ON csc.source_service_item_id = ssi.id
    INNER JOIN services ss ON ssi.service_id = ss.id
    INNER JOIN cmdb_items cmi_source ON ss.cmdb_item_id = cmi_source.id
    INNER JOIN service_items tsi ON csc.target_service_item_id = tsi.id
    INNER JOIN services ts ON tsi.service_id = ts.id
    INNER JOIN cmdb_items cmi_target ON ts.cmdb_item_id = cmi_target.id
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
      ss.name as source_service_name,
      cmi_source.name as source_cmdb_item_name,
      tsi.id as target_id,
      tsi.name as target_name,
      tsi.type as target_type,
      tsi.status as target_status,
      ts.cmdb_item_id as target_cmdb_item_id,
      tsi.service_id as target_service_id,
      ts.name as target_service_name,
      cmi_target.name as target_cmdb_item_name
    FROM cross_service_connections csc
    INNER JOIN service_items ssi ON csc.source_service_item_id = ssi.id
    INNER JOIN services ss ON ssi.service_id = ss.id
    INNER JOIN cmdb_items cmi_source ON ss.cmdb_item_id = cmi_source.id
    INNER JOIN service_items tsi ON csc.target_service_item_id = tsi.id
    INNER JOIN services ts ON tsi.service_id = ts.id
    INNER JOIN cmdb_items cmi_target ON ts.cmdb_item_id = cmi_target.id
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
  direction = 'forward',
  propagationEnabled = true
) => {
  return pool.query(
    `INSERT INTO cross_service_connections
      (source_service_item_id, target_service_item_id, workspace_id, connection_type, direction, propagation_enabled)
     VALUES($1, $2, $3, $4, $5, $6)
     RETURNING *`,
    [sourceServiceItemId, targetServiceItemId, workspaceId, connectionType, direction, propagationEnabled]
  );
};

// Update existing cross-service connection
const updateCrossServiceConnection = (
  sourceServiceItemId,
  targetServiceItemId,
  workspaceId,
  connectionType,
  direction,
  propagationEnabled
) => {
  return pool.query(
    `UPDATE cross_service_connections
     SET connection_type = $1, direction = $2, propagation_enabled = $3, updated_at = CURRENT_TIMESTAMP
     WHERE source_service_item_id = $4 AND target_service_item_id = $5 AND workspace_id = $6
     RETURNING *`,
    [connectionType, direction, propagationEnabled, sourceServiceItemId, targetServiceItemId, workspaceId]
  );
};

// Update by ID
const updateCrossServiceConnectionById = (
  id,
  connectionType,
  direction,
  propagationEnabled
) => {
  return pool.query(
    `UPDATE cross_service_connections
     SET connection_type = $1, direction = $2, propagation_enabled = $3, updated_at = CURRENT_TIMESTAMP
     WHERE id = $4
     RETURNING *`,
    [connectionType, direction, propagationEnabled, id]
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

// ==================== RECURSIVE CROSS-SERVICE PROPAGATION ====================

/**
 * Get connection type definition by slug
 * @param {string} typeSlug - The connection type slug (e.g., 'depends_on', 'consumed_by')
 * @returns {Object} - Connection type definition with propagation info
 */
const getConnectionTypeDefinition = async (typeSlug) => {
  try {
    const result = await pool.query(
      'SELECT * FROM connection_type_definitions WHERE type_slug = $1',
      [typeSlug]
    );
    return result.rows[0] || null;
  } catch (error) {
    console.error(`Error fetching connection type definition for ${typeSlug}:`, error);
    return null;
  }
};

/**
 * Recursively propagate status changes through cross-service connections (service item to service item)
 * @param {number} serviceItemId - The service item whose status changed
 * @param {string} status - The new status to propagate
 * @param {number} workspaceId - The workspace ID
 * @param {Set} visitedServiceItems - Set of already visited service item IDs (to prevent cycles)
 * @param {number} depth - Current recursion depth (for safety)
 * @param {number} maxDepth - Maximum recursion depth (default: 10)
 * @returns {Array} - Array of affected service item IDs
 */
const propagateStatusToConnectedServiceItems = async (
  serviceItemId,
  status,
  workspaceId,
  visitedServiceItems = new Set(),
  depth = 0,
  maxDepth = 10
) => {
  if (depth === 0) {
    console.log(`\n🌊 ============================================`);
    console.log(`🌊 CROSS-SERVICE PROPAGATION STARTED`);
    console.log(`🌊 ============================================`);
    console.log(`🌊 Source Service Item ID: ${serviceItemId}`);
    console.log(`🌊 Status to propagate: ${status}`);
    console.log(`🌊 Workspace ID: ${workspaceId}`);
    console.log(`🌊 Max depth: ${maxDepth}`);
    console.log(`🌊 -------------------------------------------`);
  }

  // Safety check: prevent infinite recursion
  if (depth >= maxDepth) {
    console.warn(`${'  '.repeat(depth)}⚠️ Max recursion depth (${maxDepth}) reached for service item ${serviceItemId}`);
    return [];
  }

  // Mark current service item as visited
  visitedServiceItems.add(serviceItemId);

  console.log(`\n${'  '.repeat(depth)}🔻 Depth ${depth}: Processing service item ${serviceItemId}`);
  const affectedServiceItems = [];
  // Safety check: prevent infinite recursion
  if (depth >= maxDepth) {
    console.warn(`⚠️ Max recursion depth (${maxDepth}) reached for service item ${serviceItemId}`);
    return [];
  }

  // Mark current service item as visited
  visitedServiceItems.add(serviceItemId);

  console.log(`\n${'  '.repeat(depth)}🔻 Depth ${depth}: Processing service item ${serviceItemId}`);

  try {
    // Get all cross-service connections where this service item is the source
    const outgoingConnections = await pool.query(`
      SELECT
        csc.id,
        csc.source_service_item_id,
        csc.target_service_item_id,
        csc.connection_type,
        csc.propagation_enabled,
        ssi.name as source_name,
        tsi.name as target_name,
        tsi.status as target_status,
        ss.id as target_service_id,
        ss.name as target_service_name
      FROM cross_service_connections csc
      INNER JOIN service_items ssi ON csc.source_service_item_id = ssi.id
      INNER JOIN service_items tsi ON csc.target_service_item_id = tsi.id
      INNER JOIN services ss ON tsi.service_id = ss.id
      WHERE csc.source_service_item_id = $1
        AND csc.workspace_id = $2
        AND csc.propagation_enabled = true
    `, [serviceItemId, workspaceId]);

    console.log(`${'  '.repeat(depth)}🔍 Found ${outgoingConnections.rows.length} outgoing connections from service item ${serviceItemId}`);

    // Process each outgoing connection
    for (const conn of outgoingConnections.rows) {
      const targetServiceItemId = conn.target_service_item_id;
      const targetServiceId = conn.target_service_id;

      // Skip if already visited
      if (visitedServiceItems.has(targetServiceItemId)) {
        console.log(`${'  '.repeat(depth)}⏭️ Skipping already visited service item ${targetServiceItemId} (${conn.target_name})`);
        continue;
      }

      // Get connection type definition to check propagation rule
      const connTypeDef = await getConnectionTypeDefinition(conn.connection_type);
      const propagation = connTypeDef?.propagation || 'both';

      console.log(`${'  '.repeat(depth)}📋 Connection: "${conn.source_name}" → "${conn.target_name}"`);
      console.log(`${'  '.repeat(depth)}   Type: ${conn.connection_type}, Propagation: ${propagation}, Enabled: ${conn.propagation_enabled}`);
      console.log(`${'  '.repeat(depth)}   Target status: ${conn.target_status}`);

      // Check if propagation should happen based on propagation rule
      // For cross-service connections, we propagate based on connection type definition
      const shouldPropagate =
        propagation === 'source_to_target' ||
        propagation === 'both';

      console.log(`${'  '.repeat(depth)}   Should propagate: ${shouldPropagate ? '✅ YES' : '❌ NO'} (rule: ${propagation})`);

      if (shouldPropagate) {
        // Only propagate if target is currently active (preserve manual changes)
        if (conn.target_status === 'active') {
          console.log(`${'  '.repeat(depth)}✅ PROPAGATING: "${conn.target_name}" (ID: ${targetServiceItemId}) → ${status}`);

          // Update target service item status
          await pool.query(
            `UPDATE service_items
             SET status = $1, updated_at = CURRENT_TIMESTAMP
             WHERE id = $2 AND status = 'active'
             RETURNING id`,
            [status, targetServiceItemId]
          );

          // Update target service status as well (since its service item changed)
          await pool.query(
            `UPDATE services
             SET status = $1, updated_at = CURRENT_TIMESTAMP
             WHERE id = $2 AND status = 'active'
             RETURNING id`,
            [status, targetServiceId]
          );

          // Emit socket events
          const { emitServiceUpdate, emitServiceItemStatusUpdate } = getSocketFunctions();
          await emitServiceItemStatusUpdate(targetServiceItemId, status, workspaceId, targetServiceId);
          await emitServiceUpdate(targetServiceId, workspaceId);
          console.log(`✅ Emitted updates: service item=${targetServiceItemId}, service=${targetServiceId}, status=${status}`);

          affectedServiceItems.push(targetServiceItemId);

          // Recursively propagate to connected service items
          console.log(`${'  '.repeat(depth)}🔄 Recursively propagating from "${conn.target_name}"...`);
          const nestedAffectedItems = await propagateStatusToConnectedServiceItems(
            targetServiceItemId,
            status,
            workspaceId,
            visitedServiceItems,
            depth + 1,
            maxDepth
          );

          console.log(`${'  '.repeat(depth)}🔄 Recursive propagation from "${conn.target_name}" affected ${nestedAffectedItems.length} items`);
          affectedServiceItems.push(...nestedAffectedItems);
        } else {
          console.log(`${'  '.repeat(depth)}⏭️ SKIP: Target "${conn.target_name}" status is ${conn.target_status} (not active)`);
        }
      } else {
        console.log(`${'  '.repeat(depth)}⏭️ SKIP: Connection type "${conn.connection_type}" has propagation="${propagation}" (not source_to_target or both)`);
      }
    }

    console.log(`${'  '.repeat(depth)}✅ Depth ${depth} complete: Affected ${affectedServiceItems.length} service items`);
    if (affectedServiceItems.length > 0) {
      console.log(`${'  '.repeat(depth)}   Affected IDs:`, affectedServiceItems);
    }

    if (depth === 0) {
      console.log(`\n🌊 CROSS-SERVICE PROPAGATION COMPLETED`);
      console.log(`🌊 Total affected service items: ${affectedServiceItems.length}`);
      console.log(`🌊 ============================================`);
    }

    return affectedServiceItems;
  } catch (error) {
    console.error(`❌ Error propagating status from service item ${serviceItemId}:`, error);
    throw error;
  }
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
  propagateStatusToConnectedServiceItems,
  getConnectionTypeDefinition,
};
