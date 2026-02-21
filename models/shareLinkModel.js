const { generateShareToken } = require('../utils/shareUtils');
const crypto = require('crypto');
const bcrypt = require('bcrypt');

class ShareLinkModel {
  constructor(db) {
    this.db = db;
  }

  /**
   * Generate unique token for share link
   */
  async generateUniqueToken() {
    let token;
    let exists = true;
    let attempts = 0;

    while (exists && attempts < 10) {
      token = generateShareToken();
      const result = await this.db.query(
        'SELECT id FROM share_links WHERE token = $1',
        [token]
      );
      exists = result.rows.length > 0;
      attempts++;
    }

    if (exists) {
      throw new Error('Failed to generate unique token');
    }

    return token;
  }

  /**
   * Create a new share link
   */
  async create({ workspaceId, createdBy, expiresAt, password = null }) {
    const token = await this.generateUniqueToken();
    let passwordHash = null;

    if (password) {
      passwordHash = await bcrypt.hash(password, 10);
    }

    const query = `
      INSERT INTO share_links (token, workspace_id, created_by, expires_at, password_hash)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *
    `;

    const result = await this.db.query(query, [
      token,
      workspaceId,
      createdBy,
      expiresAt || null,
      passwordHash
    ]);

    return result.rows[0];
  }

  /**
   * Get share link by token (active and not expired)
   */
  async getByToken(token) {
    const query = `
      SELECT *,
        CASE
          WHEN expires_at IS NULL THEN true
          WHEN expires_at > CURRENT_TIMESTAMP THEN true
          ELSE false
        END as is_valid
      FROM share_links
      WHERE token = $1 AND is_active = true
    `;

    const result = await this.db.query(query, [token]);

    if (result.rows.length === 0) {
      return null;
    }

    const shareLink = result.rows[0];

    // Check if expired
    if (shareLink.expires_at && new Date(shareLink.expires_at) < new Date()) {
      return null;
    }

    return shareLink;
  }

  /**
   * Verify password for protected share link
   */
  async verifyPassword(token, password) {
    const shareLink = await this.getByToken(token);

    if (!shareLink || !shareLink.password_hash) {
      return false;
    }

    return await bcrypt.compare(password, shareLink.password_hash);
  }

  /**
   * Increment access count and log access
   */
  async logAccess(shareLinkId, visitorIp, userAgent) {
    const client = await this.db.connect();

    try {
      await client.query('BEGIN');

      // Increment access count
      await client.query(
        'UPDATE share_links SET access_count = access_count + 1, last_accessed_at = CURRENT_TIMESTAMP WHERE id = $1',
        [shareLinkId]
      );

      // Log access details
      await client.query(
        'INSERT INTO share_access_logs (share_link_id, visitor_ip, visitor_user_agent) VALUES ($1, $2, $3)',
        [shareLinkId, visitorIp, userAgent]
      );

      await client.query('COMMIT');
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  /**
   * Get all share links for a workspace
   */
  async getByWorkspace(workspaceId) {
    const query = `
      SELECT
        id,
        token,
        workspace_id,
        created_by,
        created_at,
        expires_at,
        is_active,
        access_count,
        last_accessed_at,
        CASE WHEN password_hash IS NOT NULL THEN true ELSE false END as has_password
      FROM share_links
      WHERE workspace_id = $1
      ORDER BY created_at DESC
    `;

    const result = await this.db.query(query, [workspaceId]);
    return result.rows;
  }

  /**
   * Get share link by ID
   */
  async getById(id) {
    const query = `
      SELECT
        id,
        token,
        workspace_id,
        created_by,
        created_at,
        expires_at,
        is_active,
        access_count,
        last_accessed_at,
        CASE WHEN password_hash IS NOT NULL THEN true ELSE FALSE END as has_password
      FROM share_links
      WHERE id = $1
    `;

    const result = await this.db.query(query, [id]);
    return result.rows[0] || null;
  }

  /**
   * Update share link (expires_at, is_active, password)
   */
  async update(id, updates) {
    const fields = [];
    const values = [];
    let paramIndex = 1;

    if (updates.expiresAt !== undefined) {
      fields.push(`expires_at = $${paramIndex++}`);
      values.push(updates.expiresAt);
    }

    if (updates.isActive !== undefined) {
      fields.push(`is_active = $${paramIndex++}`);
      values.push(updates.isActive);
    }

    if (updates.password !== undefined) {
      if (updates.password === null || updates.password === '') {
        fields.push(`password_hash = NULL`);
      } else {
        const passwordHash = await bcrypt.hash(updates.password, 10);
        fields.push(`password_hash = $${paramIndex++}`);
        values.push(passwordHash);
      }
    }

    if (fields.length === 0) {
      return await this.getById(id);
    }

    values.push(id);

    const query = `
      UPDATE share_links
      SET ${fields.join(', ')}
      WHERE id = $${paramIndex}
      RETURNING *
    `;

    const result = await this.db.query(query, values);

    // Return formatted result
    const row = result.rows[0];
    return {
      id: row.id,
      token: row.token,
      workspace_id: row.workspace_id,
      created_by: row.created_by,
      created_at: row.created_at,
      expires_at: row.expires_at,
      is_active: row.is_active,
      access_count: row.access_count,
      last_accessed_at: row.last_accessed_at,
      has_password: row.password_hash !== null
    };
  }

  /**
   * Delete share link
   */
  async delete(id) {
    const query = 'DELETE FROM share_links WHERE id = $1 RETURNING id';
    const result = await this.db.query(query, [id]);
    return result.rows.length > 0;
  }

  /**
   * Get access logs for a share link
   */
  async getAccessLogs(shareLinkId, limit = 50) {
    const query = `
      SELECT
        id,
        visitor_ip,
        visitor_user_agent,
        accessed_at
      FROM share_access_logs
      WHERE share_link_id = $1
      ORDER BY accessed_at DESC
      LIMIT $2
    `;

    const result = await this.db.query(query, [shareLinkId, limit]);
    return result.rows;
  }

  /**
   * Get share link stats
   */
  async getStats(shareLinkId) {
    const query = `
      SELECT
        sl.access_count,
        sl.created_at,
        sl.last_accessed_at,
        COUNT(DISTINCT sal.visitor_ip) as unique_visitors,
        COUNT(sal.id) as total_visits
      FROM share_links sl
      LEFT JOIN share_access_logs sal ON sl.id = sal.share_link_id
      WHERE sl.id = $1
      GROUP BY sl.id, sl.access_count, sl.created_at, sl.last_accessed_at
    `;

    const result = await this.db.query(query, [shareLinkId]);
    return result.rows[0] || null;
  }
}

module.exports = ShareLinkModel;
