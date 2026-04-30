const express = require('express');
const router = express.Router();
const pool = require('../db');
const serviceModel = require('../models/serviceModel');
const cmdbModel = require('../models/cmdbModel');
const { emitCmdbUpdate, emitServiceUpdate, emitServiceItemStatusUpdate } = require('../socket');
const upload = require('../config/upload');
const fs = require('fs');
const path = require('path');
const { authenticateToken } = require('../middleware/auth');

// ==================== SERVICES ROUTES ====================

// Get a single service by ID (more specific route to avoid conflict with :cmdbItemId)
router.get('/single/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;

  try {
    const result = await serviceModel.getServiceById(id);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Service not found' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get all services for a CMDB item
router.get('/:cmdbItemId', authenticateToken, async (req, res) => {
  const { cmdbItemId } = req.params;

  try {
    const result = await serviceModel.getServicesByItemId(cmdbItemId);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Create a new service
router.post('/', authenticateToken, async (req, res) => {
  const { cmdb_item_id, name, status, icon_type, icon_name, description } = req.body;

  if (!cmdb_item_id || !name) {
    return res.status(400).json({ error: 'cmdb_item_id and name are required' });
  }

  try {
    let iconPath = null;

    // Handle icon file upload if present
    if (req.file && icon_type === 'upload') {
      iconPath = `/uploads/${req.file.filename}`;
    }

    const result = await serviceModel.createService(
      cmdb_item_id,
      name,
      status || 'active',
      icon_type || 'preset',
      iconPath,
      icon_name,
      description
    );

    await emitCmdbUpdate(cmdbModel);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Upload/update service icon (separate endpoint for file upload)
router.post('/:id/upload-icon', authenticateToken, upload.single('icon'), async (req, res) => {
  const { id } = req.params;

  if (!req.file) {
    return res.status(400).json({ error: 'No icon file uploaded' });
  }

  try {
    const iconPath = `/uploads/${req.file.filename}`;

    // Delete old icon if it was an uploaded file
    const existingService = await serviceModel.getServiceById(id);
    if (existingService.rows.length > 0) {
      const service = existingService.rows[0];
      if (service.icon_path) {
        const fullPath = path.join(__dirname, '..', service.icon_path);
        if (fs.existsSync(fullPath)) {
          fs.unlinkSync(fullPath);
        }
      }
    }

    const result = await serviceModel.updateServiceIcon(id, 'upload', iconPath, null);
    await emitCmdbUpdate(cmdbModel);
    res.json(result.rows[0]);
  } catch (err) {
    // Delete uploaded file if error
    if (req.file) {
      fs.unlinkSync(req.file.path);
    }
    res.status(500).json({ error: err.message });
  }
});

// Update service
router.put('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { name, status, description } = req.body;

  if (!name) {
    return res.status(400).json({ error: 'name is required' });
  }

  try {
    const result = await serviceModel.updateService(id, name, status, description);
    await emitCmdbUpdate(cmdbModel);
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update service icon
router.put('/:id/icon', authenticateToken, upload.single('icon'), async (req, res) => {
  const { id } = req.params;
  const { icon_type, icon_name } = req.body;

  if (!icon_type) {
    return res.status(400).json({ error: 'icon_type is required' });
  }

  try {
    let iconPath = null;

    // Get existing service to preserve icon if needed
    const existingServiceResult = await pool.query('SELECT * FROM services WHERE id = $1', [id]);
    if (existingServiceResult.rows.length === 0) {
      return res.status(404).json({ error: 'Service not found' });
    }
    const existingService = existingServiceResult.rows[0];

    // Handle uploaded icon
    if (req.file && icon_type === 'upload') {
      iconPath = `/uploads/${req.file.filename}`;

      // Delete old icon if it was an uploaded file
      if (existingService.icon_path) {
        const fullPath = path.join(__dirname, '..', existingService.icon_path);
        if (fs.existsSync(fullPath)) {
          fs.unlinkSync(fullPath);
        }
      }
    } else if (icon_type === 'upload' && !req.file) {
      // Keep existing icon path if no new file uploaded
      iconPath = existingService.icon_path;
    }

    const result = await serviceModel.updateServiceIcon(id, icon_type, iconPath, icon_name);
    await emitCmdbUpdate(cmdbModel);
    res.json(result.rows[0]);
  } catch (err) {
    // Delete uploaded file if error
    if (req.file) {
      fs.unlinkSync(req.file.path);
    }
    res.status(500).json({ error: err.message });
  }
});

// Delete service
router.delete('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;

  try {
    // Delete service icon if it was an uploaded file
    const existingService = await serviceModel.getServiceById(id);
    if (existingService.rows.length > 0) {
      const iconPath = existingService.rows[0].icon_path;
      if (iconPath) {
        const fullPath = path.join(__dirname, '..', iconPath);
        if (fs.existsSync(fullPath)) {
          fs.unlinkSync(fullPath);
        }
      }
    }

    await serviceModel.deleteService(id);
    await emitCmdbUpdate(cmdbModel);
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update service position (as independent node)
router.put('/:id/position', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { position, skipEmit } = req.body;

  if (!position || typeof position.x !== 'number' || typeof position.y !== 'number') {
    return res.status(400).json({ error: 'Invalid position format' });
  }

  try {
    const result = await serviceModel.updateServicePosition(id, position);

    if (!skipEmit) {
      await emitCmdbUpdate(cmdbModel);
    }

    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update service dimensions
router.put('/:id/dimensions', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { width, height } = req.body;

  if (typeof width !== 'number' || typeof height !== 'number') {
    return res.status(400).json({ error: 'Invalid dimensions format' });
  }

  try {
    const result = await serviceModel.updateServiceDimensions(id, width, height);
    await emitCmdbUpdate(cmdbModel);
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Toggle service expanded state
router.patch('/:id/toggle-expanded', authenticateToken, async (req, res) => {
  const { id } = req.params;

  try {
    const result = await serviceModel.toggleServiceExpanded(id);
    await emitCmdbUpdate(cmdbModel);
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get all services for workspace (as nodes)
router.get('/workspace/:workspaceId', authenticateToken, async (req, res) => {
  const { workspaceId } = req.params;

  try {
    const result = await serviceModel.getServicesWithItemCounts(workspaceId);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update service status only
router.patch('/:id/status', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;

  if (!status) {
    return res.status(400).json({ error: 'status is required' });
  }

  const validStatuses = ['active', 'inactive', 'maintenance', 'disabled', 'decommissioned'];
  if (!validStatuses.includes(status)) {
    return res.status(400).json({ error: 'Invalid status value. Must be active, inactive, maintenance, disabled, or decommissioned' });
  }

  try {
    // Get service first
    const serviceResult = await serviceModel.getServiceById(id);
    if (serviceResult.rows.length === 0) {
      return res.status(404).json({ error: 'Service not found' });
    }
    const service = serviceResult.rows[0];

    // Try to get workspace_id from service items first
    let workspaceId = null;
    const itemsResult = await serviceModel.getAllServiceItems(id, null);

    if (itemsResult.rows.length > 0) {
      workspaceId = itemsResult.rows[0].workspace_id;
    } else {
      // If no service items, get workspace_id from cmdb_item
      const cmdbModel = require('../models/cmdbModel');
      const cmdbResult = await cmdbModel.getItemById(service.cmdb_item_id);
      if (cmdbResult.rows.length > 0) {
        workspaceId = cmdbResult.rows[0].workspace_id;
      }
    }

    if (!workspaceId) {
      const result = await serviceModel.updateServiceStatus(id, status);
      return res.json(result.rows[0]);
    }
    const result = await serviceModel.updateServiceStatus(id, status);

    // Log sebelum emit untuk debugging
    console.log(`🔧 Backend: Emitting service_update for serviceId=${id}, workspaceId=${workspaceId}`);
    await emitServiceUpdate(id, workspaceId);

    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// NEW: Manually trigger recursive propagation from a service
router.post('/:id/propagate-status', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { status, max_depth = 10 } = req.body;

  if (!status) {
    return res.status(400).json({ error: 'status is required' });
  }

  const validStatuses = ['active', 'inactive', 'maintenance', 'disabled', 'decommissioned'];
  if (!validStatuses.includes(status)) {
    return res.status(400).json({ error: 'Invalid status value. Must be active, inactive, maintenance, disabled, or decommissioned' });
  }

  try {
    // Get service first
    const serviceResult = await serviceModel.getServiceById(id);
    if (serviceResult.rows.length === 0) {
      return res.status(404).json({ error: 'Service not found' });
    }
    const service = serviceResult.rows[0];

    // Try to get workspace_id from service items first
    let workspaceId = null;
    const itemsResult = await serviceModel.getAllServiceItems(id, null);

    if (itemsResult.rows.length > 0) {
      workspaceId = itemsResult.rows[0].workspace_id;
    } else {
      // If no service items, get workspace_id from cmdb_item
      const cmdbModel = require('../models/cmdbModel');
      const cmdbResult = await cmdbModel.getItemById(service.cmdb_item_id);
      if (cmdbResult.rows.length > 0) {
        workspaceId = cmdbResult.rows[0].workspace_id;
      }
    }

    if (!workspaceId) {
      return res.status(400).json({ error: 'Could not determine workspace_id for service' });
    }

    // First update the service status itself
    await serviceModel.updateServiceStatus(id, status);

    // Then trigger recursive propagation to connected services
    console.log(`🔄 Manual recursive propagation triggered for service ${id} with status ${status}, max_depth=${max_depth}`);
    const affectedServices = await serviceModel.propagateStatusToConnectedServices(
      id,
      status,
      workspaceId,
      new Set([id]), // Start with current service already visited
      0,
      max_depth
    );

    // Emit socket update for the workspace
    await emitCmdbUpdate(cmdbModel);

    res.json({
      message: 'Recursive propagation completed successfully',
      source_service_id: parseInt(id),
      status,
      workspace_id: workspaceId,
      affected_services: affectedServices,
      total_affected: affectedServices.length
    });
  } catch (err) {
    console.error('Error during manual recursive propagation:', err);
    res.status(500).json({ error: err.message });
  }
});

// NEW: Get propagation preview (show what would be affected without actually propagating)
router.get('/:id/propagation-preview', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { status } = req.query;

  try {
    // Get service first
    const serviceResult = await serviceModel.getServiceById(id);
    if (serviceResult.rows.length === 0) {
      return res.status(404).json({ error: 'Service not found' });
    }
    const service = serviceResult.rows[0];

    // Try to get workspace_id from service items first
    let workspaceId = null;
    const itemsResult = await serviceModel.getAllServiceItems(id, null);

    if (itemsResult.rows.length > 0) {
      workspaceId = itemsResult.rows[0].workspace_id;
    } else {
      // If no service items, get workspace_id from cmdb_item
      const cmdbModel = require('../models/cmdbModel');
      const cmdbResult = await cmdbModel.getItemById(service.cmdb_item_id);
      if (cmdbResult.rows.length > 0) {
        workspaceId = cmdbResult.rows[0].workspace_id;
      }
    }

    if (!workspaceId) {
      return res.status(400).json({ error: 'Could not determine workspace_id for service' });
    }

    // Get all service-to-service connections from this service
    const pool = require('../db');
    const connectionsResult = await pool.query(
      `SELECT stsc.target_service_id, s.name as target_service_name, s.status as target_service_status,
              stsc.connection_type, stsc.propagation, stsc.direction
       FROM service_to_service_connections stsc
       INNER JOIN services s ON stsc.target_service_id = s.id
       WHERE stsc.source_service_id = $1 AND stsc.workspace_id = $2
       ORDER BY stsc.created_at`,
      [id, workspaceId]
    );

    // Analyze which services would be affected
    const wouldBeAffected = [];
    const wouldNotBeAffected = [];

    for (const connection of connectionsResult.rows) {
      const shouldPropagate =
        (connection.propagation === 'source_to_target' || connection.propagation === 'both') &&
        (status === 'inactive' || status === 'disabled' || status === 'maintenance');

      const onlyIfActive = connection.target_service_status === 'active';

      if (shouldPropagate && onlyIfActive) {
        wouldBeAffected.push({
          service_id: connection.target_service_id,
          service_name: connection.target_service_name,
          current_status: connection.target_service_status,
          would_become: status,
          connection_type: connection.connection_type,
          propagation: connection.propagation,
          direction: connection.direction
        });
      } else {
        wouldNotBeAffected.push({
          service_id: connection.target_service_id,
          service_name: connection.target_service_name,
          current_status: connection.target_service_status,
          reason: !shouldPropagate ? 'Propagation not enabled for this connection type' : 'Target service not active',
          connection_type: connection.connection_type,
          propagation: connection.propagation
        });
      }
    }

    res.json({
      source_service: {
        id: service.id,
        name: service.name,
        current_status: service.status,
        proposed_status: status
      },
      would_be_affected: wouldBeAffected,
      would_not_be_affected: wouldNotBeAffected,
      total_connections: connectionsResult.rows.length,
      summary: {
        would_propagate_to: wouldBeAffected.length,
        would_skip: wouldNotBeAffected.length
      }
    });
  } catch (err) {
    console.error('Error getting propagation preview:', err);
    res.status(500).json({ error: err.message });
  }
});

// ==================== SERVICE ITEMS ROUTES ====================

// Get all service items
router.get('/:serviceId/items', authenticateToken, async (req, res) => {
  const { serviceId } = req.params;
  const { workspace_id } = req.query;

  if (!workspace_id) {
    return res.status(400).json({ error: 'workspace_id is required' });
  }

  try {
    const result = await serviceModel.getAllServiceItems(serviceId, workspace_id);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Create a new service item
router.post('/:serviceId/items', authenticateToken, async (req, res) => {
  const { serviceId } = req.params;
  const { name, type, description, position, status, ip, domain, port, category, location, workspace_id, group_id } = req.body;

  if (!name || !workspace_id) {
    return res.status(400).json({ error: 'name and workspace_id are required' });
  }

  try {
    const result = await serviceModel.createServiceItem(
      serviceId,
      name,
      type,
      description,
      position,
      status,
      ip,
      domain,
      port,
      category,
      location,
      workspace_id,
      group_id
    );

    await emitCmdbUpdate(cmdbModel);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update service item
router.put('/items/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { name, type, description, status, ip, domain, port, category, location, group_id, order_in_group } = req.body;

  if (!name) {
    return res.status(400).json({ error: 'name is required' });
  }

  try {
    // Ambil item data sebelum update untuk mendapatkan service_id yang benar
    const itemBeforeUpdate = await serviceModel.getServiceItemById(id);
    if (itemBeforeUpdate.rows.length === 0) {
      return res.status(404).json({ error: 'Service item not found' });
    }

    const result = await serviceModel.updateServiceItem(id, name, type, description, status, ip, domain, port, category, location, group_id, order_in_group);

    // Emit service update dengan serviceId dan workspaceId dari item SEBELUM update
    // untuk memastikan konsistensi
    await emitServiceUpdate(itemBeforeUpdate.rows[0].service_id, itemBeforeUpdate.rows[0].workspace_id);

    // NEW: Also emit service item status update if status is present in the request
    // This ensures layana-service edges update in real-time when service item status changes through the form
    if (status !== undefined && status !== itemBeforeUpdate.rows[0].status) {
      await emitServiceItemStatusUpdate(id, status, itemBeforeUpdate.rows[0].workspace_id, itemBeforeUpdate.rows[0].service_id);
      console.log(`✅ Emitted service_item_status_update on PUT: item=${id}, status=${status}, service=${itemBeforeUpdate.rows[0].service_id}`);

      // Trigger propagation if status changed to problematic state
      if (status === 'inactive' || status === 'maintenance' || status === 'decommissioned') {
        console.log(`🔄 Triggering cross-service propagation from PUT endpoint for item ${id}...`);
        const crossServiceConnectionModel = require('../models/crossServiceConnectionModel');
        const affectedServiceItems = await crossServiceConnectionModel.propagateStatusToConnectedServiceItems(
          id,
          status,
          itemBeforeUpdate.rows[0].workspace_id,
          new Set([id]),
          0,
          10
        );
        console.log(`✅ Cross-service propagation from PUT: affected ${affectedServiceItems.length} items`);
      }
    }

    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update service item position
router.put('/items/:id/position', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { position, skipRefresh } = req.body;

  if (!position || typeof position.x !== 'number' || typeof position.y !== 'number') {
    return res.status(400).json({ error: 'Invalid position format' });
  }

  try {
    // Ambil item data sebelum update untuk mendapatkan service_id yang benar
    const itemBeforeUpdate = await serviceModel.getServiceItemById(id);
    if (itemBeforeUpdate.rows.length === 0) {
      return res.status(404).json({ error: 'Service item not found' });
    }

    const result = await serviceModel.updateServiceItemPosition(id, position);

    // Hanya emit service update jika skipRefresh tidak true
    // skipRefresh digunakan untuk mencegah socket event ke services lain
    if (!skipRefresh) {
      // Emit service update dengan serviceId dan workspaceId dari item SEBELUM update
      await emitServiceUpdate(itemBeforeUpdate.rows[0].service_id, itemBeforeUpdate.rows[0].workspace_id);
    } else {
      console.log(`⏭️ Skipping service update emit for item ${id} (skipRefresh=true)`);
    }

    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update service item status only
router.patch('/items/:id/status', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;

  if (!status) {
    return res.status(400).json({ error: 'status is required' });
  }

  const validStatuses = ['active', 'inactive', 'maintenance', 'disabled', 'decommissioned'];
  if (!validStatuses.includes(status)) {
    return res.status(400).json({ error: 'Invalid status value. Must be active, inactive, maintenance, disabled, or decommissioned' });
  }

  try {
    // Get service item first to obtain service_id and workspace_id
    const itemResult = await serviceModel.getServiceItemById(id);
    if (itemResult.rows.length === 0) {
      return res.status(404).json({ error: 'Service item not found' });
    }
    const item = itemResult.rows[0];

    const result = await serviceModel.updateServiceItemStatus(id, status);
    // Emit both service update (for nodes) and service item status update (for hover cards)
    await emitServiceUpdate(item.service_id, item.workspace_id);
    await emitServiceItemStatusUpdate(id, status, item.workspace_id, item.service_id);
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete service item
router.delete('/items/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;

  try {
    // Get item data first before deleting
    const itemResult = await serviceModel.getServiceItemById(id);
    if (itemResult.rows.length === 0) {
      return res.status(404).json({ error: 'Service item not found' });
    }
    const item = itemResult.rows[0];

    await serviceModel.deleteServiceConnectionsByItemId(id);
    await serviceModel.deleteServiceItem(id);

    // Emit service update dengan serviceId dan workspaceId
    await emitServiceUpdate(item.service_id, item.workspace_id);

    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ==================== CROSS-SERVICE PROPAGATION FOR SERVICE ITEMS ====================

// Manually trigger cross-service propagation from a service item
router.post('/items/:serviceItemId/propagate-status', authenticateToken, async (req, res) => {
  const { serviceItemId } = req.params;
  const { status, max_depth = 10 } = req.body;

  if (!status) {
    return res.status(400).json({ error: 'status is required' });
  }

  const validStatuses = ['active', 'inactive', 'maintenance', 'disabled', 'decommissioned'];
  if (!validStatuses.includes(status)) {
    return res.status(400).json({ error: 'Invalid status value. Must be active, inactive, maintenance, disabled, or decommissioned' });
  }

  try {
    // Get service item first to obtain workspace_id
    const itemResult = await serviceModel.getServiceItemById(serviceItemId);
    if (itemResult.rows.length === 0) {
      return res.status(404).json({ error: 'Service item not found' });
    }
    const item = itemResult.rows[0];

    // Get cross-service connection model
    const crossServiceConnectionModel = require('../models/crossServiceConnectionModel');

    // Perform cross-service propagation
    const affectedServiceItems = await crossServiceConnectionModel.propagateStatusToConnectedServiceItems(
      parseInt(serviceItemId),
      status,
      item.workspace_id,
      new Set([parseInt(serviceItemId)]), // Start with current service item already visited
      0,
      parseInt(max_depth)
    );

    // Emit socket events for all affected service items and their services
    const { emitServiceUpdate, emitServiceItemStatusUpdate } = require('../socket');
    for (const affectedItemId of affectedServiceItems) {
      // Get affected service item details to emit proper events
      const affectedItemResult = await serviceModel.getServiceItemById(affectedItemId);
      if (affectedItemResult.rows.length > 0) {
        const affectedItem = affectedItemResult.rows[0];
        await emitServiceItemStatusUpdate(affectedItemId, status, item.workspace_id, affectedItem.service_id);
        await emitServiceUpdate(affectedItem.service_id, item.workspace_id);
        console.log(`✅ Emitted cross-service propagated updates: item=${affectedItemId}, service=${affectedItem.service_id}, status=${status}`);
      }
    }

    res.json({
      message: 'Cross-service status propagation completed',
      sourceServiceItemId: serviceItemId,
      status: status,
      affectedServiceItems: affectedServiceItems,
      count: affectedServiceItems.length
    });
  } catch (err) {
    console.error('Error propagating cross-service status:', err);
    res.status(500).json({ error: err.message });
  }
});

// Get cross-service propagation preview for a service item
router.get('/items/:serviceItemId/propagation-preview', authenticateToken, async (req, res) => {
  const { serviceItemId } = req.params;
  const { status } = req.query;

  if (!status) {
    return res.status(400).json({ error: 'status parameter is required' });
  }

  try {
    // Get service item first
    const itemResult = await serviceModel.getServiceItemById(serviceItemId);
    if (itemResult.rows.length === 0) {
      return res.status(404).json({ error: 'Service item not found' });
    }
    const item = itemResult.rows[0];

    // Get cross-service connection model
    const crossServiceConnectionModel = require('../models/crossServiceConnectionModel');

    // Get outgoing connections to see what would be affected
    const connectionsResult = await crossServiceConnectionModel.getCrossServiceConnectionsByServiceItemId(
      serviceItemId
    );

    // Filter to get only outgoing connections (where this service item is the source)
    const outgoingConnections = connectionsResult.rows.filter(conn => conn.source_service_item_id === parseInt(serviceItemId));

    const preview = await Promise.all(outgoingConnections.map(async (conn) => {
      const wouldAffect = conn.target_status === 'active' && conn.propagation_enabled;
      const connTypeDef = await crossServiceConnectionModel.getConnectionTypeDefinition(conn.connection_type);
      const propagation = connTypeDef?.propagation || 'both';

      return {
        connection: `${conn.source_name} → ${conn.target_name}`,
        source_service_item: conn.source_name,
        target_service_item: conn.target_name,
        source_service: conn.source_service_name,
        target_service: conn.target_service_name,
        connection_type: conn.connection_type,
        propagation: propagation,
        propagation_enabled: conn.propagation_enabled,
        would_affect: wouldAffect,
        current_status: conn.target_status,
        new_status: wouldAffect ? status : conn.target_status
      };
    }));

    res.json({
      source_service_item_id: serviceItemId,
      source_service_item_name: item.name,
      status: status,
      affected_connections: preview,
      total_connections: preview.length,
      would_affect_count: preview.filter(p => p.would_affect).length
    });
  } catch (err) {
    console.error('Error getting cross-service propagation preview:', err);
    res.status(500).json({ error: err.message });
  }
});

// ==================== SERVICE CONNECTIONS ROUTES ====================

// Get all service connections
router.get('/:serviceId/connections', authenticateToken, async (req, res) => {
  const { serviceId } = req.params;
  const { workspace_id } = req.query;

  if (!workspace_id) {
    return res.status(400).json({ error: 'workspace_id is required' });
  }

  try {
    const result = await serviceModel.getAllServiceConnections(serviceId, workspace_id);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Create a new service connection
router.post('/:serviceId/connections', authenticateToken, async (req, res) => {
  const { serviceId } = req.params;
  const { source_id, target_id, workspace_id, connection_type, propagation } = req.body;

  if (!source_id || !target_id || !workspace_id) {
    return res.status(400).json({ error: 'source_id, target_id, and workspace_id are required' });
  }

  try {
    const result = await serviceModel.createServiceConnection(
      serviceId,
      source_id,
      target_id,
      workspace_id,
      connection_type || 'connects_to',
      propagation || 'source_to_target'
    );
    await emitCmdbUpdate(cmdbModel);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update service connection type and propagation
router.put('/:serviceId/connections/:sourceId/:targetId', authenticateToken, async (req, res) => {
  const { serviceId, sourceId, targetId } = req.params;
  const { connection_type, propagation } = req.body;

  if (!connection_type || !propagation) {
    return res.status(400).json({ error: 'connection_type and propagation are required' });
  }

  try {
    const result = await serviceModel.updateServiceConnection(
      serviceId,
      sourceId,
      targetId,
      connection_type,
      propagation
    );
    await emitCmdbUpdate(cmdbModel);
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete service connection
router.delete('/:serviceId/connections/:sourceId/:targetId', authenticateToken, async (req, res) => {
  const { serviceId, sourceId, targetId } = req.params;

  try {
    await serviceModel.deleteServiceConnection(serviceId, sourceId, targetId);
    await emitCmdbUpdate(cmdbModel);
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
