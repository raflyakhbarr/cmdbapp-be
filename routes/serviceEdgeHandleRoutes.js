const express = require('express');
const router = express.Router();
const serviceEdgeHandleModel = require('../models/serviceEdgeHandleModel');
const { authenticateToken } = require('../middleware/auth');

// Get all service edge handles for a service
router.get('/:serviceId/edge-handles', authenticateToken, async (req, res) => {
  const { serviceId } = req.params;
  const { workspace_id } = req.query;

  if (!workspace_id) {
    return res.status(400).json({ error: 'workspace_id is required' });
  }

  try {
    const handles = await serviceEdgeHandleModel.getAllServiceEdgeHandles(
      parseInt(serviceId),
      parseInt(workspace_id)
    );
    res.json(handles);
  } catch (err) {
    console.error('Error fetching service edge handles:', err);
    res.status(500).json({ error: err.message });
  }
});

// Get a specific service edge handle
router.get('/edge-handles/:edgeId', authenticateToken, async (req, res) => {
  const { edgeId } = req.params;

  try {
    const handle = await serviceEdgeHandleModel.getServiceEdgeHandle(edgeId);
    if (!handle) {
      return res.status(404).json({ error: 'Edge handle not found' });
    }
    res.json(handle);
  } catch (err) {
    console.error('Error fetching service edge handle:', err);
    res.status(500).json({ error: err.message });
  }
});

// Create or update a service edge handle
router.put('/edge-handles/:edgeId', authenticateToken, async (req, res) => {
  const { edgeId } = req.params;
  const { sourceHandle, targetHandle, serviceId, workspace_id } = req.body;

  if (!sourceHandle || !targetHandle || !serviceId || !workspace_id) {
    return res.status(400).json({
      error: 'sourceHandle, targetHandle, serviceId, and workspace_id are required'
    });
  }

  try {
    const handle = await serviceEdgeHandleModel.upsertServiceEdgeHandle(
      edgeId,
      sourceHandle,
      targetHandle,
      parseInt(serviceId),
      parseInt(workspace_id)
    );
    res.json(handle);
  } catch (err) {
    console.error('Error saving service edge handle:', err);
    res.status(500).json({ error: err.message });
  }
});

// Bulk upsert service edge handles
router.post('/:serviceId/edge-handles/bulk', authenticateToken, async (req, res) => {
  const { serviceId } = req.params;
  const { edgeHandles, workspace_id } = req.body;

  if (!edgeHandles || !workspace_id) {
    return res.status(400).json({ error: 'edgeHandles and workspace_id are required' });
  }

  try {
    const result = await serviceEdgeHandleModel.bulkUpsertServiceEdgeHandles(
      edgeHandles,
      parseInt(serviceId),
      parseInt(workspace_id)
    );
    res.json(result);
  } catch (err) {
    console.error('Error bulk saving service edge handles:', err);
    res.status(500).json({ error: err.message });
  }
});

// Delete a service edge handle
router.delete('/edge-handles/:edgeId', authenticateToken, async (req, res) => {
  const { edgeId } = req.params;

  try {
    const handle = await serviceEdgeHandleModel.deleteServiceEdgeHandle(edgeId);
    if (!handle) {
      return res.status(404).json({ error: 'Edge handle not found' });
    }
    res.json(handle);
  } catch (err) {
    console.error('Error deleting service edge handle:', err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
