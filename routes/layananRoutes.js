const express = require('express');
const router = express.Router();
const {
  getAllLayanan,
  getLayananById,
  createLayanan,
  updateLayanan,
  deleteLayanan,
  updateLayananPosition,
  updateLayananStatus,
  getAllLayananConnections,
  createLayananConnection,
  deleteLayananConnection,
  updateLayananConnection,
  deleteLayananConnectionsBySource,
  deleteLayananConnectionsByTarget,
} = require('../models/layananModel');

// GET /api/layanan - Get all layanan (optionally by workspace)
router.get('/', async (req, res) => {
  try {
    const { workspace_id } = req.query;
    const result = await getAllLayanan(workspace_id);
    res.json(result.rows);
  } catch (err) {
    console.error('Error fetching layanan:', err);
    res.status(500).json({ error: 'Failed to fetch layanan' });
  }
});

// POST /api/layanan - Create new layanan
router.post('/', async (req, res) => {
  try {
    const { name, description, status, position, workspace_id } = req.body;

    if (!name || !workspace_id) {
      return res.status(400).json({ error: 'Name and workspace_id are required' });
    }

    const result = await createLayanan(name, description, status, position, workspace_id);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('Error creating layanan:', err);
    res.status(500).json({ error: 'Failed to create layanan' });
  }
});

// GET /api/layanan/connections - Get all layanan connections (MUST BE BEFORE /:id)
router.get('/connections', async (req, res) => {
  try {
    const { workspace_id } = req.query;
    if (!workspace_id) {
      return res.status(400).json({ error: 'workspace_id is required' });
    }
    const result = await getAllLayananConnections(workspace_id);
    res.json(result.rows);
  } catch (err) {
    console.error('Error fetching connections:', err);
    res.status(500).json({ error: 'Failed to fetch connections' });
  }
});

// POST /api/layanan/connections - Create layanan connection (MUST BE BEFORE /:id)
router.post('/connections', async (req, res) => {
  try {
    const { source_type, source_id, target_type, target_id, workspace_id, connection_type, propagation_enabled } = req.body;

    if (!source_type || !source_id || !target_type || !target_id || !workspace_id) {
      return res.status(400).json({ error: 'source_type, source_id, target_type, target_id, and workspace_id are required' });
    }

    const result = await createLayananConnection(source_type, source_id, target_type, target_id, workspace_id, connection_type, propagation_enabled);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('Error creating connection:', err);
    res.status(500).json({ error: 'Failed to create connection' });
  }
});

// PUT /api/layanan/connections/:id - Update layanan connection (MUST BE BEFORE /:id)
router.put('/connections/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { propagation_enabled } = req.body;

    if (propagation_enabled === undefined) {
      return res.status(400).json({ error: 'propagation_enabled is required' });
    }

    const result = await updateLayananConnection(id, propagation_enabled);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Layanan connection not found' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error('Error updating layanan connection:', err);
    res.status(500).json({ error: 'Failed to update layanan connection' });
  }
});

// DELETE /api/layanan/connections/:id - Delete layanan connection (MUST BE BEFORE /:id)
router.delete('/connections/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await deleteLayananConnection(id);
    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Connection not found' });
    }
    res.json({ message: 'Connection deleted successfully' });
  } catch (err) {
    console.error('Error deleting connection:', err);
    res.status(500).json({ error: 'Failed to delete connection' });
  }
});

// PUT /api/layanan/:id/position - Update layanan position (MUST BE BEFORE /:id)
router.put('/:id/position', async (req, res) => {
  try {
    const { id } = req.params;
    const { position } = req.body;

    const result = await updateLayananPosition(id, position);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Layanan not found' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    console.error('Error updating position:', err);
    res.status(500).json({ error: 'Failed to update position' });
  }
});

// PATCH /api/layanan/:id/status - Update layanan status (MUST BE BEFORE /:id)
router.patch('/:id/status', async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!status) {
      return res.status(400).json({ error: 'Status is required' });
    }

    const result = await updateLayananStatus(id, status);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Layanan not found' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    console.error('Error updating status:', err);
    res.status(500).json({ error: 'Failed to update status' });
  }
});

// GET /api/layanan/:id - Get layanan by ID (MUST BE LAST)
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await getLayananById(id);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Layanan not found' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    console.error('Error fetching layanan:', err);
    res.status(500).json({ error: 'Failed to fetch layanan' });
  }
});

// PUT /api/layanan/:id - Update layanan
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { name, description, status } = req.body;

    if (!name) {
      return res.status(400).json({ error: 'Name is required' });
    }

    const result = await updateLayanan(id, name, description, status);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Layanan not found' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    console.error('Error updating layanan:', err);
    res.status(500).json({ error: 'Failed to update layanan' });
  }
});

// DELETE /api/layanan/:id - Delete layanan
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    // Delete connections first
    await deleteLayananConnectionsBySource('layanan', id);
    await deleteLayananConnectionsByTarget('layanan', id);

    // Delete layanan
    const result = await deleteLayanan(id);
    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Layanan not found' });
    }
    res.json({ message: 'Layanan deleted successfully' });
  } catch (err) {
    console.error('Error deleting layanan:', err);
    res.status(500).json({ error: 'Failed to delete layanan' });
  }
});

module.exports = router;
