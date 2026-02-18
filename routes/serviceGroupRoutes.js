const express = require('express');
const router = express.Router();
const serviceGroupModel = require('../models/serviceGroupModel');
const { emitCmdbUpdate } = require('../socket');
const cmdbModel = require('../models/cmdbModel');
const { authenticateToken } = require('../middleware/auth');

// ==================== SERVICE GROUPS ROUTES ====================

router.get('/:serviceId', authenticateToken, async (req, res) => {
  const { serviceId } = req.params;
  const { workspace_id } = req.query;
  if (!workspace_id) return res.status(400).json({ error: 'workspace_id is required' });
  try {
    const result = await serviceGroupModel.getAllServiceGroups(serviceId, workspace_id);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/', authenticateToken, async (req, res) => {
  const { service_id, name, description, color, position, workspace_id } = req.body;
  if (!service_id || !name || !workspace_id) {
    return res.status(400).json({ error: 'service_id, name, dan workspace_id wajib diisi' });
  }
  try {
    const result = await serviceGroupModel.createServiceGroup(service_id, name, description, color, position, workspace_id);
    await emitCmdbUpdate(cmdbModel);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { name, description, color, position } = req.body;
  if (!name) return res.status(400).json({ error: 'name wajib diisi' });
  try {
    const result = await serviceGroupModel.updateServiceGroup(id, name, description, color, position);
    await emitCmdbUpdate(cmdbModel);
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

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

router.put('/:id/position', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { position, skipEmit } = req.body;
  try {
    const result = await serviceGroupModel.updateServiceGroupPosition(id, position);
    if (!skipEmit) await emitCmdbUpdate(cmdbModel);
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ==================== SERVICE GROUP CONNECTIONS ROUTES ====================

router.get('/:serviceId/connections', authenticateToken, async (req, res) => {
  const { serviceId } = req.params;
  const { workspace_id } = req.query;
  if (!workspace_id) return res.status(400).json({ error: 'workspace_id is required' });
  try {
    const result = await serviceGroupModel.getAllServiceGroupConnections(serviceId, workspace_id);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Group-to-group connection
router.post('/connections', authenticateToken, async (req, res) => {
  const { service_id, source_id, target_id, workspace_id } = req.body;
  if (!service_id || !source_id || !target_id || !workspace_id) {
    return res.status(400).json({ error: 'service_id, source_id, target_id, dan workspace_id wajib diisi' });
  }
  try {
    const result = await serviceGroupModel.createServiceGroupConnection(service_id, source_id, target_id, workspace_id);
    await emitCmdbUpdate(cmdbModel);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Group-to-item connection
// PERBAIKAN: terima target_item_id bukan target_id
router.post('/connections/to-item', authenticateToken, async (req, res) => {
  const { service_id, source_group_id, target_item_id, workspace_id } = req.body;
  if (!service_id || !source_group_id || !target_item_id || !workspace_id) {
    return res.status(400).json({ error: 'service_id, source_group_id, target_item_id, dan workspace_id wajib diisi' });
  }
  try {
    const result = await serviceGroupModel.createServiceGroupToItemConnection(
      service_id, source_group_id, target_item_id, workspace_id
    );
    await emitCmdbUpdate(cmdbModel);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete group-to-group connection
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

// Delete group-to-item connection
// PERBAIKAN: param terakhir adalah targetItemId (bukan targetId generik)
router.delete('/connections/to-item/:serviceId/:sourceGroupId/:targetItemId', authenticateToken, async (req, res) => {
  const { serviceId, sourceGroupId, targetItemId } = req.params;
  try {
    await serviceGroupModel.deleteServiceGroupToItemConnection(serviceId, sourceGroupId, targetItemId);
    await emitCmdbUpdate(cmdbModel);
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Item-to-group connection
router.post('/connections/from-item', authenticateToken, async (req, res) => {
  const { service_id, source_id, target_group_id, workspace_id } = req.body;
  if (!service_id || !source_id || !target_group_id || !workspace_id) {
    return res.status(400).json({ error: 'service_id, source_id, target_group_id, dan workspace_id wajib diisi' });
  }
  try {
    const result = await serviceGroupModel.createItemToGroupConnection(
      service_id, source_id, target_group_id, workspace_id
    );
    await emitCmdbUpdate(cmdbModel);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete item-to-group connection
router.delete('/connections/from-item/:serviceId/:sourceId/:targetGroupId', authenticateToken, async (req, res) => {
  const { serviceId, sourceId, targetGroupId } = req.params;
  try {
    await serviceGroupModel.deleteItemToGroupConnection(serviceId, sourceId, targetGroupId);
    await emitCmdbUpdate(cmdbModel);
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ==================== SERVICE ITEM GROUP ASSIGNMENT ROUTES ====================

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

router.patch('/items/:id/reorder', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { new_order } = req.body;
  if (new_order === undefined || new_order === null) {
    return res.status(400).json({ error: 'new_order wajib diisi' });
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