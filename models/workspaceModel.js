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

    // 5c-2. Duplicate service_connections (item-to-item connections within a service)
    const sourceServiceConnections = await client.query(
      `SELECT * FROM service_connections WHERE workspace_id = $1`,
      [sourceId]
    );
    console.log(`[duplicateWorkspace] Found ${sourceServiceConnections.rows.length} service_connections to duplicate`);

    let svcConnSuccess = 0;
    let svcConnSkipped = 0;
    for (const conn of sourceServiceConnections.rows) {
      const mappedServiceId = serviceMap[conn.service_id];
      const mappedSourceId = serviceItemMap[conn.source_id];
      const mappedTargetId = serviceItemMap[conn.target_id];

      if (!mappedServiceId || !mappedSourceId || !mappedTargetId) {
        console.warn(`[duplicateWorkspace] Skipping service_connection ${conn.id}: service_id=${conn.service_id}->${mappedServiceId}, source_id=${conn.source_id}->${mappedSourceId}, target_id=${conn.target_id}->${mappedTargetId}`);
        svcConnSkipped++;
        continue;
      }

      console.log(`[duplicateWorkspace] service_connection: service_id=${conn.service_id}->${mappedServiceId}, source_id=${conn.source_id}->${mappedSourceId}, target_id=${conn.target_id}->${mappedTargetId}`);
      await client.query(
        `INSERT INTO service_connections (
          service_id, source_id, target_id, workspace_id, connection_type, propagation
        ) VALUES ($1, $2, $3, $4, $5, $6)`,
        [
          mappedServiceId,
          mappedSourceId,
          mappedTargetId,
          newWorkspaceId,
          conn.connection_type || 'connects_to',
          conn.propagation || 'source_to_target'
        ]
      );
      svcConnSuccess++;
    }
    console.log(`[duplicateWorkspace] service_connections duplication: ${svcConnSuccess} success, ${svcConnSkipped} skipped`);

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

    const crossServiceConnMap = {};
    for (const conn of sourceCrossConnections.rows) {
      const mappedSourceId = serviceItemMap[conn.source_service_item_id];
      const mappedTargetId = serviceItemMap[conn.target_service_item_id];

      if (!mappedSourceId || !mappedTargetId) {
        console.warn(`Skipping cross_service_connection ${conn.id} - service item not found in mapping`);
        continue;
      }

      const insertResult = await client.query(
        `INSERT INTO cross_service_connections (
          source_service_item_id, target_service_item_id, connection_type,
          direction, propagation_enabled, workspace_id
        ) VALUES ($1, $2, $3, $4, $5, $6)
        RETURNING id`,
        [
          mappedSourceId,
          mappedTargetId,
          conn.connection_type || 'connects_to',
          conn.direction || 'forward',
          conn.propagation_enabled !== false,
          newWorkspaceId
        ]
      );
      crossServiceConnMap[conn.id] = insertResult.rows[0].id;
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
      const mappedSourceServiceId = conn.source_service_id ? serviceMap[conn.source_service_id] : null;
      const mappedTargetServiceId = conn.target_service_id ? serviceMap[conn.target_service_id] : null;
      const mappedSourceServiceItemId = conn.source_service_item_id ? serviceItemMap[conn.source_service_item_id] : null;
      const mappedTargetServiceItemId = conn.target_service_item_id ? serviceItemMap[conn.target_service_item_id] : null;

      if (!mappedSourceId && !mappedSourceGroupId && !mappedSourceServiceId && !mappedSourceServiceItemId) continue;
      if (!mappedTargetId && !mappedTargetGroupId && !mappedTargetServiceId && !mappedTargetServiceItemId) continue;

      await client.query(
        `INSERT INTO connections (
          source_id, target_id, source_group_id, target_group_id,
          source_service_id, target_service_id,
          source_service_item_id, target_service_item_id,
          connection_type, direction, workspace_id
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
        [
          mappedSourceId,
          mappedTargetId,
          mappedSourceGroupId,
          mappedTargetGroupId,
          mappedSourceServiceId,
          mappedTargetServiceId,
          mappedSourceServiceItemId,
          mappedTargetServiceItemId,
          conn.connection_type || 'depends_on',
          conn.direction || 'forward',
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
      console.log(`[duplicateWorkspace] Found ${sourceEdgeHandles.rows.length} edge_handles to duplicate`);
      console.log(`[duplicateWorkspace] itemMap keys: ${Object.keys(itemMap).length}, groupMap keys: ${Object.keys(groupMap).length}, serviceMap keys: ${Object.keys(serviceMap).length}, serviceItemMap keys: ${Object.keys(serviceItemMap).length}`);

      for (const edge of sourceEdgeHandles.rows) {
        const edgeId = edge.edge_id;
        let newEdgeId = null;

        // Pattern 1: e{id}-{id} — could be CMDB item-to-item OR service item-to-item
        // CMDB items are stored in edge_handles via CMDBVisualization
        // Service items are stored in edge_handles via ServiceVisualization (not service_edge_handles)
        // Try itemMap first, fall back to serviceItemMap
        const itemToItemMatch = edgeId.match(/^e(\d+)-(\d+)$/);
        if (itemToItemMatch) {
          const oldSourceId = parseInt(itemToItemMatch[1]);
          const oldTargetId = parseInt(itemToItemMatch[2]);

          // Try CMDB item map first
          let newSourceId = itemMap[oldSourceId];
          let newTargetId = itemMap[oldTargetId];

          if (newSourceId && newTargetId) {
            newEdgeId = `e${newSourceId}-${newTargetId}`;
          } else {
            // Fall back to service item map (ServiceVisualization stores handles in edge_handles)
            newSourceId = serviceItemMap[oldSourceId];
            newTargetId = serviceItemMap[oldTargetId];
            if (newSourceId && newTargetId) {
              newEdgeId = `e${newSourceId}-${newTargetId}`;
            }
          }
        }
        // eservice-* patterns MUST be checked BEFORE broad includes('-group'/'-service-')
        // to avoid being consumed by those conditions
        // Pattern: eservice-item-{sourceServiceItemId}-{targetId}
        else if (edgeId.startsWith('eservice-item-')) {
          const match = edgeId.match(/^eservice-item-(\d+)-(\d+)$/);
          if (match) {
            const newSourceServiceItemId = serviceItemMap[parseInt(match[1])];
            let newTargetId = itemMap[parseInt(match[2])];
            if (!newTargetId) {
              newTargetId = serviceItemMap[parseInt(match[2])];
            }
            if (newSourceServiceItemId && newTargetId) {
              newEdgeId = `eservice-item-${newSourceServiceItemId}-${newTargetId}`;
            }
          }
        }
        // Pattern: eservice-{serviceId}-service-item-{targetServiceItemId}
        else if (/^eservice-\d+-service-item-\d+$/.test(edgeId)) {
          const match = edgeId.match(/^eservice-(\d+)-service-item-(\d+)$/);
          if (match) {
            const newSourceId = serviceMap[parseInt(match[1])];
            const newTargetId = serviceItemMap[parseInt(match[2])];
            if (newSourceId && newTargetId) {
              newEdgeId = `eservice-${newSourceId}-service-item-${newTargetId}`;
            }
          }
        }
        // Pattern: eservice-{serviceId}-service-{targetServiceId}
        else if (/^eservice-\d+-service-\d+$/.test(edgeId)) {
          const match = edgeId.match(/^eservice-(\d+)-service-(\d+)$/);
          if (match) {
            const newSourceId = serviceMap[parseInt(match[1])];
            const newTargetId = serviceMap[parseInt(match[2])];
            if (newSourceId && newTargetId) {
              newEdgeId = `eservice-${newSourceId}-service-${newTargetId}`;
            }
          }
        }
        // Pattern: eservice-{serviceId}-group{groupId}
        else if (/^eservice-\d+-group\d+$/.test(edgeId)) {
          const match = edgeId.match(/^eservice-(\d+)-group(\d+)$/);
          if (match) {
            const newSourceId = serviceMap[parseInt(match[1])];
            const newTargetId = groupMap[parseInt(match[2])];
            if (newSourceId && newTargetId) {
              newEdgeId = `eservice-${newSourceId}-group${newTargetId}`;
            }
          }
        }
        // Pattern: eservice-{serviceId}-{targetId}
        else if (/^eservice-\d+-\d+$/.test(edgeId)) {
          const match = edgeId.match(/^eservice-(\d+)-(\d+)$/);
          if (match) {
            const newSourceId = serviceMap[parseInt(match[1])];
            let newTargetId = itemMap[parseInt(match[2])];
            if (!newTargetId) {
              newTargetId = serviceItemMap[parseInt(match[2])];
            }
            if (newSourceId && newTargetId) {
              newEdgeId = `eservice-${newSourceId}-${newTargetId}`;
            }
          }
        }
        // Pattern: cross-service-{sourceServiceItemId}-{targetServiceItemId} (new format)
        else if (/^cross-service-\d+-\d+$/.test(edgeId)) {
          const match = edgeId.match(/^cross-service-(\d+)-(\d+)$/);
          if (match) {
            const newSourceId = serviceItemMap[parseInt(match[1])];
            const newTargetId = serviceItemMap[parseInt(match[2])];
            if (newSourceId && newTargetId) {
              newEdgeId = `cross-service-${newSourceId}-${newTargetId}`;
            }
          }
        }
        // Pattern: cross-service-connection-{connectionId} (legacy format)
        else if (edgeId.startsWith('cross-service-connection-')) {
          const match = edgeId.match(/^cross-service-connection-(\d+)$/);
          if (match) {
            const oldConnId = parseInt(match[1]);
            const newConnId = crossServiceConnMap[oldConnId];
            if (newConnId) {
              newEdgeId = `cross-service-connection-${newConnId}`;
            }
          }
        }
        // Pattern: group-e{sourceGroupId}-{targetGroupId} (group-to-group)
        else if (edgeId.startsWith('group-e')) {
          const match = edgeId.match(/^group-e(\d+)-(\d+)$/);
          if (match) {
            const newSourceGroupId = groupMap[parseInt(match[1])];
            const newTargetGroupId = groupMap[parseInt(match[2])];
            if (newSourceGroupId && newTargetGroupId) {
              newEdgeId = `group-e${newSourceGroupId}-${newTargetGroupId}`;
            }
          }
        }
        // Pattern: group{groupId}-e{targetItemId} (group-to-item)
        else if (edgeId.startsWith('group') && edgeId.includes('-e')) {
          const match = edgeId.match(/^group(\d+)-e(\d+)$/);
          if (match) {
            const newGroupId = groupMap[parseInt(match[1])];
            const newTargetId = itemMap[parseInt(match[2])];
            if (newGroupId && newTargetId) {
              newEdgeId = `group${newGroupId}-e${newTargetId}`;
            }
          }
        }
        // Pattern: e{sourceItemId}-group{groupId} (item-to-group)
        else if (edgeId.includes('-group')) {
          const match = edgeId.match(/^e(\d+)-group(\d+)$/);
          if (match) {
            const newSourceId = itemMap[parseInt(match[1])];
            const newGroupId = groupMap[parseInt(match[2])];
            if (newSourceId && newGroupId) {
              newEdgeId = `e${newSourceId}-group${newGroupId}`;
            }
          }
        }
        // Pattern: e{sourceId}-service-item-{targetServiceItemId}
        else if (edgeId.includes('-service-item-')) {
          const match = edgeId.match(/^e(\d+)-service-item-(\d+)$/);
          if (match) {
            const newSourceId = itemMap[parseInt(match[1])];
            const newTargetId = serviceItemMap[parseInt(match[2])];
            if (newSourceId && newTargetId) {
              newEdgeId = `e${newSourceId}-service-item-${newTargetId}`;
            }
          }
        }
        // Pattern: e{sourceId}-service-{targetServiceId}
        else if (edgeId.includes('-service-')) {
          const match = edgeId.match(/^e(\d+)-service-(\d+)$/);
          if (match) {
            const newSourceId = itemMap[parseInt(match[1])];
            const newTargetId = serviceMap[parseInt(match[2])];
            if (newSourceId && newTargetId) {
              newEdgeId = `e${newSourceId}-service-${newTargetId}`;
            }
          }
        }
        
        if (newEdgeId) {
          console.log(`[duplicateWorkspace] edge_handles: "${edgeId}" -> "${newEdgeId}" (handles: ${edge.source_handle} -> ${edge.target_handle})`);
          await client.query(
            `INSERT INTO edge_handles (edge_id, source_handle, target_handle, workspace_id, created_at, updated_at)
             VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
             ON CONFLICT (edge_id) DO NOTHING`,
            [newEdgeId, edge.source_handle, edge.target_handle, newWorkspaceId]
          );
        } else {
          console.warn(`[duplicateWorkspace] edge_handles: SKIPPED "${edgeId}" - no pattern matched or mapping failed`);
        }
      }
    } catch (err) {
      console.warn('Error duplicating edge_handles:', err.message);
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

        let newEdgeId = edge.edge_id;

        // Pattern A: e{serviceItemId}-{serviceItemId} (item-to-item within service)
        const itemToItemMatch = edge.edge_id.match(/^e(\d+)-(\d+)$/);
        if (itemToItemMatch) {
          const oldSourceId = parseInt(itemToItemMatch[1]);
          const oldTargetId = parseInt(itemToItemMatch[2]);
          const newSourceId = serviceItemMap[oldSourceId];
          const newTargetId = serviceItemMap[oldTargetId];
          if (newSourceId && newTargetId) {
            newEdgeId = `e${newSourceId}-${newTargetId}`;
          }
        }
        // Pattern B: service-group-e{sourceGroupId}-{targetGroupId} (group-to-group within service)
        else if (edge.edge_id.startsWith('service-group-e')) {
          const match = edge.edge_id.match(/^service-group-e(\d+)-(\d+)$/);
          if (match) {
            const oldSourceGroupId = parseInt(match[1]);
            const oldTargetGroupId = parseInt(match[2]);
            const newSourceGroupId = serviceGroupMap[oldSourceGroupId];
            const newTargetGroupId = serviceGroupMap[oldTargetGroupId];
            if (newSourceGroupId && newTargetGroupId) {
              newEdgeId = `service-group-e${newSourceGroupId}-${newTargetGroupId}`;
            }
          }
        }
        // Pattern C: service-group-item-e{groupId}-{itemId} (group-to-item within service)
        else if (edge.edge_id.startsWith('service-group-item-e')) {
          const match = edge.edge_id.match(/^service-group-item-e(\d+)-(\d+)$/);
          if (match) {
            const oldGroupId = parseInt(match[1]);
            const oldItemId = parseInt(match[2]);
            const newGroupId = serviceGroupMap[oldGroupId];
            const newItemId = serviceItemMap[oldItemId];
            if (newGroupId && newItemId) {
              newEdgeId = `service-group-item-e${newGroupId}-${newItemId}`;
            }
          }
        }
        // Pattern D: service-item-group-e{itemId}-{groupId} (item-to-group within service)
        else if (edge.edge_id.startsWith('service-item-group-e')) {
          const match = edge.edge_id.match(/^service-item-group-e(\d+)-(\d+)$/);
          if (match) {
            const oldItemId = parseInt(match[1]);
            const oldGroupId = parseInt(match[2]);
            const newItemId = serviceItemMap[oldItemId];
            const newGroupId = serviceGroupMap[oldGroupId];
            if (newItemId && newGroupId) {
              newEdgeId = `service-item-group-e${newItemId}-${newGroupId}`;
            }
          }
        }

        // Use ON CONFLICT DO NOTHING to handle duplicates gracefully
        const oldEdgeId = edge.edge_id;
        if (newEdgeId !== oldEdgeId) {
          console.log(`[duplicateWorkspace] service_edge_handles: "${oldEdgeId}" -> "${newEdgeId}" (service: ${edge.service_id} -> ${newServiceId}, handles: ${edge.source_handle} -> ${edge.target_handle})`);
        } else {
          console.warn(`[duplicateWorkspace] service_edge_handles: UNMAPPED "${oldEdgeId}" - mapping failed, inserting with original edge_id (will NOT match new edges!)`);
        }
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