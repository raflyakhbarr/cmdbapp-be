const express = require('express');
const router = express.Router();
const cmdbModel = require('../models/cmdbModel');
const connectionModel = require('../models/connectionModel');
const { emitCmdbUpdate } = require('../socket'); 
const upload = require('../config/upload');
const fs = require('fs');
const path = require('path');
const pool = require('../db');
const { env } = require('process');
const { authenticateToken } = require('../middleware/auth');

router.get('/', authenticateToken, async (req, res) => {
  const { workspace_id } = req.query;
  
  try {
    const result = await cmdbModel.getAllItems(workspace_id || null);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/connections', authenticateToken, async (req, res) => {
  const { workspace_id } = req.query;
  
  try {
    const result = await connectionModel.getAllConnections(workspace_id || null);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get connections for specific item
router.get('/:id/connections', authenticateToken, async (req, res) => {
  const { id } = req.params;
  try {
    const result = await connectionModel.getConnectionsByItemId(id);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get affected items (cascade view)
router.get('/:id/affected', authenticateToken, async (req, res) => {
  const { id } = req.params;
  try {
    const result = await connectionModel.getAffectedItems(id);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Method post buat item
router.post('/', authenticateToken, upload.array('images', 10), async (req, res) => {
  const { name, type, description, status, ip, category, location, group_id, env_type, position, workspace_id } = req.body;
  
  if(!workspace_id) {
    return res.status(400).json({ error: 'workspace_id is required' });
  }

  try {
    // Get uploaded file paths
    const images = req.files ? req.files.map(file => `/uploads/${file.filename}`) : [];
    
    const result = await cmdbModel.createItem(
      name, 
      type, 
      description, 
      status || 'active', 
      ip, 
      category, 
      location, 
      images,
      group_id || null,
      env_type,
      position ? JSON.parse(position) : null, // Parse position jika ada
      workspace_id
    );
    await emitCmdbUpdate(cmdbModel);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    // Hapus file yang sudah diupload jika terjadi error
    if (req.files) {
      req.files.forEach(file => {
        fs.unlinkSync(file.path);
      });
    }
    res.status(500).json({ error: err.message });
  }
});

// Create connection between items
router.post('/connections', authenticateToken, async (req, res) => {
  const { source_id, target_id, workspace_id } = req.body;
  
  if (!source_id || !target_id) {
    return res.status(400).json({ error: 'source_id and target_id are required' });
  }
  
  if (!workspace_id) {
    return res.status(400).json({ error: 'workspace_id is required' });
  }
  
  try {
    const result = await connectionModel.createConnection(source_id, target_id, workspace_id);
    await emitCmdbUpdate(cmdbModel);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/connections/to-group', authenticateToken, async (req, res) => {
  const { source_id, target_group_id, workspace_id } = req.body;
  
  if (!source_id || !target_group_id) {
    return res.status(400).json({ error: 'source_id and target_group_id are required' });
  }
  
  if (!workspace_id) {
    return res.status(400).json({ error: 'workspace_id is required' });
  }
  
  try {
    const result = await connectionModel.createItemToGroupConnection(source_id, target_group_id, workspace_id);
    await emitCmdbUpdate(cmdbModel);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update item position
router.put('/:id/position', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { position, skipEmit } = req.body; // ← TAMBAH skipEmit

  if (!position || typeof position.x !== 'number' || typeof position.y !== 'number') {
    return res.status(400).json({ error: 'Invalid position format' });
  }

  try {
    const result = await cmdbModel.updateItemPosition(id, position);
    
    if (!skipEmit) {
      await emitCmdbUpdate(cmdbModel);
    }
    
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Method update 
router.put('/:id', authenticateToken, upload.array('images', 10), async (req, res) => {
  const { id } = req.params;
  const { name, type, description, status, ip, category, location, existingImages, group_id, env_type } = req.body;
  
  try {
    // Parse existing images
    let images = [];
    if (existingImages) {
      images = JSON.parse(existingImages);
    }
    
    // Add new uploaded images
    if (req.files && req.files.length > 0) {
      const newImages = req.files.map(file => `/uploads/${file.filename}`);
      images = [...images, ...newImages];
    }
    
    if (status) {
      await cmdbModel.updateItemStatus(id, status);
    }
    
    const result = await cmdbModel.updateItem(
      id, 
      name, 
      type, 
      description, 
      status || 'active', 
      ip, 
      category, 
      location, 
      images,
      group_id || null,
      env_type,
    );
    await emitCmdbUpdate(cmdbModel);
    res.json(result.rows[0]);
  } catch (err) {
    // Hapus file yang sudah diupload jika terjadi error
    if (req.files) {
      req.files.forEach(file => {
        fs.unlinkSync(file.path);
      });
    }
    res.status(500).json({ error: err.message });
  }
});

// PATCH: Update item status
router.patch('/:id/status', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;
  
  if (!status) {
    return res.status(400).json({ error: 'Status is required' });
  }
  
  try {
    const result = await cmdbModel.updateItemStatus(id, status);
    await emitCmdbUpdate(cmdbModel);
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PATCH: Update item group
router.patch('/:id/group', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { group_id, order_in_group } = req.body;
  
  try {
    const result = await cmdbModel.updateItemGroup(id, group_id, order_in_group);
    await emitCmdbUpdate(cmdbModel);
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PATCH: Reorder item within group - MUST BE BEFORE /:id route
router.patch('/:id/reorder', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { new_order } = req.body;
  
  console.log(`Reorder request received - ID: ${id}, New Order: ${new_order}`);
  
  if (typeof new_order !== 'number') {
    console.error('Invalid new_order type:', typeof new_order);
    return res.status(400).json({ error: 'new_order must be a number' });
  }
  
  try {
    const result = await cmdbModel.reorderItemInGroup(id, new_order);
    await emitCmdbUpdate(cmdbModel);
    console.log(`Reorder successful for item ${id}`);
    res.json(result.rows[0]);
  } catch (err) {
    console.error(`Reorder failed for item ${id}:`, err);
    res.status(500).json({ error: err.message });
  }
});

// Delete item (and its images)
router.delete('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  try {
    // Get item
    const itemResult = await cmdbModel.getItemById(id);
    const item = itemResult.rows[0];
    
    // Hapus file gambar
    if (item && item.images) {
      const images = typeof item.images === 'string' ? JSON.parse(item.images) : item.images;
      images.forEach(imagePath => {
        const fullPath = path.join(__dirname, '..', imagePath);
        if (fs.existsSync(fullPath)) {
          fs.unlinkSync(fullPath);
        }
      });
    }
    
    await cmdbModel.deleteItem(id);
    await emitCmdbUpdate(cmdbModel);
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete single image
router.delete('/:id/images', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { imagePath } = req.body;
  
  try {
    // Get item
    const itemResult = await cmdbModel.getItemById(id);
    const item = itemResult.rows[0];
    
    if (!item) {
      return res.status(404).json({ error: 'Item tidak ditemukan' });
    }
    
    // Parse images
    let images = typeof item.images === 'string' ? JSON.parse(item.images) : item.images || [];
    
    // Remove image from array
    images = images.filter(img => img !== imagePath);
    
    // Delete physical file
    const fullPath = path.join(__dirname, '..', imagePath);
    if (fs.existsSync(fullPath)) {
      fs.unlinkSync(fullPath);
    }
    
    // Update database
    const result = await cmdbModel.updateItem(
      id, item.name, item.type, item.description, item.status, 
      item.ip, item.category, item.location, images
    );
    
    await emitCmdbUpdate(cmdbModel);
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete connection
router.delete('/connections/:sourceId/:targetId', authenticateToken, async (req, res) => {
  const { sourceId, targetId } = req.params;
  try {
    await connectionModel.deleteConnection(sourceId, targetId);
    await emitCmdbUpdate(cmdbModel);
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/connections/to-group/:sourceId/:targetGroupId', authenticateToken, async (req, res) => {
  const { sourceId, targetGroupId } = req.params;
  try {
    await pool.query(
      'DELETE FROM connections WHERE source_id = $1 AND target_group_id = $2',
      [sourceId, targetGroupId]
    );
    await emitCmdbUpdate(cmdbModel);
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/connections/from-group', authenticateToken, async (req, res) => {
  const { source_group_id, target_id, workspace_id } = req.body;
  
  if (!source_group_id || !target_id) {
    return res.status(400).json({ error: 'source_group_id and target_id are required' });
  }
  
  if (!workspace_id) {
    return res.status(400).json({ error: 'workspace_id is required' });
  }
  
  try {
    const result = await connectionModel.createGroupToItemConnection(source_group_id, target_id, workspace_id);
    await emitCmdbUpdate(cmdbModel);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/connections/from-group/:sourceGroupId/:targetId', authenticateToken, async (req, res) => {
  const { sourceGroupId, targetId } = req.params;
  try {
    await connectionModel.deleteGroupToItemConnection(sourceGroupId, targetId);
    await emitCmdbUpdate(cmdbModel);
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/trigger-update', authenticateToken, async (req, res) => {
  try {
    await emitCmdbUpdate(cmdbModel);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;