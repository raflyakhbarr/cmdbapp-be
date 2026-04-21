const express = require('express');
const router = express.Router();
const {
  getAllLayananServiceConnections,
  getLayananServiceConnectionsByLayananId,
  getLayananServiceConnectionsByServiceItemId,
  createLayananServiceConnection,
  updateLayananServiceConnection,
  deleteLayananServiceConnection,
  deleteLayananServiceConnectionsByLayananId,
  deleteLayananServiceConnectionsByServiceItemId,
} = require('../models/layananServiceConnectionModel');
const { emitCmdbUpdate } = require('../socket');

// GET /api/layanan-service-connections - Get all layanan service connections (optionally by workspace)
router.get('/', async (req, res) => {
  try {
    const { workspace_id } = req.query;
    if (!workspace_id) {
      return res.status(400).json({ error: 'workspace_id is required' });
    }
    const result = await getAllLayananServiceConnections(workspace_id);
    res.json(result.rows);
  } catch (err) {
    console.error('Error fetching layanan service connections:', err);
    res.status(500).json({ error: 'Failed to fetch layanan service connections' });
  }
});

// GET /api/layanan-service-connections/layanan/:layananId - Get connections by layanan ID
router.get('/layanan/:layananId', async (req, res) => {
  try {
    const { layananId } = req.params;
    const result = await getLayananServiceConnectionsByLayananId(layananId);
    res.json(result.rows);
  } catch (err) {
    console.error('Error fetching layanan service connections by layanan ID:', err);
    res.status(500).json({ error: 'Failed to fetch layanan service connections' });
  }
});

// GET /api/layanan-service-connections/service-item/:serviceItemId - Get connections by service item ID
router.get('/service-item/:serviceItemId', async (req, res) => {
  try {
    const { serviceItemId } = req.params;
    const result = await getLayananServiceConnectionsByServiceItemId(serviceItemId);
    res.json(result.rows);
  } catch (err) {
    console.error('Error fetching layanan service connections by service item ID:', err);
    res.status(500).json({ error: 'Failed to fetch layanan service connections' });
  }
});

// POST /api/layanan-service-connections - Create layanan service connection
router.post('/', async (req, res) => {
  try {
    const { layanan_id, service_id, service_item_id, workspace_id, connection_type, propagation_enabled } = req.body;

    if (!layanan_id || !service_id || !service_item_id || !workspace_id) {
      return res.status(400).json({ error: 'layanan_id, service_id, service_item_id, and workspace_id are required' });
    }

    const result = await createLayananServiceConnection(
      layanan_id,
      service_id,
      service_item_id,
      workspace_id,
      connection_type || 'depends_on',
      propagation_enabled !== undefined ? propagation_enabled : true
    );

    // Emit socket update for real-time status propagation
    await emitCmdbUpdate(null);

    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('Error creating layanan service connection:', err);
    res.status(500).json({ error: 'Failed to create layanan service connection' });
  }
});

// PUT /api/layanan-service-connections/:id - Update layanan service connection
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { connection_type, propagation_enabled } = req.body;

    if (!connection_type || propagation_enabled === undefined) {
      return res.status(400).json({ error: 'connection_type and propagation_enabled are required' });
    }

    const result = await updateLayananServiceConnection(id, connection_type, propagation_enabled);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Layanan service connection not found' });
    }

    // Emit socket update for real-time status propagation
    await emitCmdbUpdate(null);

    res.json(result.rows[0]);
  } catch (err) {
    console.error('Error updating layanan service connection:', err);
    res.status(500).json({ error: 'Failed to update layanan service connection' });
  }
});

// DELETE /api/layanan-service-connections/:id - Delete layanan service connection
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await deleteLayananServiceConnection(id);

    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Layanan service connection not found' });
    }

    // Emit socket update for real-time status propagation
    await emitCmdbUpdate(null);

    res.json({ message: 'Layanan service connection deleted successfully' });
  } catch (err) {
    console.error('Error deleting layanan service connection:', err);
    res.status(500).json({ error: 'Failed to delete layanan service connection' });
  }
});

module.exports = router;
