const express = require('express');
const router = express.Router();
const externalItemModel = require('../models/externalItemModel');
const { authenticateToken } = require('../middleware/auth');

// ==================== EXTERNAL ITEM POSITION ROUTES ====================

// Get all external item positions for a service
router.get('/service/:serviceId', authenticateToken, async (req, res) => {
  const { workspaceId } = req.query;
  const { serviceId } = req.params;

  if (!workspaceId) {
    return res.status(400).json({ error: 'workspaceId is required' });
  }

  try {
    const result = await externalItemModel.getExternalItemPositionsByService(workspaceId, serviceId);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get position for a specific external item
router.get('/item/:externalServiceItemId', authenticateToken, async (req, res) => {
  const { workspaceId, serviceId } = req.query;
  const { externalServiceItemId } = req.params;

  if (!workspaceId || !serviceId) {
    return res.status(400).json({ error: 'workspaceId and serviceId are required' });
  }

  try {
    const result = await externalItemModel.getExternalItemPosition(workspaceId, serviceId, externalServiceItemId);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Position not found' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Save or update external item position
router.post('/', authenticateToken, async (req, res) => {
  const { workspaceId, serviceId, externalServiceItemId, position } = req.body;

  if (!workspaceId || !serviceId || !externalServiceItemId || !position) {
    return res.status(400).json({
      error: 'workspaceId, serviceId, externalServiceItemId, and position are required'
    });
  }

  try {
    const result = await externalItemModel.saveExternalItemPosition(
      workspaceId,
      serviceId,
      externalServiceItemId,
      position
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete external item position
router.delete('/:serviceId/:externalServiceItemId', authenticateToken, async (req, res) => {
  const { workspaceId } = req.query;
  const { serviceId, externalServiceItemId } = req.params;

  if (!workspaceId) {
    return res.status(400).json({ error: 'workspaceId is required' });
  }

  try {
    await externalItemModel.deleteExternalItemPosition(workspaceId, serviceId, externalServiceItemId);
    res.json({ message: 'Position deleted successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Clear all external positions for a service
router.delete('/service/:serviceId/clear', authenticateToken, async (req, res) => {
  const { workspaceId } = req.query;
  const { serviceId } = req.params;

  if (!workspaceId) {
    return res.status(400).json({ error: 'workspaceId is required' });
  }

  try {
    await externalItemModel.clearExternalPositionsByService(workspaceId, serviceId);
    res.json({ message: 'All positions cleared successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
