const express = require('express');
const router = express.Router();
const serviceToServiceConnectionModel = require('../models/serviceToServiceConnectionModel');
const serviceModel = require('../models/serviceModel');
const { authenticateToken } = require('../middleware/auth');

// Apply authentication to all routes
router.use(authenticateToken);

// ==================== GET ROUTES ====================

// Get all service-to-service connections for a specific CMDB item
router.get('/item/:itemId', async (req, res) => {
  try {
    const { itemId } = req.params;

    if (!itemId || isNaN(itemId)) {
      return res.status(400).json({ error: 'Invalid CMDB item ID' });
    }

    const result = await serviceToServiceConnectionModel.getServiceToServiceConnectionsByItemId(itemId);
    res.json(result.rows);
  } catch (err) {
    console.error('Error fetching service-to-service connections:', err);
    res.status(500).json({ error: 'Failed to fetch service-to-service connections' });
  }
});

// Get all service-to-service connections for a workspace
router.get('/workspace/:workspaceId', async (req, res) => {
  try {
    const { workspaceId } = req.params;

    if (!workspaceId || isNaN(workspaceId)) {
      return res.status(400).json({ error: 'Invalid workspace ID' });
    }

    const result = await serviceToServiceConnectionModel.getServiceToServiceConnectionsByWorkspace(workspaceId);
    res.json(result.rows);
  } catch (err) {
    console.error('Error fetching workspace service-to-service connections:', err);
    res.status(500).json({ error: 'Failed to fetch workspace service-to-service connections' });
  }
});

// Get a specific service-to-service connection by source and target service IDs
router.get('/service/:sourceServiceId/:targetServiceId', async (req, res) => {
  try {
    const { sourceServiceId, targetServiceId } = req.params;

    if (!sourceServiceId || isNaN(sourceServiceId) || !targetServiceId || isNaN(targetServiceId)) {
      return res.status(400).json({ error: 'Invalid service IDs' });
    }

    const result = await serviceToServiceConnectionModel.getServiceToServiceConnection(sourceServiceId, targetServiceId);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Service-to-service connection not found' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error('Error fetching service-to-service connection:', err);
    res.status(500).json({ error: 'Failed to fetch service-to-service connection' });
  }
});

// Get all connections for a specific service
router.get('/service/:serviceId/connections', async (req, res) => {
  try {
    const { serviceId } = req.params;

    if (!serviceId || isNaN(serviceId)) {
      return res.status(400).json({ error: 'Invalid service ID' });
    }

    const result = await serviceToServiceConnectionModel.getServiceConnections(serviceId);
    res.json(result.rows);
  } catch (err) {
    console.error('Error fetching service connections:', err);
    res.status(500).json({ error: 'Failed to fetch service connections' });
  }
});

// ==================== POST ROUTE ====================

// Create a new service-to-service connection
router.post('/', async (req, res) => {
  const pool = require('../db');
  const client = await pool.connect();

  try {
    const { cmdb_item_id, source_service_id, target_service_id, workspace_id, connection_type, direction, propagation } = req.body;

    // Validation
    if (!cmdb_item_id || !source_service_id || !target_service_id || !workspace_id) {
      return res.status(400).json({
        error: 'Missing required fields: cmdb_item_id, source_service_id, target_service_id, workspace_id'
      });
    }

    if (source_service_id === target_service_id) {
      return res.status(400).json({ error: 'Cannot connect service to itself' });
    }

    await client.query('BEGIN');

    // Verify both services exist (they can be in different CMDB items now - cross-item connections allowed!)
    const servicesCheck = await client.query(
      'SELECT id, cmdb_item_id FROM services WHERE id IN ($1, $2)',
      [source_service_id, target_service_id]
    );

    if (servicesCheck.rows.length !== 2) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'One or both services not found' });
    }

    const sourceService = servicesCheck.rows.find(s => s.id === source_service_id);
    const targetService = servicesCheck.rows.find(s => s.id === target_service_id);

    // Cross-item connections are now allowed! cmdb_item_id can be different

    // Check if connection already exists
    const existingConnection = await client.query(
      'SELECT id FROM service_to_service_connections WHERE source_service_id = $1 AND target_service_id = $2',
      [source_service_id, target_service_id]
    );

    if (existingConnection.rows.length > 0) {
      await client.query('ROLLBACK');
      return res.status(409).json({ error: 'Connection already exists' });
    }

    // Create the connection
    const result = await serviceToServiceConnectionModel.createServiceToServiceConnection(
      cmdb_item_id,
      source_service_id,
      target_service_id,
      workspace_id,
      connection_type || 'connects_to',
      direction || 'forward',
      propagation || 'source_to_target'
    );

    await client.query('COMMIT');

    // Emit socket update
    const { emitCmdbUpdate } = require('../socket');
    await emitCmdbUpdate(workspace_id);

    res.status(201).json(result.rows[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Error creating service-to-service connection:', err);
    res.status(500).json({ error: 'Failed to create service-to-service connection' });
  } finally {
    client.release();
  }
});

