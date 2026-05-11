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
    if (newWorkspace.rows.length === 0) {
      throw new Error(`Source workspace with id ${sourceId} not found`);
    }
    const newWorkspaceId = newWorkspace.rows[0].id;
    console.log(`[duplicateWorkspace] Created new workspace ${newWorkspaceId} (${newName}) from source ${sourceId}`);
    
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
    console.log(`[duplicateWorkspace] Fetching cmdb_items for workspace ${sourceId}`);
    const sourceItems = await client.query(
      'SELECT * FROM cmdb_items WHERE workspace_id = $1',
      [sourceId]
    );
    console.log(`[duplicateWorkspace] Found ${sourceItems.rows.length} items to duplicate`);

    // 5. Create item mapping (old_id -> new_id)
    const itemMap = {};
    for (const oldItem of sourceItems.rows) {
      const mappedGroupId = oldItem.group_id ? groupMap[oldItem.group_id] : null;

      const newItem = await client.query(
        `INSERT INTO cmdb_items (
          name, type, description, status, ip, category, location,
          group_id, order_in_group, env_type, position, workspace_id, alias, port
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14) RETURNING id`,
        [
          oldItem.name,
          oldItem.type,
          oldItem.description,
          oldItem.status,
          oldItem.ip,
          oldItem.category,
          oldItem.location,
          mappedGroupId,
          oldItem.order_in_group,
          oldItem.env_type,
          oldItem.position,
          newWorkspaceId,
          oldItem.alias || null,
          oldItem.port || null
        ]
      );
      itemMap[oldItem.id] = newItem.rows[0].id;
    }
    console.log(`[duplicateWorkspace] Item duplication complete. ${Object.keys(itemMap).length} items duplicated`);

    // 5. Duplicate services
    console.log(`[duplicateWorkspace] Fetching services for workspace ${sourceId}`);
    const sourceServices = await client.query(
      'SELECT * FROM services WHERE workspace_id = $1',
      [sourceId]
    );
    console.log(`[duplicateWorkspace] Found ${sourceServices.rows.length} services to duplicate`);

    const serviceMap = {};
    for (const oldService of sourceServices.rows) {
      const mappedCmdbItemId = itemMap[oldService.cmdb_item_id];

      if (!mappedCmdbItemId) {
        console.warn(`Skipping service ${oldService.id} - parent cmdb_item not found in mapping`);
        continue;
      }

      const newService = await client.query(
        `INSERT INTO services (
          cmdb_item_id, name, status, icon_type, icon_path, icon_name,
          description, position, width, height, is_expanded, workspace_id
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) RETURNING id`,
        [
          mappedCmdbItemId,
          oldService.name,
          oldService.status,
          oldService.icon_type || 'preset',
          oldService.icon_path || null,
          oldService.icon_name || null,
          oldService.description || null,
          oldService.position || '{"x": 0, "y": 0}',
          oldService.width || 120,
          oldService.height || 80,
          oldService.is_expanded || false,
          newWorkspaceId
        ]
      );
      serviceMap[oldService.id] = newService.rows[0].id;
      console.log(`[duplicateWorkspace] Duplicated service ${oldService.id} -> ${newService.rows[0].id} (${oldService.name})`);
    }
    console.log(`[duplicateWorkspace] Service duplication complete. ${Object.keys(serviceMap).length} services duplicated`);

    // 5b. Duplicate service_groups
    const sourceServiceGroups = await client.query(
      'SELECT * FROM service_groups WHERE workspace_id = $1',
      [sourceId]
    );

    const serviceGroupMap = {};
    for (const oldSg of sourceServiceGroups.rows) {
      const mappedServiceId = serviceMap[oldSg.service_id];

      if (!mappedServiceId) {
        console.warn(`Skipping service_group ${oldSg.id} - parent service not found`);
        continue;
      }

      const newSg = await client.query(
        `INSERT INTO service_groups (service_id, name, description, color, position, workspace_id)
         VALUES ($1, $2, $3, $4, $5, $6) RETURNING id`,
        [
          mappedServiceId,
          oldSg.name,
          oldSg.description || null,
          oldSg.color || '#e0e7ff',
          oldSg.position || null,
          newWorkspaceId
        ]
      );
      serviceGroupMap[oldSg.id] = newSg.rows[0].id;
    }

    // 5c. Duplicate service_items
    const sourceServiceItems = await client.query(
      'SELECT * FROM service_items WHERE workspace_id = $1',
      [sourceId]
    );

    const serviceItemMap = {};
    for (const oldSi of sourceServiceItems.rows) {
      const mappedServiceId = serviceMap[oldSi.service_id];
      const mappedGroupId = oldSi.group_id ? serviceGroupMap[oldSi.group_id] : null;

      if (!mappedServiceId) {
        console.warn(`Skipping service_item ${oldSi.id} - parent service not found`);
        continue;
      }

      const newSi = await client.query(
        `INSERT INTO service_items (
          service_id, name, type, description, position, status,
          ip, category, location, group_id, order_in_group, domain, port, workspace_id
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14) RETURNING id`,
        [
          mappedServiceId,
          oldSi.name,
          oldSi.type || null,
          oldSi.description || null,
          oldSi.position || '{"x": 0, "y": 0}',
          oldSi.status || 'active',
          oldSi.ip || null,
          oldSi.category || null,
          oldSi.location || null,
          mappedGroupId,
          oldSi.order_in_group || 0,
          oldSi.domain || null,
          oldSi.port || null,
          newWorkspaceId
        ]
      );
      serviceItemMap[oldSi.id] = newSi.rows[0].id;
    }

    // 5d. Duplicate service_to_service_connections
    const sourceSvcSvcConnections = await client.query(
      `SELECT * FROM service_to_service_connections WHERE workspace_id = $1`,
      [sourceId]
    );

    for (const conn of sourceSvcSvcConnections.rows) {
      const mappedSourceId = serviceMap[conn.source_service_id];
      const mappedTargetId = serviceMap[conn.target_service_id];
      const mappedCmdbItemId = itemMap[conn.cmdb_item_id];

      if (!mappedSourceId || !mappedTargetId) {
        console.warn(`Skipping service_to_service_connection ${conn.id} - service not found in mapping`);
        continue;
      }

      await client.query(
        `INSERT INTO service_to_service_connections (
          source_service_id, target_service_id, cmdb_item_id, connection_type,
          direction, propagation, workspace_id
        ) VALUES ($1, $2, $3, $4, $5, $6, $7)`,
        [
          mappedSourceId,
          mappedTargetId,
          mappedCmdbItemId || null,
          conn.connection_type || 'connects_to',
          conn.direction || 'forward',
          conn.propagation || 'both',
          newWorkspaceId
        ]
      );
    }

    // 5e. Duplicate cross_service_connections
    const sourceCrossConnections = await client.query(
      `SELECT * FROM cross_service_connections WHERE workspace_id = $1`,
      [sourceId]
    );

    for (const conn of sourceCrossConnections.rows) {
      const mappedSourceId = serviceItemMap[conn.source_service_item_id];
      const mappedTargetId = serviceItemMap[conn.target_service_item_id];

      if (!mappedSourceId || !mappedTargetId) {
        console.warn(`Skipping cross_service_connection ${conn.id} - service item not found in mapping`);
        continue;
      }

      await client.query(
        `INSERT INTO cross_service_connections (
          source_service_item_id, target_service_item_id, connection_type,
          direction, propagation_enabled, workspace_id
        ) VALUES ($1, $2, $3, $4, $5, $6)`,
        [
          mappedSourceId,
          mappedTargetId,
          conn.connection_type || 'connects_to',
          conn.direction || 'forward',
          conn.propagation_enabled !== false,
          newWorkspaceId
        ]
      );
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

    // 5f. Duplicate service_edge_handles
    // Use ON CONFLICT DO NOTHING to handle duplicates gracefully
    try {
      console.log(`[duplicateWorkspace] Fetching service_edge_handles for workspace ${sourceId}`);
      const sourceServiceEdgeHandles = await client.query(
        `SELECT * FROM service_edge_handles WHERE workspace_id = $1`,
        [sourceId]
      );
      console.log(`[duplicateWorkspace] Found ${sourceServiceEdgeHandles.rows.length} service_edge_handles to duplicate`);

      for (const edge of sourceServiceEdgeHandles.rows) {
        const newServiceId = serviceMap[edge.service_id];
        if (!newServiceId) {
          console.warn(`Skipping service_edge_handle ${edge.id} - service ${edge.service_id} not found in mapping`);
          continue;
        }

        // service_edge_handles edge_id format: 'e{itemId}-{itemId}'
        let newEdgeId = edge.edge_id;
        const itemToItemMatch = edge.edge_id.match(/^e(\d+)-(\d+)$/);
        if (itemToItemMatch) {
          const oldSourceItemId = parseInt(itemToItemMatch[1]);
          const oldTargetItemId = parseInt(itemToItemMatch[2]);
          const newSourceItemId = itemMap[oldSourceItemId];
          const newTargetItemId = itemMap[oldTargetItemId];
          if (newSourceItemId && newTargetItemId) {
            newEdgeId = `e${newSourceItemId}-${newTargetItemId}`;
          }
        }

        // Use ON CONFLICT DO NOTHING to handle duplicates gracefully
        await client.query(
          `INSERT INTO service_edge_handles (edge_id, source_handle, target_handle, service_id, workspace_id)
           VALUES ($1, $2, $3, $4, $5)
           ON CONFLICT (edge_id) DO NOTHING`,
          [newEdgeId, edge.source_handle, edge.target_handle, newServiceId, newWorkspaceId]
        );
      }
      console.log(`[duplicateWorkspace] service_edge_handles duplication complete`);
    } catch (err) {
      console.warn('Error duplicating service_edge_handles:', err.message);
    }

    // 5g. Duplicate cross_service_edge_handles
    // Use ON CONFLICT DO NOTHING to handle duplicates gracefully
    try {
      console.log(`[duplicateWorkspace] Fetching cross_service_edge_handles for workspace ${sourceId}`);
      const sourceCrossEdgeHandles = await client.query(
        `SELECT * FROM cross_service_edge_handles WHERE workspace_id = $1`,
        [sourceId]
      );
      console.log(`[duplicateWorkspace] Found ${sourceCrossEdgeHandles.rows.length} cross_service_edge_handles to duplicate`);

      for (const edge of sourceCrossEdgeHandles.rows) {
        const newSourceServiceId = serviceMap[edge.source_service_id];
        const newTargetServiceId = serviceMap[edge.target_service_id];
        const newViewingServiceId = edge.viewing_service_id ? serviceMap[edge.viewing_service_id] : null;

        if (!newSourceServiceId || !newTargetServiceId) {
          console.warn(`Skipping cross_service_edge_handle ${edge.id} - service not found`);
          continue;
        }

        // edge_id format: 'cross-service-{sourceItemId}-{targetItemId}'
        let newEdgeId = edge.edge_id;
        const crossMatch = edge.edge_id.match(/^cross-service-(\d+)-(\d+)$/);
        if (crossMatch) {
          const oldSourceItemId = parseInt(crossMatch[1]);
          const oldTargetItemId = parseInt(crossMatch[2]);
          const newSourceItemId = serviceItemMap[oldSourceItemId];
          const newTargetItemId = serviceItemMap[oldTargetItemId];
          if (newSourceItemId && newTargetItemId) {
            newEdgeId = `cross-service-${newSourceItemId}-${newTargetItemId}`;
          }
        }

        // Use ON CONFLICT DO NOTHING to handle duplicates gracefully
        // Unique constraint: (edge_id, source_service_id, target_service_id, viewing_service_id)
        await client.query(
          `INSERT INTO cross_service_edge_handles (edge_id, source_service_id, target_service_id, source_handle, target_handle, workspace_id, viewing_service_id)
           VALUES ($1, $2, $3, $4, $5, $6, $7)
           ON CONFLICT (edge_id, source_service_id, target_service_id, viewing_service_id) DO NOTHING`,
          [newEdgeId, newSourceServiceId, newTargetServiceId, edge.source_handle, edge.target_handle, newWorkspaceId, newViewingServiceId]
        );
        console.log(`[duplicateWorkspace] Duplicated cross_service_edge_handle ${edge.id}`);
      }
      console.log(`[duplicateWorkspace] cross_service_edge_handles duplication complete`);
    } catch (err) {
      console.warn('Error duplicating cross_service_edge_handles:', err.message);
    }

    // 5h. Duplicate external_item_positions
    try {
      const sourceExternalPositions = await client.query(
        `SELECT * FROM external_item_positions WHERE workspace_id = $1`,
        [sourceId]
      );

      for (const pos of sourceExternalPositions.rows) {
        const newViewingServiceId = pos.viewing_service_id ? serviceMap[pos.viewing_service_id] : null;
        const newExternalItemId = serviceItemMap[pos.external_service_item_id];

        if (!newViewingServiceId || !newExternalItemId) {
          console.warn(`Skipping external_item_position - mapping not found`);
          continue;
        }

        await client.query(
          `INSERT INTO external_item_positions (workspace_id, service_id, external_service_item_id, position, is_auto_layouted, layout_hash)
           VALUES ($1, $2, $3, $4, $5, $6)`,
          [
            newWorkspaceId,
            newViewingServiceId,
            newExternalItemId,
            pos.position || '{"x": 0, "y": 0}',
            pos.is_auto_layouted || false,
            pos.layout_hash || null
          ]
        );
      }
    } catch (err) {
      console.warn('Error duplicating external_item_positions:', err.message);
    }

    await client.query('COMMIT');
    console.log(`[duplicateWorkspace] SUCCESS: Workspace ${newWorkspaceId} created successfully`);
    return newWorkspace;
  } catch (err) {
    console.error(`[duplicateWorkspace] ERROR:`, err);
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