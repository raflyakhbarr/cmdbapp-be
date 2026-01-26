const pool = require('../db');

const getAllWorkspaces = () => 
  pool.query('SELECT * FROM workspaces ORDER BY is_default DESC, created_at ASC');

const getWorkspaceById = (id) => 
  pool.query('SELECT * FROM workspaces WHERE id = $1', [id]);

const getDefaultWorkspace = () =>
  pool.query('SELECT * FROM workspaces WHERE is_default = true LIMIT 1');

const createWorkspace = (name, description = null) =>
  pool.query(
    'INSERT INTO workspaces(name, description, is_default) VALUES($1, $2, false) RETURNING *',
    [name, description]
  );

const updateWorkspace = (id, name, description) =>
  pool.query(
    'UPDATE workspaces SET name = $1, description = $2, updated_at = CURRENT_TIMESTAMP WHERE id = $3 RETURNING *',
    [name, description, id]
  );

const deleteWorkspace = async (id) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    
    // Check if it's the default workspace
    const workspace = await client.query('SELECT is_default FROM workspaces WHERE id = $1', [id]);
    if (workspace.rows[0]?.is_default) {
      throw new Error('Cannot delete default workspace');
    }
    
    // Delete all related data (cascade should handle this, but explicit for clarity)
    await client.query('DELETE FROM edge_handles WHERE workspace_id = $1', [id]);
    await client.query('DELETE FROM connections WHERE workspace_id = $1', [id]);
    await client.query('DELETE FROM group_connections WHERE workspace_id = $1', [id]);
    await client.query('DELETE FROM cmdb_items WHERE workspace_id = $1', [id]);
    await client.query('DELETE FROM cmdb_groups WHERE workspace_id = $1', [id]);
    
    // Delete workspace
    const result = await client.query('DELETE FROM workspaces WHERE id = $1 RETURNING *', [id]);
    
    await client.query('COMMIT');
    return result;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

const setDefaultWorkspace = async (id) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    
    // Remove default from all workspaces
    await client.query('UPDATE workspaces SET is_default = false');
    
    // Set new default
    const result = await client.query(
      'UPDATE workspaces SET is_default = true, updated_at = CURRENT_TIMESTAMP WHERE id = $1 RETURNING *',
      [id]
    );
    
    await client.query('COMMIT');
    return result;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

