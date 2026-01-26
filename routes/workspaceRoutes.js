const express = require('express');
const router = express.Router();
const workspaceModel = require('../models/workspaceModel');
const { emitCmdbUpdate } = require('../socket');
const cmdbModel = require('../models/cmdbModel');
const { authenticateToken } = require('../middleware/auth');

// Get all workspaces
router.get('/', authenticateToken, async (req, res) => {
  try {
    const result = await workspaceModel.getAllWorkspaces();
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get workspace by ID
router.get('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  try {
    const result = await workspaceModel.getWorkspaceById(id);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Workspace not found' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get default workspace
router.get('/default/get', authenticateToken, async (req, res) => {
  try {
    const result = await workspaceModel.getDefaultWorkspace();
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'No default workspace found' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Create new workspace
router.post('/', authenticateToken, async (req, res) => {
  const { name, description } = req.body;
  
  if (!name) {
    return res.status(400).json({ error: 'Workspace name is required' });
  }
  
  try {
    const result = await workspaceModel.createWorkspace(name, description);
    await emitCmdbUpdate(cmdbModel);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update workspace
router.put('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { name, description } = req.body;
  
  if (!name) {
    return res.status(400).json({ error: 'Workspace name is required' });
  }
  
  try {
    const result = await workspaceModel.updateWorkspace(id, name, description);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Workspace not found' });
    }
    await emitCmdbUpdate(cmdbModel);
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete workspace
router.delete('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  
  try {
    await workspaceModel.deleteWorkspace(id);
    await emitCmdbUpdate(cmdbModel);
    res.status(204).send();
  } catch (err) {
    if (err.message === 'Cannot delete default workspace') {
      return res.status(400).json({ error: err.message });
    }
    res.status(500).json({ error: err.message });
  }
});

// Set default workspace
router.patch('/:id/set-default', authenticateToken, async (req, res) => {
  const { id } = req.params;
  
  try {
    const result = await workspaceModel.setDefaultWorkspace(id);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Workspace not found' });
    }
    await emitCmdbUpdate(cmdbModel);
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Duplicate workspace
router.post('/:id/duplicate', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { name } = req.body;
  
  if (!name) {
    return res.status(400).json({ error: 'New workspace name is required' });
  }
  
  try {
    const result = await workspaceModel.duplicateWorkspace(id, name);
    await emitCmdbUpdate(cmdbModel);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;