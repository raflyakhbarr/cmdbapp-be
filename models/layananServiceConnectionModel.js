const pool = require('../db');

// Get all layanan service connections by workspace
const getAllLayananServiceConnections = (workspaceId) => {
  return pool.query(
    `SELECT lsc.*, l.name as layanan_name, l.status as layanan_status,
            s.name as service_name, s.icon_type as service_icon_type,
            si.name as service_item_name, si.status as service_item_status,
            si.type as service_item_type,
            ci.name as cmdb_item_name
     FROM layanan_service_connections lsc
     LEFT JOIN layanan l ON lsc.layanan_id = l.id
     LEFT JOIN services s ON lsc.service_id = s.id
     LEFT JOIN service_items si ON lsc.service_item_id = si.id
     LEFT JOIN cmdb_items ci ON s.cmdb_item_id = ci.id
     WHERE lsc.workspace_id = $1
     ORDER BY lsc.created_at DESC`,
    [workspaceId]
  );
};

// Get layanan service connections by layanan ID
const getLayananServiceConnectionsByLayananId = (layananId) => {
  return pool.query(
    `SELECT lsc.*, l.name as layanan_name, l.status as layanan_status,
            s.name as service_name, s.icon_type as service_icon_type,
            si.name as service_item_name, si.status as service_item_status,
            si.type as service_item_type
     FROM layanan_service_connections lsc
     LEFT JOIN layanan l ON lsc.layanan_id = l.id
     LEFT JOIN services s ON lsc.service_id = s.id
     LEFT JOIN service_items si ON lsc.service_item_id = si.id
     WHERE lsc.layanan_id = $1
     ORDER BY lsc.created_at DESC`,
    [layananId]
  );
};

// Get layanan service connections by service item ID
const getLayananServiceConnectionsByServiceItemId = (serviceItemId) => {
  return pool.query(
    `SELECT lsc.*, l.name as layanan_name, l.status as layanan_status,
            s.name as service_name, s.icon_type as service_icon_type,
            si.name as service_item_name, si.status as service_item_status,
            si.type as service_item_type
     FROM layanan_service_connections lsc
     LEFT JOIN layanan l ON lsc.layanan_id = l.id
     LEFT JOIN services s ON lsc.service_id = s.id
     LEFT JOIN service_items si ON lsc.service_item_id = si.id
     WHERE lsc.service_item_id = $1
     ORDER BY lsc.created_at DESC`,
    [serviceItemId]
  );
};

// Create layanan service connection
const createLayananServiceConnection = async (
  layananId,
  serviceId,
  serviceItemId,
  workspaceId,
  connectionType = 'depends_on',
  propagationEnabled = true
) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Check if connection already exists
    const existingCheck = await client.query(
      `SELECT id FROM layanan_service_connections
       WHERE layanan_id = $1 AND service_item_id = $2`,
      [layananId, serviceItemId]
    );

    let result;
    if (existingCheck.rows.length > 0) {
      // Update existing connection
      result = await client.query(
        `UPDATE layanan_service_connections
         SET connection_type = $1, propagation_enabled = $2, updated_at = CURRENT_TIMESTAMP
         WHERE id = $3
         RETURNING *`,
        [connectionType, propagationEnabled, existingCheck.rows[0].id]
      );
    } else {
      // Get next ID from sequence
      const idResult = await client.query(`SELECT nextval('layanan_service_connections_id_seq') as new_id`);
      const newId = idResult.rows[0].new_id;

      // Insert new connection with explicit ID from sequence
      result = await client.query(
        `INSERT INTO layanan_service_connections (id, layanan_id, service_id, service_item_id, workspace_id, connection_type, propagation_enabled)
         VALUES($1, $2, $3, $4, $5, $6, $7)
         RETURNING *`,
        [newId, layananId, serviceId, serviceItemId, workspaceId, connectionType, propagationEnabled]
      );
    }

    await client.query('COMMIT');
    return result;
  } catch (err) {
    console.error('[ERROR] createLayananServiceConnection failed:', err);
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

// Update layanan service connection
const updateLayananServiceConnection = (id, connectionType, propagationEnabled) => {
  return pool.query(
    `UPDATE layanan_service_connections
     SET connection_type = $1, propagation_enabled = $2, updated_at = CURRENT_TIMESTAMP
     WHERE id = $3
     RETURNING *`,
    [connectionType, propagationEnabled, id]
  );
};

// Delete layanan service connection
const deleteLayananServiceConnection = (id) => {
  return pool.query('DELETE FROM layanan_service_connections WHERE id = $1', [id]);
};

// Delete all layanan service connections by layanan ID
const deleteLayananServiceConnectionsByLayananId = (layananId) => {
  return pool.query('DELETE FROM layanan_service_connections WHERE layanan_id = $1', [layananId]);
};

// Delete all layanan service connections by service item ID
const deleteLayananServiceConnectionsByServiceItemId = (serviceItemId) => {
  return pool.query('DELETE FROM layanan_service_connections WHERE service_item_id = $1', [serviceItemId]);
};

module.exports = {
  getAllLayananServiceConnections,
  getLayananServiceConnectionsByLayananId,
  getLayananServiceConnectionsByServiceItemId,
  createLayananServiceConnection,
  updateLayananServiceConnection,
  deleteLayananServiceConnection,
  deleteLayananServiceConnectionsByLayananId,
  deleteLayananServiceConnectionsByServiceItemId,
};
