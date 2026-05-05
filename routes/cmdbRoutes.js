const express = require('express');
const router = express.Router();
const cmdbModel = require('../models/cmdbModel');
const connectionModel = require('../models/connectionModel');
const groupModel = require('../models/groupModel');
const serviceModel = require('../models/serviceModel');
const edgeHandleModel = require('../models/edgeHandleModel');
const ShareLinkModel = require('../models/shareLinkModel');
const { emitCmdbUpdate } = require('../socket');
const pool = require('../db');
const { env } = require('process');
const { authenticateToken } = require('../middleware/auth');

const shareLinkModel = new ShareLinkModel(pool);
const serviceEdgeHandleModel = require('../models/serviceEdgeHandleModel');
const crossServiceEdgeHandleModel = require('../models/crossServiceEdgeHandleModel');
const externalItemModel = require('../models/externalItemModel');

/**
 * PUBLIC ROUTE: Get shared CMDB data by share token
 * This endpoint does NOT require authentication
 */
router.get('/shared/:token', async (req, res) => {
  const { token } = req.params;

  try {
    // Get share link info
    const shareLink = await shareLinkModel.getByToken(token);

    if (!shareLink) {
      return res.status(404).json({
        error: 'Share link not found or expired',
        requires_password: false
      });
    }

    const workspaceId = shareLink.workspace_id;
    const hasPassword = !!shareLink.password_hash;

    // Check if password is required
    if (hasPassword) {
      // Check if password was provided via header
      const headerPassword = req.headers['x-share-password'];

      // Check if password was already verified in session
      const sessionPasswordVerified = req.session?.verified_share_tokens?.[token];

      if (!headerPassword && !sessionPasswordVerified) {
        return res.status(403).json({
          error: 'Password required',
          requires_password: true,
          has_password: true
        });
      }

      // If password provided via header, verify it
      if (headerPassword && !sessionPasswordVerified) {
        const isValid = await shareLinkModel.verifyPassword(token, headerPassword);
        if (!isValid) {
          return res.status(401).json({
            error: 'Invalid password',
            requires_password: true,
            has_password: true
          });
        }
        // Mark as verified in session
        if (!req.session.verified_share_tokens) {
          req.session.verified_share_tokens = {};
        }
        req.session.verified_share_tokens[token] = true;
      }
    }

    // Log access
    const visitorIp = req.ip || req.connection.remoteAddress;
    const userAgent = req.get('user-agent');
    await shareLinkModel.logAccess(shareLink.id, visitorIp, userAgent);

    // ✅ FIX: Filter external item positions by service_id if available
    // This ensures external items use positions from the viewing service (not from other services)
    let externalItemPositionsResult;
    if (shareLink.service_id) {
      console.log('\n🎯 [BACKEND /shared/:token] Filtering external_item_positions by service_id:', shareLink.service_id);
      externalItemPositionsResult = await externalItemModel.getExternalItemPositionsByService(
        workspaceId,
        shareLink.service_id
      );
    } else {
      console.log('\n📊 [BACKEND /shared/:token] No service_id in share link, returning ALL external item positions');
      externalItemPositionsResult = await externalItemModel.getExternalItemPositionsByWorkspace(workspaceId);
    }

    // Get all data for the workspace
    const [itemsResult, connectionsResult, groupsResult, edgeHandlesResult, serviceToServiceConnectionsResult, crossServiceConnectionsResult, serviceEdgeHandlesResult, crossServiceEdgeHandlesResult, connectionTypesResult] = await Promise.all([
      cmdbModel.getAllItems(workspaceId),
      connectionModel.getAllConnections(workspaceId),
      groupModel.getAllGroups(workspaceId),
      edgeHandleModel.getAllEdgeHandles(),
      require('../models/serviceToServiceConnectionModel').getServiceToServiceConnectionsByWorkspace(workspaceId),
      require('../models/crossServiceConnectionModel').getCrossServiceConnectionsByWorkspace(workspaceId),
      serviceEdgeHandleModel.getServiceEdgeHandlesByWorkspace(workspaceId),
      crossServiceEdgeHandleModel.getCrossServiceEdgeHandlesByWorkspace(workspaceId),
      // externalItemPositionsResult - moved above (line 95-103)
      connectionModel.getConnectionTypeDefinitions()
    ]);

    // Debug external item positions
    console.log('\n📊 [BACKEND /shared/:token] External Item Positions Debug:');
    console.log('📊 workspace_id:', workspaceId);
    console.log('📊 share_link.service_id:', shareLink.service_id);
    console.log('📊 externalItemPositionsResult.rows.length:', externalItemPositionsResult.rows.length);
    console.log('📊 Sample positions:', externalItemPositionsResult.rows.slice(0, 3));
    console.log('📊 ========================================\n');

    // Get services for all items WITH service items
    const items = itemsResult.rows;

    // Collect all services
    const allServices = [];
    const itemsWithServices = await Promise.all(
      items.map(async (item) => {
        const servicesResult = await serviceModel.getServicesByItemId(item.id);

        // Get service items for each service
        const servicesWithItems = await Promise.all(
          servicesResult.rows.map(async (service) => {
            const serviceItemsResult = await pool.query(
              'SELECT * FROM service_items WHERE service_id = $1 ORDER BY created_at',
              [service.id]
            );

            // Get internal item-to-item connections for this service
            const serviceItemIds = serviceItemsResult.rows.map(si => si.id);
            let serviceConnections = [];
            if (serviceItemIds.length > 0) {
              const connectionsResult = await pool.query(
                `SELECT * FROM service_connections
                 WHERE service_id = $1 AND source_id = ANY($2) AND target_id = ANY($2)`,
                [service.id, serviceItemIds]
              );
              serviceConnections = connectionsResult.rows;
            }

            // Get service groups for this service
            const groupsResult = await pool.query(
              'SELECT * FROM service_groups WHERE service_id = $1',
              [service.id]
            );

            // Get group connections for this service
            const groupIds = groupsResult.rows.map(g => g.id);
            let groupConnections = [];
            if (groupIds.length > 0) {
              // Query includes: group-to-group (source_id, target_id) AND group-to-item (source_group_id, target_item_id)
              const groupConnResult = await pool.query(
                `SELECT * FROM service_group_connections
                 WHERE service_id = $1 AND workspace_id = $2
                 AND (
                   source_id = ANY($3) OR target_id = ANY($3)
                   OR source_group_id = ANY($3) OR target_item_id = ANY($4)
                 )`,
                [service.id, workspaceId, groupIds, serviceItemIds]
              );
              groupConnections = groupConnResult.rows;
            }

            const serviceWithItems = {
              ...service,
              service_items: serviceItemsResult.rows,
              service_connections: serviceConnections,
              service_groups: groupsResult.rows,
              service_group_connections: groupConnections
            };

            // Add to all services array
            allServices.push(serviceWithItems);

            return serviceWithItems;
          })
        );

        return {
          ...item,
          services: servicesWithItems
        };
      })
    );

    res.json({
      workspace_id: workspaceId,
      items: itemsWithServices,
      services: allServices, // Add services as separate array
      connections: connectionsResult.rows,
      groups: groupsResult.rows,
      edge_handles: edgeHandlesResult.rows,
      serviceToServiceConnections: serviceToServiceConnectionsResult.rows,
      crossServiceConnections: crossServiceConnectionsResult.rows,
      service_edge_handles: serviceEdgeHandlesResult.rows,
      cross_service_edge_handles: crossServiceEdgeHandlesResult.rows,
      external_item_positions: externalItemPositionsResult.rows,
      connection_types: connectionTypesResult.rows,
      share_info: {
        token: shareLink.token,
        created_at: shareLink.created_at,
        expires_at: shareLink.expires_at,
        has_password: hasPassword,
        service_id: shareLink.service_id, // ✅ ADD: Service being shared
        cmdb_item_id: shareLink.cmdb_item_id // ✅ ADD: CMDB item being shared
      }
    });
  } catch (err) {
    console.error('Error fetching shared CMDB:', err);
    res.status(500).json({ error: err.message });
  }
});

