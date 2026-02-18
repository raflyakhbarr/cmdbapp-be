const express = require('express');
const router = express.Router();
const serviceGroupModel = require('../models/serviceGroupModel');
const serviceModel = require('../models/serviceModel');
const { emitCmdbUpdate } = require('../socket');
const cmdbModel = require('../models/cmdbModel');
const { authenticateToken } = require('../middleware/auth');

// ==================== SERVICE GROUPS ROUTES ====================

// Get all service groups for a service
router.get('/:serviceId', authenticateToken, async (req, res) => {
  const { serviceId } = req.params;
  const { workspace_id } = req.query;

  if (!workspace_id) {
    return res.status(400).json({ error: 'workspace_id is required' });
  }

  try {
    const result = await serviceGroupModel.getAllServiceGroups(serviceId, workspace_id);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Create a new service group
router.post('/', authenticateToken, async (req, res) => {
  const { service_id, name, description, color, position, workspace_id } = req.body;

  if (!service_id || !name || !workspace_id) {
    return res.status(400).json({ error: 'service_id, name, and workspace_id are required' });
  }

  try {
    const result = await serviceGroupModel.createServiceGroup(
      service_id,
      name,
      description,
      color,
      position,
      workspace_id
    );
    await emitCmdbUpdate(cmdbModel);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update service group
router.put('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { name, description, color, position } = req.body;

  if (!name) {
    return res.status(400).json({ error: 'name is required' });
  }

  try {
    const result = await serviceGroupModel.updateServiceGroup(id, name, description, color, position);
    await emitCmdbUpdate(cmdbModel);
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete service group
router.delete('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;

  try {
    await serviceGroupModel.deleteServiceGroup(id);
    await emitCmdbUpdate(cmdbModel);
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update service group position
router.put('/:id/position', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { position, skipEmit } = req.body;

  try {
    const result = await serviceGroupModel.updateServiceGroupPosition(id, position);

    if (!skipEmit) {
      await emitCmdbUpdate(cmdbModel);
    }

    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ==================== SERVICE GROUP CONNECTIONS ROUTES ====================

// Get all service group connections
router.get('/:serviceId/connections', authenticateToken, async (req, res) => {
  const { serviceId } = req.params;
  const { workspace_id } = req.query;

  if (!workspace_id) {
    return res.status(400).json({ error: 'workspace_id is required' });
  }

  try {
    const result = await serviceGroupModel.getAllServiceGroupConnections(serviceId, workspace_id);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Create service group connection (group-to-group)
router.post('/connections', authenticateToken, async (req, res) => {
  const { service_id, source_id, target_id, workspace_id } = req.body;

  if (!service_id || !source_id || !target_id || !workspace_id) {
    return res.status(400).json({ error: 'service_id, source_id, target_id, and workspace_id are required' });
  }

  try {
    const result = await serviceGroupModel.createServiceGroupConnection(service_id, source_id, target_id, workspace_id);
    await emitCmdbUpdate(cmdbModel);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Create service group to item connection
router.post('/connections/to-item', authenticateToken, async (req, res) => {
  const { service_id, source_group_id, target_id, workspace_id } = req.body;

  if (!service_id || !source_group_id || !target_id || !workspace_id) {
    return res.status(400).json({ error: 'service_id, source_group_id, target_id, and workspace_id are required' });
  }

  try {
    const result = await serviceGroupModel.createServiceGroupToItemConnection(service_id, source_group_id, target_id, workspace_id);
    await emitCmdbUpdate(cmdbModel);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete service group connection
router.delete('/connections/:serviceId/:sourceId/:targetId', authenticateToken, async (req, res) => {
  const { serviceId, sourceId, targetId } = req.params;

  try {
    await serviceGroupModel.deleteServiceGroupConnection(serviceId, sourceId, targetId);
    await emitCmdbUpdate(cmdbModel);
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete service group to item connection
router.delete('/connections/to-item/:serviceId/:sourceGroupId/:targetId', authenticateToken, async (req, res) => {
  const { serviceId, sourceGroupId, targetId } = req.params;

  try {
    await serviceGroupModel.deleteServiceGroupToItemConnection(serviceId, sourceGroupId, targetId);
    await emitCmdbUpdate(cmdbModel);
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ==================== SERVICE ITEM GROUP ASSIGNMENT ROUTES ====================

// Update service item group assignment
router.patch('/items/:id/group', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { group_id, order_in_group } = req.body;

  try {
    const result = await serviceGroupModel.updateServiceItemGroup(id, group_id, order_in_group);
    await emitCmdbUpdate(cmdbModel);
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Reorder service item within group
router.patch('/items/:id/reorder', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { new_order } = req.body;

  if (new_order === undefined || new_order === null) {
    return res.status(400).json({ error: 'new_order is required' });
  }

  try {
    const result = await serviceGroupModel.reorderServiceItemInGroup(id, new_order);
    await emitCmdbUpdate(cmdbModel);
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
