const pool = require('../db');

// Get all service edge handles for a specific service and workspace
const getAllServiceEdgeHandles = async (serviceId, workspaceId) => {
  const result = await pool.query(
    'SELECT * FROM service_edge_handles WHERE service_id = $1 AND workspace_id = $2',
    [serviceId, workspaceId]
  );

  // Transform array to object keyed by edge_id
  const handles = {};
  result.rows.forEach(row => {
    handles[row.edge_id] = {
      sourceHandle: row.source_handle,
      targetHandle: row.target_handle,
    };
  });

  return handles;
};

// Get a specific service edge handle by edge_id
const getServiceEdgeHandle = async (edgeId) => {
  const result = await pool.query(
    'SELECT * FROM service_edge_handles WHERE edge_id = $1',
    [edgeId]
  );
  return result.rows[0];
};

// Create or update a service edge handle
const upsertServiceEdgeHandle = async (edgeId, sourceHandle, targetHandle, serviceId, workspaceId) => {
  const result = await pool.query(
    `INSERT INTO service_edge_handles (edge_id, source_handle, target_handle, service_id, workspace_id)
     VALUES ($1, $2, $3, $4, $5)
     ON CONFLICT (edge_id)
     DO UPDATE SET
       source_handle = EXCLUDED.source_handle,
       target_handle = EXCLUDED.target_handle,
       updated_at = CURRENT_TIMESTAMP
     RETURNING *`,
    [edgeId, sourceHandle, targetHandle, serviceId, workspaceId]
  );
  return result.rows[0];
};

// Delete a service edge handle
const deleteServiceEdgeHandle = async (edgeId) => {
  const result = await pool.query(
    'DELETE FROM service_edge_handles WHERE edge_id = $1 RETURNING *',
    [edgeId]
  );
  return result.rows[0];
};

// Bulk upsert service edge handles
const bulkUpsertServiceEdgeHandles = async (handles, serviceId, workspaceId) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    for (const [edgeId, handleConfig] of Object.entries(handles)) {
      await client.query(
        `INSERT INTO service_edge_handles (edge_id, source_handle, target_handle, service_id, workspace_id)
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT (edge_id)
         DO UPDATE SET
           source_handle = EXCLUDED.source_handle,
           target_handle = EXCLUDED.target_handle,
           updated_at = CURRENT_TIMESTAMP`,
        [edgeId, handleConfig.sourceHandle, handleConfig.targetHandle, serviceId, workspaceId]
      );
    }

    await client.query('COMMIT');
    return { success: true };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

module.exports = {
  getAllServiceEdgeHandles,
  getServiceEdgeHandle,
  upsertServiceEdgeHandle,
  deleteServiceEdgeHandle,
  bulkUpsertServiceEdgeHandles,
};
