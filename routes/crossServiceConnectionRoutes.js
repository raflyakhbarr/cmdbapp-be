const express = require('express');
const router = express.Router();
const crossServiceConnectionModel = require('../models/crossServiceConnectionModel');
const { authenticateToken } = require('../middleware/auth');
const { emitServiceUpdate } = require('../socket');

// ==================== CROSS-SERVICE CONNECTION ROUTES ====================

// Get all cross-service connections for a workspace
router.get('/workspace/:workspaceId', authenticateToken, async (req, res) => {
  const { workspaceId } = req.params;

  try {
    const result = await crossServiceConnectionModel.getCrossServiceConnectionsByWorkspace(workspaceId);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get connections for a specific service item
router.get('/service-item/:serviceItemId', authenticateToken, async (req, res) => {
  const { serviceItemId } = req.params;

  try {
    const result = await crossServiceConnectionModel.getCrossServiceConnectionsByServiceItemId(serviceItemId);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get connection between two specific service items
router.get('/between/:sourceId/:targetId', authenticateToken, async (req, res) => {
  const { sourceId, targetId } = req.params;

  try {
    const result = await crossServiceConnectionModel.getCrossServiceConnectionBetweenItems(sourceId, targetId);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get available service items for connection
router.get('/available/:workspaceId/:currentServiceItemId', authenticateToken, async (req, res) => {
  const { workspaceId, currentServiceItemId } = req.params;

  try {
    const result = await crossServiceConnectionModel.getAvailableServiceItemsForConnection(
      workspaceId,
      currentServiceItemId
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Create a new cross-service connection
router.post('/', authenticateToken, async (req, res) => {
  const { source_service_item_id, target_service_item_id, workspace_id, connection_type, direction } = req.body;

  // Validation
  if (!source_service_item_id || !target_service_item_id || !workspace_id) {
    return res.status(400).json({
      error: 'source_service_item_id, target_service_item_id, and workspace_id are required'
    });
  }

  if (source_service_item_id === target_service_item_id) {
    return res.status(400).json({ error: 'Cannot connect to itself' });
  }

  try {
    const result = await crossServiceConnectionModel.createCrossServiceConnection(
      source_service_item_id,
      target_service_item_id,
      workspace_id,
      connection_type || 'connects_to',
      direction || 'forward'
    );

    // Emit socket update for both service items
    await emitServiceUpdate(source_service_item_id, workspace_id);
    await emitServiceUpdate(target_service_item_id, workspace_id);

    res.status(201).json(result.rows[0]);
  } catch (err) {
    if (err.code === '23505') { // Unique violation
      return res.status(409).json({ error: 'Connection already exists' });
    }
    if (err.code === '23503') { // Foreign key violation
      return res.status(404).json({ error: 'Service item not found' });
    }
    res.status(500).json({ error: err.message });
  }
});

// Update an existing cross-service connection
router.put('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { connection_type, direction } = req.body;

  if (!connection_type || !direction) {
    return res.status(400).json({ error: 'connection_type and direction are required' });
  }

  try {
    const result = await crossServiceConnectionModel.updateCrossServiceConnectionById(
      id,
      connection_type,
      direction
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Connection not found' });
    }

    // Emit socket update for both service items
    await emitServiceUpdate(result.rows[0].source_service_item_id, req.body.workspace_id);
    await emitServiceUpdate(result.rows[0].target_service_item_id, req.body.workspace_id);

    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update connection by source and target IDs
router.put('/between/:sourceId/:targetId', authenticateToken, async (req, res) => {
  const { sourceId, targetId } = req.params;
  const { workspace_id, connection_type, direction } = req.body;

  if (!workspace_id || !connection_type || !direction) {
    return res.status(400).json({ error: 'workspace_id, connection_type, and direction are required' });
  }

  try {
    const result = await crossServiceConnectionModel.updateCrossServiceConnection(
      sourceId,
      targetId,
      workspace_id,
      connection_type,
      direction
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Connection not found' });
    }

    // Emit socket update for both service items
    await emitServiceUpdate(sourceId, workspace_id);
    await emitServiceUpdate(targetId, workspace_id);

    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete a cross-service connection
router.delete('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;

  try {
    // Get connection details first for socket updates
    const connectionResult = await crossServiceConnectionModel.getCrossServiceConnectionById(id);
    if (connectionResult.rows.length === 0) {
      return res.status(404).json({ error: 'Connection not found' });
    }

    const connection = connectionResult.rows[0];
    const result = await crossServiceConnectionModel.deleteCrossServiceConnectionById(id);

    // Emit socket update for both service items
    await emitServiceUpdate(connection.source_service_item_id, connection.workspace_id);
    await emitServiceUpdate(connection.target_service_item_id, connection.workspace_id);

    res.json({ message: 'Connection deleted successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete connection by source and target IDs
router.delete('/between/:sourceId/:targetId', authenticateToken, async (req, res) => {
  const { sourceId, targetId } = req.params;

  try {
    // Get connection details first for socket updates
    const connectionResult = await crossServiceConnectionModel.getCrossServiceConnectionBetweenItems(sourceId, targetId);
    if (connectionResult.rows.length === 0) {
      return res.status(404).json({ error: 'Connection not found' });
    }

    const connection = connectionResult.rows[0];
    const result = await crossServiceConnectionModel.deleteCrossServiceConnection(sourceId, targetId);

    // Emit socket update for both service items
    await emitServiceUpdate(sourceId, connection.workspace_id);
    await emitServiceUpdate(targetId, connection.workspace_id);

    res.json({ message: 'Connection deleted successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
