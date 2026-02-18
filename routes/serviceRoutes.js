const express = require('express');
const router = express.Router();
const pool = require('../db');
const serviceModel = require('../models/serviceModel');
const cmdbModel = require('../models/cmdbModel');
const { emitCmdbUpdate } = require('../socket');
const upload = require('../config/upload');
const fs = require('fs');
const path = require('path');
const { authenticateToken } = require('../middleware/auth');

// ==================== SERVICES ROUTES ====================

// Get all services for a CMDB item
router.get('/:cmdbItemId', authenticateToken, async (req, res) => {
  const { cmdbItemId } = req.params;

  try {
    const result = await serviceModel.getServicesByItemId(cmdbItemId);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Create a new service
router.post('/', authenticateToken, async (req, res) => {
  const { cmdb_item_id, name, status, icon_type, icon_name, description } = req.body;

  if (!cmdb_item_id || !name) {
    return res.status(400).json({ error: 'cmdb_item_id and name are required' });
  }

  try {
    let iconPath = null;

    // Handle icon file upload if present
    if (req.file && icon_type === 'upload') {
      iconPath = `/uploads/${req.file.filename}`;
    }

    const result = await serviceModel.createService(
      cmdb_item_id,
      name,
      status || 'active',
      icon_type || 'preset',
      iconPath,
      icon_name,
      description
    );

    await emitCmdbUpdate(cmdbModel);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Upload/update service icon (separate endpoint for file upload)
router.post('/:id/upload-icon', authenticateToken, upload.single('icon'), async (req, res) => {
  const { id } = req.params;

  if (!req.file) {
    return res.status(400).json({ error: 'No icon file uploaded' });
  }

  try {
    const iconPath = `/uploads/${req.file.filename}`;

    // Delete old icon if it was an uploaded file
    const existingService = await serviceModel.getServiceById(id);
    if (existingService.rows.length > 0) {
      const service = existingService.rows[0];
      if (service.icon_path) {
        const fullPath = path.join(__dirname, '..', service.icon_path);
        if (fs.existsSync(fullPath)) {
          fs.unlinkSync(fullPath);
        }
      }
    }

    const result = await serviceModel.updateServiceIcon(id, 'upload', iconPath, null);
    await emitCmdbUpdate(cmdbModel);
    res.json(result.rows[0]);
  } catch (err) {
    // Delete uploaded file if error
    if (req.file) {
      fs.unlinkSync(req.file.path);
    }
    res.status(500).json({ error: err.message });
  }
});

// Update service
router.put('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { name, status, description } = req.body;

  if (!name) {
    return res.status(400).json({ error: 'name is required' });
  }

  try {
    const result = await serviceModel.updateService(id, name, status, description);
    await emitCmdbUpdate(cmdbModel);
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update service icon
router.put('/:id/icon', authenticateToken, upload.single('icon'), async (req, res) => {
  const { id } = req.params;
  const { icon_type, icon_name } = req.body;

  if (!icon_type) {
    return res.status(400).json({ error: 'icon_type is required' });
  }

  try {
    let iconPath = null;

    // Get existing service to preserve icon if needed
    const existingServiceResult = await pool.query('SELECT * FROM services WHERE id = $1', [id]);
    if (existingServiceResult.rows.length === 0) {
      return res.status(404).json({ error: 'Service not found' });
    }
    const existingService = existingServiceResult.rows[0];

    // Handle uploaded icon
    if (req.file && icon_type === 'upload') {
      iconPath = `/uploads/${req.file.filename}`;

      // Delete old icon if it was an uploaded file
      if (existingService.icon_path) {
        const fullPath = path.join(__dirname, '..', existingService.icon_path);
        if (fs.existsSync(fullPath)) {
          fs.unlinkSync(fullPath);
        }
      }
    } else if (icon_type === 'upload' && !req.file) {
      // Keep existing icon path if no new file uploaded
      iconPath = existingService.icon_path;
    }

    const result = await serviceModel.updateServiceIcon(id, icon_type, iconPath, icon_name);
    await emitCmdbUpdate(cmdbModel);
    res.json(result.rows[0]);
  } catch (err) {
    // Delete uploaded file if error
    if (req.file) {
      fs.unlinkSync(req.file.path);
    }
    res.status(500).json({ error: err.message });
  }
});

// Delete service
router.delete('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;

  try {
    // Delete service icon if it was an uploaded file
    const existingService = await serviceModel.getServiceById(id);
    if (existingService.rows.length > 0) {
      const iconPath = existingService.rows[0].icon_path;
      if (iconPath) {
        const fullPath = path.join(__dirname, '..', iconPath);
        if (fs.existsSync(fullPath)) {
          fs.unlinkSync(fullPath);
        }
      }
    }

    await serviceModel.deleteService(id);
    await emitCmdbUpdate(cmdbModel);
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ==================== SERVICE ITEMS ROUTES ====================

// Get all service items
router.get('/:serviceId/items', authenticateToken, async (req, res) => {
  const { serviceId } = req.params;
  const { workspace_id } = req.query;

  if (!workspace_id) {
    return res.status(400).json({ error: 'workspace_id is required' });
  }

  try {
    const result = await serviceModel.getAllServiceItems(serviceId, workspace_id);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Create a new service item
router.post('/:serviceId/items', authenticateToken, async (req, res) => {
  const { serviceId } = req.params;
  const { name, type, description, position, status, ip, category, location, workspace_id, group_id } = req.body;

  if (!name || !workspace_id) {
    return res.status(400).json({ error: 'name and workspace_id are required' });
  }

  try {
    const result = await serviceModel.createServiceItem(
      serviceId,
      name,
      type,
      description,
      position,
      status,
      ip,
      category,
      location,
      workspace_id,
      group_id
    );

    await emitCmdbUpdate(cmdbModel);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update service item
router.put('/items/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { name, type, description, status, ip, category, location, group_id } = req.body;

  if (!name) {
    return res.status(400).json({ error: 'name is required' });
  }

  try {
    const result = await serviceModel.updateServiceItem(id, name, type, description, status, ip, category, location, group_id);
    await emitCmdbUpdate(cmdbModel);
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update service item position
router.put('/items/:id/position', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { position } = req.body;

  if (!position || typeof position.x !== 'number' || typeof position.y !== 'number') {
    return res.status(400).json({ error: 'Invalid position format' });
  }

  try {
    const result = await serviceModel.updateServiceItemPosition(id, position);
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete service item
router.delete('/items/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;

  try {
    await serviceModel.deleteServiceConnectionsByItemId(id);
    await serviceModel.deleteServiceItem(id);
    await emitCmdbUpdate(cmdbModel);
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ==================== SERVICE CONNECTIONS ROUTES ====================

// Get all service connections
router.get('/:serviceId/connections', authenticateToken, async (req, res) => {
  const { serviceId } = req.params;
  const { workspace_id } = req.query;

  if (!workspace_id) {
    return res.status(400).json({ error: 'workspace_id is required' });
  }

  try {
    const result = await serviceModel.getAllServiceConnections(serviceId, workspace_id);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Create a new service connection
router.post('/:serviceId/connections', authenticateToken, async (req, res) => {
  const { serviceId } = req.params;
  const { source_id, target_id, workspace_id } = req.body;

  if (!source_id || !target_id || !workspace_id) {
    return res.status(400).json({ error: 'source_id, target_id, and workspace_id are required' });
  }

  try {
    const result = await serviceModel.createServiceConnection(serviceId, source_id, target_id, workspace_id);
    await emitCmdbUpdate(cmdbModel);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete service connection
router.delete('/:serviceId/connections/:sourceId/:targetId', authenticateToken, async (req, res) => {
  const { serviceId, sourceId, targetId } = req.params;

  try {
    await serviceModel.deleteServiceConnection(serviceId, sourceId, targetId);
    await emitCmdbUpdate(cmdbModel);
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
