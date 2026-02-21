const express = require('express');
const router = express.Router();
const ShareLinkModel = require('../models/shareLinkModel');
const pool = require('../db');
const { authenticateToken } = require('../middleware/auth');

const shareLinkModel = new ShareLinkModel(pool);

/**
 * Generate a new share link for a workspace (requires auth)
 */
router.post('/generate', authenticateToken, async (req, res) => {
  const { workspace_id, expiration, password } = req.body;
  const userId = req.user.id;

  if (!workspace_id) {
    return res.status(400).json({ error: 'Workspace ID is required' });
  }

  try {
    // Calculate expiration date
    const { calculateExpirationDate } = require('../utils/shareUtils');
    const expiresAt = calculateExpirationDate(expiration || 'never');

    const shareLink = await shareLinkModel.create({
      workspaceId: workspace_id,
      createdBy: userId,
      expiresAt,
      password: password || null
    });

    res.status(201).json({
      id: shareLink.id,
      token: shareLink.token,
      workspace_id: shareLink.workspace_id,
      created_at: shareLink.created_at,
      expires_at: shareLink.expires_at,
      has_password: !!shareLink.password_hash
    });
  } catch (err) {
    console.error('Error generating share link:', err);
    res.status(500).json({ error: err.message });
  }
});

/**
 * Verify password for a protected share link
 */
router.post('/verify-password', async (req, res) => {
  const { token, password } = req.body;

  if (!token || !password) {
    return res.status(400).json({ error: 'Token and password are required' });
  }

  try {
    const isValid = await shareLinkModel.verifyPassword(token, password);

    if (isValid) {
      res.json({ success: true });
    } else {
      res.status(401).json({ error: 'Invalid password' });
    }
  } catch (err) {
    console.error('Error verifying password:', err);
    res.status(500).json({ error: err.message });
  }
});

/**
 * Get all share links for a workspace (requires auth)
 */
router.get('/workspace/:workspaceId', authenticateToken, async (req, res) => {
  const { workspaceId } = req.params;

  try {
    const shareLinks = await shareLinkModel.getByWorkspace(workspaceId);
    res.json(shareLinks);
  } catch (err) {
    console.error('Error fetching share links:', err);
    res.status(500).json({ error: err.message });
  }
});

/**
 * Get share link by ID (requires auth)
 */
router.get('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;

  try {
    const shareLink = await shareLinkModel.getById(id);

    if (!shareLink) {
      return res.status(404).json({ error: 'Share link not found' });
    }

    res.json(shareLink);
  } catch (err) {
    console.error('Error fetching share link:', err);
    res.status(500).json({ error: err.message });
  }
});

/**
 * Update share link (requires auth)
 */
router.put('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { expiration, password, is_active } = req.body;

  try {
    const updates = {};

    if (expiration !== undefined) {
      const { calculateExpirationDate } = require('../utils/shareUtils');
      updates.expiresAt = calculateExpirationDate(expiration);
    }

    if (password !== undefined) {
      updates.password = password;
    }

    if (is_active !== undefined) {
      updates.isActive = is_active;
    }

    const shareLink = await shareLinkModel.update(id, updates);

    if (!shareLink) {
      return res.status(404).json({ error: 'Share link not found' });
    }

    res.json(shareLink);
  } catch (err) {
    console.error('Error updating share link:', err);
    res.status(500).json({ error: err.message });
  }
});

/**
 * Delete share link (requires auth)
 */
router.delete('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;

  try {
    const deleted = await shareLinkModel.delete(id);

    if (!deleted) {
      return res.status(404).json({ error: 'Share link not found' });
    }

    res.json({ message: 'Share link deleted successfully' });
  } catch (err) {
    console.error('Error deleting share link:', err);
    res.status(500).json({ error: err.message });
  }
});

/**
 * Get access logs for a share link (requires auth)
 */
router.get('/:id/logs', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { limit } = req.query;

  try {
    const logs = await shareLinkModel.getAccessLogs(id, parseInt(limit) || 50);
    res.json(logs);
  } catch (err) {
    console.error('Error fetching access logs:', err);
    res.status(500).json({ error: err.message });
  }
});

/**
 * Get share link stats (requires auth)
 */
router.get('/:id/stats', authenticateToken, async (req, res) => {
  const { id } = req.params;

  try {
    const stats = await shareLinkModel.getStats(id);

    if (!stats) {
      return res.status(404).json({ error: 'Share link not found' });
    }

    res.json(stats);
  } catch (err) {
    console.error('Error fetching share link stats:', err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