const duplicateWorkspace = async (sourceId, newName) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    
    // 1. Create new workspace
    const newWorkspace = await client.query(
      'INSERT INTO workspaces(name, description, is_default) SELECT $1, description, false FROM workspaces WHERE id = $2 RETURNING *',
      [newName, sourceId]
    );
    const newWorkspaceId = newWorkspace.rows[0].id;
    
    // 2. Get source groups
    const sourceGroups = await client.query(
      'SELECT * FROM cmdb_groups WHERE workspace_id = $1',
      [sourceId]
    );
    
    // 3. Create group mapping (old_id -> new_id)
    const groupMap = {};
    for (const oldGroup of sourceGroups.rows) {
      const newGroup = await client.query(
        `INSERT INTO cmdb_groups (name, description, color, position, workspace_id)
         VALUES ($1, $2, $3, $4, $5) RETURNING id`,
        [oldGroup.name, oldGroup.description, oldGroup.color, oldGroup.position, newWorkspaceId]
      );
      groupMap[oldGroup.id] = newGroup.rows[0].id;
    }
    
    // 4. Get source items
    const sourceItems = await client.query(
      'SELECT * FROM cmdb_items WHERE workspace_id = $1',
      [sourceId]
    );
    
    // 5. Create item mapping (old_id -> new_id)
    const itemMap = {};
    for (const oldItem of sourceItems.rows) {
      const mappedGroupId = oldItem.group_id ? groupMap[oldItem.group_id] : null;
      
      let imagesData = oldItem.images;
      if (typeof imagesData === 'string') {
        try {
          imagesData = JSON.parse(imagesData);
        } catch (e) {
          imagesData = [];
        }
      }
      if (!Array.isArray(imagesData)) {
        imagesData = [];
      }
      
      const newItem = await client.query(
        `INSERT INTO cmdb_items (
          name, type, description, status, ip, category, location, images, 
          group_id, order_in_group, env_type, position, workspace_id
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8::json, $9, $10, $11, $12, $13) RETURNING id`,
        [
          oldItem.name, 
          oldItem.type, 
          oldItem.description, 
          oldItem.status, 
          oldItem.ip, 
          oldItem.category, 
          oldItem.location, 
          JSON.stringify(imagesData),
          mappedGroupId, 
          oldItem.order_in_group, 
          oldItem.env_type, 
          oldItem.position, 
          newWorkspaceId
        ]
      );
      itemMap[oldItem.id] = newItem.rows[0].id;
    }
    
    // 6. Duplicate connections
    const sourceConnections = await client.query(
      `SELECT * FROM connections WHERE workspace_id = $1`,
      [sourceId]
    );
    
    for (const conn of sourceConnections.rows) {
      const mappedSourceId = conn.source_id ? itemMap[conn.source_id] : null;
      const mappedTargetId = conn.target_id ? itemMap[conn.target_id] : null;
      const mappedSourceGroupId = conn.source_group_id ? groupMap[conn.source_group_id] : null;
      const mappedTargetGroupId = conn.target_group_id ? groupMap[conn.target_group_id] : null;
      
      if (!mappedSourceId && !mappedSourceGroupId) continue;
      if (!mappedTargetId && !mappedTargetGroupId) continue;
      
      await client.query(
        `INSERT INTO connections (
          source_id, target_id, source_group_id, target_group_id, workspace_id
        ) VALUES ($1, $2, $3, $4, $5)`,
        [
          mappedSourceId,
          mappedTargetId,
          mappedSourceGroupId,
          mappedTargetGroupId,
          newWorkspaceId
        ]
      );
    }
    
    // 7. Duplicate group_connections
    const sourceGroupConnections = await client.query(
      `SELECT * FROM group_connections WHERE workspace_id = $1`,
      [sourceId]
    );
    
    for (const gConn of sourceGroupConnections.rows) {
      const mappedSourceId = groupMap[gConn.source_id] || null;
      const mappedTargetId = groupMap[gConn.target_id] || null;
      
      if (!mappedSourceId || !mappedTargetId) continue;
      
      await client.query(
        `INSERT INTO group_connections (source_id, target_id, workspace_id)
         VALUES ($1, $2, $3)`,
        [mappedSourceId, mappedTargetId, newWorkspaceId]
      );
    }
    
    // 8. Duplicate edge_handles
    try {
      const sourceEdgeHandles = await client.query(
        `SELECT * FROM edge_handles WHERE workspace_id = $1`,
        [sourceId]
      );
      
      for (const edge of sourceEdgeHandles.rows) {
        const edgeId = edge.edge_id;
        let newEdgeId = null;
        
        // Pattern 1: e{sourceItemId}-{targetItemId} (item-to-item)
        const itemToItemMatch = edgeId.match(/^e(\d+)-(\d+)$/);
        if (itemToItemMatch) {
          const oldSourceId = parseInt(itemToItemMatch[1]);
          const oldTargetId = parseInt(itemToItemMatch[2]);
          
          const newSourceId = itemMap[oldSourceId];
          const newTargetId = itemMap[oldTargetId];
          
          if (newSourceId && newTargetId) {
            newEdgeId = `e${newSourceId}-${newTargetId}`;
          }
        }
        // Pattern 2: e{sourceItemId}-group{groupId} (item-to-group)
        else if (edgeId.includes('-group')) {
          const match = edgeId.match(/^e(\d+)-group(\d+)$/);
          if (match) {
            const oldSourceId = parseInt(match[1]);
            const oldGroupId = parseInt(match[2]);
            
            const newSourceId = itemMap[oldSourceId];
            const newGroupId = groupMap[oldGroupId];
            
            if (newSourceId && newGroupId) {
              newEdgeId = `e${newSourceId}-group${newGroupId}`;
            }
          }
        }
        // Pattern 3: group{groupId}-e{targetItemId} (group-to-item)
        else if (edgeId.startsWith('group') && edgeId.includes('-e')) {
          const match = edgeId.match(/^group(\d+)-e(\d+)$/);
          if (match) {
            const oldGroupId = parseInt(match[1]);
            const oldTargetId = parseInt(match[2]);
            
            const newGroupId = groupMap[oldGroupId];
            const newTargetId = itemMap[oldTargetId];
            
            if (newGroupId && newTargetId) {
              newEdgeId = `group${newGroupId}-e${newTargetId}`;
            }
          }
        }
        // Pattern 4: group-e{sourceGroupId}-{targetGroupId} (group-to-group)
        else if (edgeId.startsWith('group-e')) {
          const match = edgeId.match(/^group-e(\d+)-(\d+)$/);
          if (match) {
            const oldSourceGroupId = parseInt(match[1]);
            const oldTargetGroupId = parseInt(match[2]);
            
            const newSourceGroupId = groupMap[oldSourceGroupId];
            const newTargetGroupId = groupMap[oldTargetGroupId];
            
            if (newSourceGroupId && newTargetGroupId) {
              newEdgeId = `group-e${newSourceGroupId}-${newTargetGroupId}`;
            }
          }
        }
        
        if (newEdgeId) {
          await client.query(
            `INSERT INTO edge_handles (edge_id, source_handle, target_handle, workspace_id, created_at, updated_at)
             VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`,
            [newEdgeId, edge.source_handle, edge.target_handle, newWorkspaceId]
          );
        }
      }
    } catch (err) {
      
    }
    
    await client.query('COMMIT');
    return newWorkspace;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

module.exports = {
  getAllWorkspaces,
  getWorkspaceById,
  getDefaultWorkspace,
  createWorkspace,
  updateWorkspace,
  deleteWorkspace,
  setDefaultWorkspace,
  duplicateWorkspace,
};