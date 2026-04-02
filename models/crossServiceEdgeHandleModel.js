const pool = require('../db');

// Get all cross-service edge handles for a workspace
const getAllCrossServiceEdgeHandles = (workspaceId) =>
  pool.query('SELECT * FROM cross_service_edge_handles WHERE workspace_id = $1', [workspaceId]);

// Get cross-service edge handle by edge ID
const getCrossServiceEdgeHandleByEdgeId = (edgeId) =>
  pool.query('SELECT * FROM cross_service_edge_handles WHERE edge_id = $1', [edgeId]);

// Get cross-service edge handles for specific service connection
const getCrossServiceEdgeHandlesByConnection = (sourceServiceId, targetServiceId, workspaceId) =>
  pool.query(
    `SELECT * FROM cross_service_edge_handles
     WHERE source_service_id = $1 AND target_service_id = $2 AND workspace_id = $3`,
    [sourceServiceId, targetServiceId, workspaceId]
  );

// Upsert cross-service edge handle dengan viewing service context
const upsertCrossServiceEdgeHandle = async (edgeId, sourceServiceId, targetServiceId, viewingServiceId, sourceHandle, targetHandle, workspaceId) => {
  const result = await pool.query(
    `INSERT INTO cross_service_edge_handles (edge_id, source_service_id, target_service_id, viewing_service_id, source_handle, target_handle, workspace_id, updated_at)
     VALUES ($1, $2, $3, $4, $5, $6, $7, CURRENT_TIMESTAMP)
     ON CONFLICT (edge_id, source_service_id, target_service_id, viewing_service_id)
     DO UPDATE SET
       source_handle = $5,
       target_handle = $6,
       workspace_id = $7,
       updated_at = CURRENT_TIMESTAMP
     RETURNING *`,
    [edgeId, sourceServiceId, targetServiceId, viewingServiceId, sourceHandle, targetHandle, workspaceId]
  );
  return result;
};

// Delete cross-service edge handle by edge ID
const deleteCrossServiceEdgeHandle = (edgeId) =>
  pool.query('DELETE FROM cross_service_edge_handles WHERE edge_id = $1', [edgeId]);

// Bulk upsert cross-service edge handles dengan viewing service support
const bulkUpsertCrossServiceEdgeHandles = async (edgeHandles, workspaceId) => {
  if (!edgeHandles || Object.keys(edgeHandles).length === 0) {
    return { rows: [] };
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const results = [];
    for (const [edgeId, handles] of Object.entries(edgeHandles)) {
      const result = await client.query(
        `INSERT INTO cross_service_edge_handles (edge_id, source_service_id, target_service_id, viewing_service_id, source_handle, target_handle, workspace_id, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, CURRENT_TIMESTAMP)
         ON CONFLICT (edge_id, source_service_id, target_service_id, viewing_service_id)
         DO UPDATE SET
           source_handle = $5,
           target_handle = $6,
           workspace_id = $7,
           updated_at = CURRENT_TIMESTAMP
         RETURNING *`,
        [edgeId, handles.sourceServiceId, handles.targetServiceId, handles.viewingServiceId, handles.sourceHandle, handles.targetHandle, workspaceId]
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
  getAllCrossServiceEdgeHandles,
  getCrossServiceEdgeHandleByEdgeId,
  getCrossServiceEdgeHandlesByConnection,
  upsertCrossServiceEdgeHandle,
  deleteCrossServiceEdgeHandle,
  bulkUpsertCrossServiceEdgeHandles,
};
