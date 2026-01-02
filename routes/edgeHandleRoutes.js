// routes/edgeHandleRoutes.js
const express = require('express');
const router = express.Router();
const edgeHandleModel = require('../models/edgeHandleModel');
const { emitCmdbUpdate } = require('../socket');
const cmdbModel = require('../models/cmdbModel');

// Get all edge handles
router.get('/', async (req, res) => {
  try {
    const result = await edgeHandleModel.getAllEdgeHandles();
    
    // Convert to object format { edgeId: { sourceHandle, targetHandle } }
    const edgeHandles = {};
    result.rows.forEach(row => {
      edgeHandles[row.edge_id] = {
        sourceHandle: row.source_handle,
        targetHandle: row.target_handle,
      };
    });
    
    res.json(edgeHandles);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Upsert single edge handle
router.post('/', async (req, res) => {
  const { edgeId, sourceHandle, targetHandle } = req.body;
  
  if (!edgeId || !sourceHandle || !targetHandle) {
    return res.status(400).json({ 
      error: 'edgeId, sourceHandle, and targetHandle are required' 
    });
  }
  
  try {
    const result = await edgeHandleModel.upsertEdgeHandle(
      edgeId, 
      sourceHandle, 
      targetHandle
    );
    await emitCmdbUpdate(cmdbModel);
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Bulk upsert edge handles
router.post('/bulk', async (req, res) => {
  const { edgeHandles } = req.body;
  
  if (!edgeHandles || typeof edgeHandles !== 'object') {
    return res.status(400).json({ 
      error: 'edgeHandles object is required' 
    });
  }
  
  try {
    const result = await edgeHandleModel.bulkUpsertEdgeHandles(edgeHandles);
    await emitCmdbUpdate(cmdbModel);
    res.json({ 
      success: true, 
      count: result.rows.length,
      data: result.rows 
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete edge handle
router.delete('/:edgeId', async (req, res) => {
  const { edgeId } = req.params;
  
  try {
    await edgeHandleModel.deleteEdgeHandle(edgeId);
    await emitCmdbUpdate(cmdbModel);
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;