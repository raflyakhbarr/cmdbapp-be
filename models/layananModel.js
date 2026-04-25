const pool = require('../db');

// Get all layanan by workspace
const getAllLayanan = (workspaceId = null) => {
  if (workspaceId) {
    return pool.query(
      'SELECT * FROM layanan WHERE workspace_id = $1 ORDER BY created_at DESC',
      [workspaceId]
    );
  }
  return pool.query('SELECT * FROM layanan ORDER BY created_at DESC');
};

const getLayananById = (id) => pool.query('SELECT * FROM layanan WHERE id = $1', [id]);

const createLayanan = (name, description, status = 'active', position = null, workspace_id) =>
  pool.query(
    `INSERT INTO layanan(name, description, status, position, workspace_id)
     VALUES($1, $2, $3, $4, $5) RETURNING *`,
    [name, description, status, position ? JSON.stringify(position) : null, workspace_id]
  );

const updateLayanan = (id, name, description, status) =>
  pool.query(
    `UPDATE layanan
     SET name = $1, description = $2, status = $3, updated_at = CURRENT_TIMESTAMP
     WHERE id = $4
     RETURNING *`,
    [name, description, status, id]
  );

const deleteLayanan = (id) => pool.query('DELETE FROM layanan WHERE id = $1', [id]);

const updateLayananPosition = (id, position) =>
  pool.query(
    'UPDATE layanan SET position = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *',
    [position, id]
  );

const updateLayananStatus = (id, status) =>
  pool.query(
    'UPDATE layanan SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *',
    [status, id]
  );

// Layanan Connections
const getAllLayananConnections = (workspaceId) => {
  return pool.query(`
    SELECT
      lc.*,
      COALESCE(l_source.status, s_source.status) as source_status,
      COALESCE(l_target.status, s_target.status) as target_status
    FROM layanan_connections lc
    LEFT JOIN layanan l_source ON lc.source_type = 'layanan' AND lc.source_id = l_source.id
    LEFT JOIN layanan l_target ON lc.target_type = 'layanan' AND lc.target_id = l_target.id
    LEFT JOIN services s_source ON lc.source_type = 'service' AND lc.source_id = s_source.id
    LEFT JOIN services s_target ON lc.target_type = 'service' AND lc.target_id = s_target.id
    WHERE lc.workspace_id = $1
    ORDER BY lc.created_at
  `, [workspaceId]);
};

const createLayananConnection = (source_type, source_id, target_type, target_id, workspace_id, connection_type = 'connects_to', propagation_enabled = true) =>
  pool.query(
    `INSERT INTO layanan_connections(source_type, source_id, target_type, target_id, workspace_id, connection_type, propagation_enabled)
     VALUES($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
    [source_type, source_id, target_type, target_id, workspace_id, connection_type, propagation_enabled]
  );

const deleteLayananConnection = (id) =>
  pool.query('DELETE FROM layanan_connections WHERE id = $1', [id]);

const updateLayananConnection = (id, propagation_enabled) =>
  pool.query(
    `UPDATE layanan_connections
     SET propagation_enabled = $1, updated_at = CURRENT_TIMESTAMP
     WHERE id = $2
     RETURNING *`,
    [propagation_enabled, id]
  );

const deleteLayananConnectionsBySource = (source_type, source_id) =>
  pool.query(
    'DELETE FROM layanan_connections WHERE source_type = $1 AND source_id = $2',
    [source_type, source_id]
  );

const deleteLayananConnectionsByTarget = (target_type, target_id) =>
  pool.query(
    'DELETE FROM layanan_connections WHERE target_type = $1 AND target_id = $2',
    [target_type, target_id]
  );

module.exports = {
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
};
