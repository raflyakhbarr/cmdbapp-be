// routes/groupRoutes.js
const express = require('express');
const router = express.Router();
const groupModel = require('../models/groupModel');
const { emitCmdbUpdate } = require('../socket');
const cmdbModel = require('../models/cmdbModel');
const { authenticateToken } = require('../middleware/auth')

// Get all groups
router.get('/', authenticateToken, async (req, res) => {
  try {
    const result = await groupModel.getAllGroups();
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Create new group
router.post('/', authenticateToken, async (req, res) => {
  const { name, description, color, position } = req.body;
  try {
    const result = await groupModel.createGroup(name, description, color, position);
    await emitCmdbUpdate(cmdbModel);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update group
router.put('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { name, description, color, position } = req.body;
  try {
    const result = await groupModel.updateGroup(id, name, description, color, position);
    await emitCmdbUpdate(cmdbModel);
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete group
router.delete('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  try {
    await groupModel.deleteGroup(id);
    await emitCmdbUpdate(cmdbModel);
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update group position
router.put('/:id/position', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { position, skipEmit } = req.body;
  
  try {
    const result = await groupModel.updateGroupPosition(id, position);
    
    if (!skipEmit) {
      await emitCmdbUpdate(cmdbModel);
    }
    
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get all group connections
router.get('/connections', authenticateToken, async (req, res) => {
  try {
    const result = await groupModel.getAllGroupConnections();
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Create group connection
router.post('/connections', authenticateToken, async (req, res) => {
  const { source_id, target_id } = req.body;
  try {
    const result = await groupModel.createGroupConnection(source_id, target_id);
    await emitCmdbUpdate(cmdbModel);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete group connection
router.delete('/connections/:sourceId/:targetId', authenticateToken, async (req, res) => {
  const { sourceId, targetId } = req.params;
  try {
    await groupModel.deleteGroupConnection(sourceId, targetId);
    await emitCmdbUpdate(cmdbModel);
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;