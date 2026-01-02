// routes/groupRoutes.js
const express = require('express');
const router = express.Router();
const groupModel = require('../models/groupModel');
const { emitCmdbUpdate } = require('../socket');
const cmdbModel = require('../models/cmdbModel');

// Get all groups
router.get('/', async (req, res) => {
  try {
    const result = await groupModel.getAllGroups();
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Create new group
router.post('/', async (req, res) => {
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
router.put('/:id', async (req, res) => {
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
router.delete('/:id', async (req, res) => {
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
router.put('/:id/position', async (req, res) => {
  const { id } = req.params;
  const { position } = req.body;
  try {
    const result = await groupModel.updateGroupPosition(id, position);
    await emitCmdbUpdate(cmdbModel);
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get all group connections
router.get('/connections', async (req, res) => {
  try {
    const result = await groupModel.getAllGroupConnections();
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Create group connection
router.post('/connections', async (req, res) => {
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
router.delete('/connections/:sourceId/:targetId', async (req, res) => {
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