// ==================== PUT ROUTE ====================

// Update a service-to-service connection
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { connection_type, direction, propagation } = req.body;

    if (!id || isNaN(id)) {
      return res.status(400).json({ error: 'Invalid connection ID' });
    }

    // Check if connection exists
    const existing = await serviceToServiceConnectionModel.getServiceToServiceConnectionById(id);

    if (existing.rows.length === 0) {
      return res.status(404).json({ error: 'Service-to-service connection not found' });
    }

    const result = await serviceToServiceConnectionModel.updateServiceToServiceConnection(
      id,
      connection_type || existing.rows[0].connection_type,
      direction !== undefined ? direction : existing.rows[0].direction,
      propagation !== undefined ? propagation : existing.rows[0].propagation
    );

    // Emit socket update
    const { emitCmdbUpdate } = require('../socket');
    await emitCmdbUpdate(existing.rows[0].workspace_id);

    res.json(result.rows[0]);
  } catch (err) {
    console.error('Error updating service-to-service connection:', err);
    res.status(500).json({ error: 'Failed to update service-to-service connection' });
  }
});

// ==================== DELETE ROUTES ====================

// Delete a service-to-service connection by ID
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    if (!id || isNaN(id)) {
      return res.status(400).json({ error: 'Invalid connection ID' });
    }

    // Get connection first for workspace_id
    const existing = await serviceToServiceConnectionModel.getServiceToServiceConnectionById(id);

    if (existing.rows.length === 0) {
      return res.status(404).json({ error: 'Service-to-service connection not found' });
    }

    const result = await serviceToServiceConnectionModel.deleteServiceToServiceConnection(id);

    // Emit socket update
    const { emitCmdbUpdate } = require('../socket');
    await emitCmdbUpdate(existing.rows[0].workspace_id);

    res.json({ message: 'Service-to-service connection deleted successfully' });
  } catch (err) {
    console.error('Error deleting service-to-service connection:', err);
    res.status(500).json({ error: 'Failed to delete service-to-service connection' });
  }
});

// Delete a service-to-service connection by source and target service IDs
router.delete('/service/:sourceServiceId/:targetServiceId', async (req, res) => {
  try {
    const { sourceServiceId, targetServiceId } = req.params;

    if (!sourceServiceId || isNaN(sourceServiceId) || !targetServiceId || isNaN(targetServiceId)) {
      return res.status(400).json({ error: 'Invalid service IDs' });
    }

    // Get connection first for workspace_id
    const existing = await serviceToServiceConnectionModel.getServiceToServiceConnection(sourceServiceId, targetServiceId);

    if (existing.rows.length === 0) {
      return res.status(404).json({ error: 'Service-to-service connection not found' });
    }

    const result = await serviceToServiceConnectionModel.deleteServiceToServiceConnectionByServices(
      sourceServiceId,
      targetServiceId
    );

    // Emit socket update
    const { emitCmdbUpdate } = require('../socket');
    await emitCmdbUpdate(existing.rows[0].workspace_id);

    res.json({ message: 'Service-to-service connection deleted successfully' });
  } catch (err) {
    console.error('Error deleting service-to-service connection:', err);
    res.status(500).json({ error: 'Failed to delete service-to-service connection' });
  }
});

module.exports = router;
