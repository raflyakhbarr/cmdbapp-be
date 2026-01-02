const pool = require('../db');

const getAllEdgeHandles = () => 
  pool.query('SELECT * FROM edge_handles');

const getEdgeHandleByEdgeId = (edgeId) =>
  pool.query('SELECT * FROM edge_handles WHERE edge_id = $1', [edgeId]);

const upsertEdgeHandle = async (edgeId, sourceHandle, targetHandle) => {
  const result = await pool.query(
    `INSERT INTO edge_handles (edge_id, source_handle, target_handle, updated_at)
     VALUES ($1, $2, $3, CURRENT_TIMESTAMP)
     ON CONFLICT (edge_id) 
     DO UPDATE SET 
       source_handle = $2,
       target_handle = $3,
       updated_at = CURRENT_TIMESTAMP
     RETURNING *`,
    [edgeId, sourceHandle, targetHandle]
  );
  return result;
};

const deleteEdgeHandle = (edgeId) =>
  pool.query('DELETE FROM edge_handles WHERE edge_id = $1', [edgeId]);

const deleteEdgeHandles = async (edgeIds) => {
  if (!edgeIds || edgeIds.length === 0) return;
  
  const placeholders = edgeIds.map((_, i) => `$${i + 1}`).join(',');
  await pool.query(
    `DELETE FROM edge_handles WHERE edge_id IN (${placeholders})`,
    edgeIds
  );
};

const bulkUpsertEdgeHandles = async (edgeHandles) => {
  if (!edgeHandles || Object.keys(edgeHandles).length === 0) {
    return { rows: [] };
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    
    const results = [];
    for (const [edgeId, handles] of Object.entries(edgeHandles)) {
      const result = await client.query(
        `INSERT INTO edge_handles (edge_id, source_handle, target_handle, updated_at)
         VALUES ($1, $2, $3, CURRENT_TIMESTAMP)
         ON CONFLICT (edge_id) 
         DO UPDATE SET 
           source_handle = $2,
           target_handle = $3,
           updated_at = CURRENT_TIMESTAMP
         RETURNING *`,
        [edgeId, handles.sourceHandle, handles.targetHandle]
      );
      results.push(result.rows[0]);
    }
    
    await client.query('COMMIT');
    return { rows: results };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

module.exports = {
  getAllEdgeHandles,
  getEdgeHandleByEdgeId,
  upsertEdgeHandle,
  deleteEdgeHandle,
  deleteEdgeHandles,
  bulkUpsertEdgeHandles,
};