/**
 * PUBLIC ROUTE: Verify password for protected share link
 * This endpoint does NOT require authentication
 */
router.post('/shared/:token/verify-password', async (req, res) => {
  const { token } = req.params;
  const { password } = req.body;

  if (!password) {
    return res.status(400).json({ error: 'Password is required' });
  }

  try {
    const shareLink = await shareLinkModel.getByToken(token);

    if (!shareLink) {
      return res.status(404).json({ error: 'Share link not found or expired' });
    }

    if (!shareLink.password_hash) {
      return res.status(400).json({ error: 'This share link is not password protected' });
    }

    const isValid = await shareLinkModel.verifyPassword(token, password);

    if (isValid) {
      // Store verified token in session
      if (!req.session.verified_share_tokens) {
        req.session.verified_share_tokens = {};
      }
      req.session.verified_share_tokens[token] = true;

      res.json({ success: true });
    } else {
      res.status(401).json({ error: 'Invalid password' });
    }
  } catch (err) {
    console.error('Error verifying password:', err);
    res.status(500).json({ error: err.message });
  }
});

router.get('/', authenticateToken, async (req, res) => {
  const { workspace_id } = req.query;
  
  try {
    const result = await cmdbModel.getAllItems(workspace_id || null);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/connections', authenticateToken, async (req, res) => {
  const { workspace_id } = req.query;

  try {
    const result = await connectionModel.getAllConnections(workspace_id || null);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get connection type definitions
router.get('/connection-types', authenticateToken, async (req, res) => {
  try {
    const result = await connectionModel.getConnectionTypeDefinitions();
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get connections for specific item
router.get('/:id/connections', authenticateToken, async (req, res) => {
  const { id } = req.params;
  try {
    const result = await connectionModel.getConnectionsByItemId(id);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get affected items (cascade view)
router.get('/:id/affected', authenticateToken, async (req, res) => {
  const { id } = req.params;
  try {
    const result = await connectionModel.getAffectedItems(id);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Method post buat item
router.post('/', authenticateToken, async (req, res) => {
  const { name, type, description, status, ip, category, location, group_id, env_type, position, workspace_id, storage, alias, port } = req.body;

  if(!workspace_id) {
    return res.status(400).json({ error: 'workspace_id is required' });
  }

  try {
    const result = await cmdbModel.createItem(
      name,
      type,
      description,
      status || 'active',
      ip,
      category,
      location,
      group_id || null,
      env_type,
      position ? JSON.parse(position) : null,
      workspace_id,
      storage || null,
      alias || null,
      port || null
    );
    await emitCmdbUpdate(cmdbModel);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Create connection between items
router.post('/connections', authenticateToken, async (req, res) => {
  const { source_id, target_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id } = req.body;

  // Log connection creation
  console.log('\n🔗 ========================================');
  console.log('🔗 BACKEND: Creating Connection');
  console.log('🔗 ========================================');
  console.log('🔗 source_id:', source_id);
  console.log('🔗 source_service_id:', source_service_id);
  console.log('🔗 source_service_item_id:', source_service_item_id);
  console.log('🔗 target_id:', target_id);
  console.log('🔗 target_service_id:', target_service_id);
  console.log('🔗 target_service_item_id:', target_service_item_id);
  console.log('🔗 workspace_id:', workspace_id);
  console.log('🔗 connection_type:', connection_type);
  console.log('🔗 direction:', direction);
  console.log('🔗 ========================================\n');

  // Allow various source/target combinations
  const hasSource = source_id || source_service_id || source_service_item_id;
  const hasTarget = target_id || target_service_id || target_service_item_id;

  if (!hasSource || !hasTarget) {
    return res.status(400).json({ error: 'source (source_id/source_service_id/source_service_item_id) and target (target_id/target_service_id/target_service_item_id) are required' });
  }

  if (!workspace_id) {
    return res.status(400).json({ error: 'workspace_id is required' });
  }

  try {
    const result = await connectionModel.createConnection(
      source_id || null,
      target_id || null,
      workspace_id,
      connection_type || 'depends_on',
      direction || 'forward',
      target_service_id || null,
      target_service_item_id || null,
      source_service_id || null,
      source_service_item_id || null
    );

    console.log('\n✅ Connection created successfully!');
    console.log('✅ Connection ID:', result.rows[0].id);
    console.log('✅ ========================================\n');

    await emitCmdbUpdate(cmdbModel);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('❌ Error creating connection:', err);
    res.status(500).json({ error: err.message });
  }
});

router.post('/connections/to-group', authenticateToken, async (req, res) => {
  const { source_id, target_group_id, workspace_id } = req.body;
  
  if (!source_id || !target_group_id) {
    return res.status(400).json({ error: 'source_id and target_group_id are required' });
  }
  
  if (!workspace_id) {
    return res.status(400).json({ error: 'workspace_id is required' });
  }
  
  try {
    const result = await connectionModel.createItemToGroupConnection(source_id, target_group_id, workspace_id);
    await emitCmdbUpdate(cmdbModel);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update item position
router.put('/:id/position', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { position, skipEmit } = req.body; // ← TAMBAH skipEmit

  if (!position || typeof position.x !== 'number' || typeof position.y !== 'number') {
    return res.status(400).json({ error: 'Invalid position format' });
  }

  try {
    const result = await cmdbModel.updateItemPosition(id, position);
    
    if (!skipEmit) {
      await emitCmdbUpdate(cmdbModel);
    }
    
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Method update
router.put('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { name, type, description, status, ip, category, location, group_id, env_type, storage, alias, port } = req.body;

  try {
    // Get current item to check if status exists
    const currentResult = await cmdbModel.getItemById(id);
    const currentItem = currentResult.rows[0];
    const currentStatus = currentItem ? currentItem.status : 'active';

    // Update item without status first (to avoid double status update)
    const result = await cmdbModel.updateItem(
      id,
      name,
      type,
      description,
      currentStatus, // Use current status, don't update yet
      ip,
      category,
      location,
      group_id || null,
      env_type,
      storage || null,
      alias || null,
      port || null
    );

    // Then update status separately with propagation if status is being changed
    if (status && status !== currentStatus) {
      await cmdbModel.updateItemStatus(id, status);
    }

    await emitCmdbUpdate(cmdbModel);

    // Return the updated item WITH services (so frontend gets the updated service statuses)
    const finalResult = await cmdbModel.getItemById(id);
    const servicesResult = await serviceModel.getServicesByItemId(id);

    res.json({
      ...finalResult.rows[0],
      services: servicesResult.rows
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PATCH: Update item status
router.patch('/:id/status', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;
  
  if (!status) {
    return res.status(400).json({ error: 'Status is required' });
  }
  
  try {
    const result = await cmdbModel.updateItemStatus(id, status);
    await emitCmdbUpdate(cmdbModel);
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PATCH: Update item group
router.patch('/:id/group', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { group_id, order_in_group } = req.body;
  
  try {
    const result = await cmdbModel.updateItemGroup(id, group_id, order_in_group);
    await emitCmdbUpdate(cmdbModel);
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PATCH: Reorder item within group - MUST BE BEFORE /:id route
router.patch('/:id/reorder', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { new_order } = req.body;

  if (typeof new_order !== 'number') {
    return res.status(400).json({ error: 'new_order must be a number' });
  }

  try {
    const result = await cmdbModel.reorderItemInGroup(id, new_order);
    await emitCmdbUpdate(cmdbModel);
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete item
router.delete('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  try {
    await cmdbModel.deleteItem(id);
    await emitCmdbUpdate(cmdbModel);
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update connection between items
router.put('/connections/:sourceId/:targetId', authenticateToken, async (req, res) => {
  const { sourceId, targetId } = req.params;
  const { workspace_id, connection_type, direction } = req.body;

  if (!workspace_id) {
    return res.status(400).json({ error: 'workspace_id is required' });
  }

  if (!connection_type || !direction) {
    return res.status(400).json({ error: 'connection_type and direction are required' });
  }

  try {
    const result = await connectionModel.updateConnection(
      sourceId,
      targetId,
      workspace_id,
      connection_type,
      direction
    );
    await emitCmdbUpdate(cmdbModel);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Connection not found' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete connection
router.delete('/connections/:sourceId/:targetId', authenticateToken, async (req, res) => {
  const { sourceId, targetId } = req.params;
  try {
    await connectionModel.deleteConnection(sourceId, targetId);
    await emitCmdbUpdate(cmdbModel);
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete item-to-service connection
router.delete('/connections/item-to-service/:sourceId/:targetServiceId', authenticateToken, async (req, res) => {
  const { sourceId, targetServiceId } = req.params;
  try {
    await pool.query(
      'DELETE FROM connections WHERE source_id = $1 AND target_service_id = $2',
      [sourceId, targetServiceId]
    );
    await emitCmdbUpdate(cmdbModel);
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete item-to-service-item connection
router.delete('/connections/item-to-service-item/:sourceId/:targetServiceItemId', authenticateToken, async (req, res) => {
  const { sourceId, targetServiceItemId } = req.params;
  try {
    const result = await pool.query(
      'DELETE FROM connections WHERE source_id = $1 AND target_service_item_id = $2 RETURNING *',
      [sourceId, targetServiceItemId]
    );
    await emitCmdbUpdate(cmdbModel);
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/connections/to-group/:sourceId/:targetGroupId', authenticateToken, async (req, res) => {
  const { sourceId, targetGroupId } = req.params;
  try {
    await pool.query(
      'DELETE FROM connections WHERE source_id = $1 AND target_group_id = $2',
      [sourceId, targetGroupId]
    );
    await emitCmdbUpdate(cmdbModel);
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete service-to-item connection
router.delete('/connections/from-service/:sourceServiceId/:targetItemId', authenticateToken, async (req, res) => {
  const { sourceServiceId, targetItemId } = req.params;
  try {
    const result = await pool.query(
      'DELETE FROM connections WHERE source_service_id = $1 AND target_id = $2 RETURNING *',
      [sourceServiceId, targetItemId]
    );
    await emitCmdbUpdate(cmdbModel);
    res.status(204).send();
  } catch (err) {
    console.error('Delete service-to-item error:', err);
    res.status(500).json({ error: err.message });
  }
});

// Delete service-item-to-item connection
router.delete('/connections/service-item-to-item/:sourceServiceItemId/:targetItemId', authenticateToken, async (req, res) => {
  const { sourceServiceItemId, targetItemId } = req.params;
  try {
    const result = await pool.query(
      'DELETE FROM connections WHERE source_service_item_id = $1 AND target_id = $2 RETURNING *',
      [sourceServiceItemId, targetItemId]
    );
    await emitCmdbUpdate(cmdbModel);
    res.status(204).send();
  } catch (err) {
    console.error('Delete service-item-to-item error:', err);
    res.status(500).json({ error: err.message });
  }
});

router.post('/connections/from-group', authenticateToken, async (req, res) => {
  const { source_group_id, target_id, workspace_id } = req.body;
  
  if (!source_group_id || !target_id) {
    return res.status(400).json({ error: 'source_group_id and target_id are required' });
  }
  
  if (!workspace_id) {
    return res.status(400).json({ error: 'workspace_id is required' });
  }
  
  try {
    const result = await connectionModel.createGroupToItemConnection(source_group_id, target_id, workspace_id);
    await emitCmdbUpdate(cmdbModel);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/connections/from-group/:sourceGroupId/:targetId', authenticateToken, async (req, res) => {
  const { sourceGroupId, targetId } = req.params;
  try {
    await connectionModel.deleteGroupToItemConnection(sourceGroupId, targetId);
    await emitCmdbUpdate(cmdbModel);
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update group-to-item connection type
router.put('/connections/from-group/:sourceGroupId/:targetId', authenticateToken, async (req, res) => {
  const { sourceGroupId, targetId } = req.params;
  const { workspace_id, connection_type, direction } = req.body;

  if (!workspace_id || !connection_type || !direction) {
    return res.status(400).json({ error: 'workspace_id, connection_type, and direction are required' });
  }

  try {
    const result = await connectionModel.updateGroupItemConnection(sourceGroupId, targetId, workspace_id, connection_type, direction);
    await emitCmdbUpdate(cmdbModel);
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update item-to-group connection type
router.put('/connections/to-group/:sourceId/:targetGroupId', authenticateToken, async (req, res) => {
  const { sourceId, targetGroupId } = req.params;
  const { workspace_id, connection_type, direction } = req.body;

  if (!workspace_id || !connection_type || !direction) {
    return res.status(400).json({ error: 'workspace_id, connection_type, and direction are required' });
  }

  try {
    const result = await connectionModel.updateItemGroupConnection(sourceId, targetGroupId, workspace_id, connection_type, direction);
    await emitCmdbUpdate(cmdbModel);
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/trigger-update', authenticateToken, async (req, res) => {
  try {
    await emitCmdbUpdate(cmdbModel);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;