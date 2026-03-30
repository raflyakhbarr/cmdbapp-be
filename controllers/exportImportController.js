// cmdbapp-be/controllers/exportImportController.js

const pool = require('../db');

/**
 * Get all data for export
 */
async function getExportData(workspaceId) {
  // Validate workspaceId
  if (!workspaceId || isNaN(parseInt(workspaceId))) {
    throw new Error('Invalid workspace_id parameter');
  }

  try {

    // Fetch CMDB Items
    const itemsResult = await pool.query(`
      SELECT
        id, name, type, status, ip, port, description,
        position, group_id, order_in_group, workspace_id,
        category, location, env_type, storage, alias
      FROM cmdb_items
      WHERE workspace_id = $1
      ORDER BY id
    `, [workspaceId]);

    // Fetch Groups
    const groupsResult = await pool.query(`
      SELECT id, name, description, color, position, created_at, workspace_id
      FROM cmdb_groups
      WHERE workspace_id = $1
      ORDER BY id
    `, [workspaceId]);

    // Fetch Services (join with cmdb_items to get workspace filter)
    const servicesResult = await pool.query(`
      SELECT s.id, s.cmdb_item_id, s.name, s.status, s.icon_type, s.icon_path, s.icon_name, s.description
      FROM services s
      INNER JOIN cmdb_items ci ON s.cmdb_item_id = ci.id
      WHERE ci.workspace_id = $1
      ORDER BY s.id
    `, [workspaceId]);

    // Fetch Service Items
    const serviceItemsResult = await pool.query(`
      SELECT id, service_id, name, type, description, status, ip, category, location, position, group_id, order_in_group, domain, port
      FROM service_items
      WHERE workspace_id = $1
      ORDER BY id
    `, [workspaceId]);

    // Fetch Service Groups
    const serviceGroupsResult = await pool.query(`
      SELECT id, service_id, name, description, color, position, created_at, workspace_id
      FROM service_groups
      WHERE workspace_id = $1
      ORDER BY id
    `, [workspaceId]);

    // Fetch Service Group Connections
    const serviceGroupConnectionsResult = await pool.query(`
      SELECT id, service_id, source_id, target_id, source_group_id, target_group_id, target_item_id, workspace_id, created_at
      FROM service_group_connections
      WHERE workspace_id = $1
      ORDER BY id
    `, [workspaceId]);

    // Fetch Cross-Service Connections
    const connectionsResult = await pool.query(`
      SELECT
        id, source_service_item_id, target_service_item_id,
        connection_type, direction, workspace_id, created_at, updated_at
      FROM cross_service_connections
      WHERE workspace_id = $1
      ORDER BY id
    `, [workspaceId]);

    return {
      cmdbItems: itemsResult.rows,
      groups: groupsResult.rows,
      services: servicesResult.rows,
      serviceItems: serviceItemsResult.rows,
      serviceGroups: serviceGroupsResult.rows,
      serviceGroupConnections: serviceGroupConnectionsResult.rows,
      crossServiceConnections: connectionsResult.rows,
      metadata: [
        { key: 'export_date', value: new Date().toISOString() },
        { key: 'workspace_id', value: workspaceId },
        { key: 'version', value: '1.0' },
        { key: 'total_cmdb_items', value: itemsResult.rows.length },
        { key: 'total_groups', value: groupsResult.rows.length },
        { key: 'total_services', value: servicesResult.rows.length },
        { key: 'total_service_items', value: serviceItemsResult.rows.length },
        { key: 'total_service_groups', value: serviceGroupsResult.rows.length },
        { key: 'total_service_group_connections', value: serviceGroupConnectionsResult.rows.length },
        { key: 'total_connections', value: connectionsResult.rows.length }
      ]
    };
  } catch (err) {
    throw new Error(`Failed to fetch export data: ${err.message}`);
  }
}

/**
 * Generate import template with sample data
 */
async function getImportTemplate() {
  try {
    const XLSX = require('xlsx');
    const wb = XLSX.utils.book_new();

    // Template structure with sample data
    const sampleItems = [
      { id: 1, name: 'Database Server', type: 'database', description: 'Production DB Server', status: 'active', ip: '192.168.1.10', port: 5432, category: 'production', location: 'on-premise', env_type: 'production', group_id: null, order_in_group: 0, position: '{"x":100,"y":200}', alias: 'db-prod-01', storage: null },
    ];

    const sampleGroups = [
      { id: 1, name: 'Production', description: 'Production servers', color: '#10b981', position: '{"x":0,"y":0}', workspace_id: 1 },
    ];

    const sampleServices = [
      { id: 1, cmdb_item_id: 1, name: 'API Service', status: 'active', icon_type: 'preset', icon_path: null, icon_name: 'server', description: 'Backend API Service' },
    ];

    const sampleServiceItems = [
      { id: 1, service_id: 1, name: 'API Server', type: 'server', description: 'Main API Server', status: 'active', ip: '192.168.1.20', category: 'production', location: 'on-premise', group_id: null, order_in_group: 0, position: '{"x":100,"y":100}', domain: 'api.example.com', port: 8080 },
    ];

    const sampleServiceGroups = [
      { id: 1, service_id: 1, name: 'API Components', description: 'API related components', color: '#3b82f6', position: '{"x":0,"y":0}', workspace_id: 1 },
    ];

    const sampleServiceGroupConnections = [
      { id: 1, service_id: 1, source_id: 1, target_id: null, source_group_id: null, target_group_id: 1, target_item_id: null, workspace_id: 1 },
    ];

    const sampleConnections = [
      { id: 1, source_service_item_id: 1, target_service_item_id: 2, connection_type: 'connects_to', direction: 'forward', workspace_id: 1 },
    ];

    const metadata = [
      { key: 'Description', value: 'CMDB Import Template v1.0 - Fill with your data' },
      { key: 'Date', value: new Date().toISOString() },
      { key: '', value: '' },
      { key: 'CMDB Items Columns', value: 'id, name, type, description, status, ip, port, category, location, env_type, position (jsonb), alias, storage (jsonb), group_id, order_in_group' },
      { key: 'Groups Columns', value: 'id, name, description, color, position (jsonb), created_at, workspace_id' },
      { key: 'Services Columns', value: 'id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description' },
      { key: 'Service Items Columns', value: 'id, service_id, name, type, description, status, ip, category, location, position (jsonb), group_id, order_in_group, domain, port' },
      { key: 'Service Groups Columns', value: 'id, service_id, name, description, color, position (jsonb), created_at, workspace_id' },
      { key: 'Service Group Connections Columns', value: 'id, service_id, source_id, target_id, source_group_id, target_group_id, target_item_id, workspace_id, created_at' },
      { key: 'Connections Columns', value: 'id, source_service_item_id, target_service_item_id, connection_type, direction, workspace_id, created_at, updated_at' },
      { key: '', value: '' },
      { key: 'Status Values', value: 'active, inactive, maintenance, disabled' },
      { key: 'Category Values', value: 'production, staging, development, testing' },
      { key: 'Env Type Values', value: 'production, staging, development, testing' },
      { key: 'Location Values', value: 'on-premise, cloud, hybrid' },
      { key: 'Icon Type Values', value: 'preset, upload, emoji' },
      { key: 'Connection Type Values', value: 'connects_to, depends_on, communicates_with, blocks, allows' },
      { key: 'Direction Values', value: 'forward, backward, bidirectional' },
      { key: '', value: '' },
      { key: '⚠️ ID HANDLING', value: 'IDs from Excel WILL BE USED during import' },
      { key: 'TRUE Conflict', value: 'If ID exists BUT name is DIFFERENT → IMPORT BLOCKED (error)' },
      { key: 'UPDATE Scenario', value: 'If ID exists AND name is SAME → UPDATE allowed (uses conflict strategy)' },
      { key: 'Conflict Strategy', value: 'Merge (update if different), Overwrite (replace all), Skip (keep existing)' },
      { key: 'Missing ID', value: 'If ID is empty/null in Excel, database will auto-generate new ID' },
      { key: '', value: '' },
      { key: 'Position Format', value: 'JSON: {"x": 100, "y": 200}' },
      { key: 'Storage Format', value: 'JSON: {"type": "local", "size": "1TB"} or null' },
      { key: 'Service Group Connection', value: 'Use EITHER source_id/target_id OR source_group_id/target_group_id' },
    ];

    XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(sampleItems), 'CMDB Items');
    XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(sampleGroups), 'Groups');
    XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(sampleServices), 'Services');
    XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(sampleServiceItems), 'Service Items');
    XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(sampleServiceGroups), 'Service Groups');
    XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(sampleServiceGroupConnections), 'Service Group Connections');
    XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(sampleConnections), 'Cross-Service Connections');
    XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(metadata), 'Metadata');

    return XLSX.write(wb, { type: 'buffer', bookType: 'xlsx' });
  } catch (err) {
    throw new Error(`Failed to generate template: ${err.message}`);
  }
}

/**
 * Validate import data and generate preview
 */
async function validateImportData(workspaceId, fileData, strategy) {
  try {
    // Get existing data for conflict detection
    const [existingItems, existingGroups, existingServices, existingServiceItems, existingConnections] = await Promise.all([
      pool.query('SELECT id, name, workspace_id FROM cmdb_items WHERE workspace_id = $1', [workspaceId]),
      pool.query('SELECT id, name, workspace_id FROM cmdb_groups WHERE workspace_id = $1', [workspaceId]),
      // Skip services validation for now - requires cmdb_item_id mapping
      Promise.resolve({ rows: [] }),
      pool.query('SELECT id, name, workspace_id FROM service_items WHERE workspace_id = $1', [workspaceId]),
      pool.query('SELECT id, workspace_id FROM cross_service_connections WHERE workspace_id = $1', [workspaceId]),
    ]);

    const conflicts = [];
    const errors = [];

    // Validate CMDB Items - check for TRUE ID conflicts (ID exists but name is DIFFERENT)
    const existingItemIds = new Set(existingItems.rows.map(i => i.id));
    fileData.cmdbItems.forEach((item) => {
      // Skip empty rows check (already done above)
      const keys = Object.keys(item);
      const hasRequiredField = item.name !== undefined && item.name !== null && String(item.name).trim() !== '';
      const isMinimalData = keys.length <= 2 && !hasRequiredField;

      if (keys.length === 0 || isMinimalData) {
        return;
      }

      // Check if ID already exists in database with DIFFERENT name - TRUE CONFLICT
      if (item.id && existingItemIds.has(item.id)) {
        const existing = existingItems.rows.find(i => i.id === item.id);

        // If ID exists but NAME is DIFFERENT → TRUE CONFLICT (BLOCK)
        if (existing && existing.name !== item.name) {
          errors.push({
            type: 'CMDB Item',
            id: item.id,
            name: item.name || 'Unnamed',
            conflict_with: existing.name,
            message: `ID ${item.id} already exists as "${existing.name}"`
          });
        }
        // If ID exists and NAME is SAME → This is UPDATE scenario (allow based on strategy)
      }
    });

    // If there are TRUE ID conflicts, throw error to block import
    if (errors.length > 0) {
      const errorList = errors.map(e => `${e.type} "${e.name}" (ID: ${e.id}): ${e.message}`).join('\n');
      throw new Error(`ID conflicts detected - cannot import:\n${errorList}`);
    }

    // Validate CMDB Items - check for empty names (skip completely empty rows silently)
    fileData.cmdbItems.forEach((item, idx) => {
      // Skip empty rows check (already done above)
      const keys = Object.keys(item);
      const hasRequiredField = item.name !== undefined && item.name !== null && String(item.name).trim() !== '';
      const isMinimalData = keys.length <= 2 && !hasRequiredField;

      if (keys.length === 0 || isMinimalData) {
        return;
      }

      // Only warn if there's substantial data but name is missing
      if (!hasRequiredField && keys.length > 2) {
        console.log(`WARNING: Item #${idx + 1} has data but no name. Keys:`, keys);
        conflicts.push({
          type: 'Warning',
          name: `CMDB Item #${idx + 1}`,
          existing: 'Empty name',
          imported: 'Will be skipped (required field)'
        });
      }
    });

    // Validate CMDB Items
    const itemMap = new Map(existingItems.rows.map(i => [i.name, i]));
    fileData.cmdbItems.forEach(item => {
      if (itemMap.has(item.name)) {
        const existing = itemMap.get(item.name);
        if (existing.status !== item.status) {
          conflicts.push({
            type: 'CMDB Item',
            name: item.name,
            existing: existing.status,
            imported: item.status
          });
        }
      }
    });

    // Validate Groups - check for TRUE ID conflicts (ID exists but name is DIFFERENT)
    const existingGroupIds = new Set(existingGroups.rows.map(g => g.id));
    fileData.groups.forEach((group) => {
      const keys = Object.keys(group);
      const hasRequiredField = group.name !== undefined && group.name !== null && String(group.name).trim() !== '';
      const isMinimalData = keys.length <= 2 && !hasRequiredField;

      if (keys.length === 0 || isMinimalData) {
        return;
      }

      // Check if ID already exists with DIFFERENT name - TRUE CONFLICT
      if (group.id && existingGroupIds.has(group.id)) {
        const existing = existingGroups.rows.find(g => g.id === group.id);

        // If ID exists but NAME is DIFFERENT → TRUE CONFLICT (BLOCK)
        if (existing && existing.name !== group.name) {
          errors.push({
            type: 'Group',
            id: group.id,
            name: group.name || 'Unnamed',
            conflict_with: existing.name,
            message: `ID ${group.id} already exists as "${existing.name}"`
          });
        }
      }
    });

    // Validate Groups - check for empty names (skip completely empty rows silently)
    fileData.groups.forEach((group, idx) => {
      // Check if row has insufficient data (likely empty row with only 1-2 minor fields)
      const keys = Object.keys(group);
      const hasRequiredField = group.name !== undefined && group.name !== null && String(group.name).trim() !== '';
      const isMinimalData = keys.length <= 2 && !hasRequiredField;

      // Skip if truly empty or only has minor fields without name
      if (keys.length === 0 || isMinimalData) {
        // Skip silently - this is just an empty row with stray data
        return;
      }

      // Only warn if there's substantial data but name is missing
      if (!hasRequiredField && keys.length > 3) {
        console.log(`WARNING: Group #${idx + 1} has data but no name. Keys:`, keys);
        conflicts.push({
          type: 'Warning',
          name: `Group #${idx + 1}`,
          existing: 'Empty name',
          imported: 'Will be skipped (required field)'
        });
      }
    });

    // Validate Groups
    const groupMap = new Map(existingGroups.rows.map(g => [g.name, g]));
    fileData.groups.forEach(group => {
      if (groupMap.has(group.name)) {
        conflicts.push({
          type: 'Group',
          name: group.name,
          existing: 'exists',
          imported: 'exists'
        });
      }
    });

    // Validate Service Items - check for TRUE ID conflicts (ID exists but name is DIFFERENT)
    const existingServiceItemIds = new Set(existingServiceItems.rows.map(si => si.id));
    fileData.serviceItems.forEach((serviceItem) => {
      const keys = Object.keys(serviceItem);
      const hasRequiredField = serviceItem.name !== undefined && serviceItem.name !== null && String(serviceItem.name).trim() !== '';
      const isMinimalData = keys.length <= 2 && !hasRequiredField;

      if (keys.length === 0 || isMinimalData) {
        return;
      }

      // Check if ID already exists with DIFFERENT name - TRUE CONFLICT
      if (serviceItem.id && existingServiceItemIds.has(serviceItem.id)) {
        const existing = existingServiceItems.rows.find(si => si.id === serviceItem.id);

        // If ID exists but NAME is DIFFERENT → TRUE CONFLICT (BLOCK)
        if (existing && existing.name !== serviceItem.name) {
          errors.push({
            type: 'Service Item',
            id: serviceItem.id,
            name: serviceItem.name || 'Unnamed',
            conflict_with: existing.name,
            message: `ID ${serviceItem.id} already exists as "${existing.name}"`
          });
        }
      }
    });

    // Validate Service Groups - check for duplicate IDs (if data exists)
    if (fileData.serviceGroups && fileData.serviceGroups.length > 0) {
      fileData.serviceGroups.forEach((serviceGroup) => {
        const keys = Object.keys(serviceGroup);
        const hasRequiredField = serviceGroup.name !== undefined && serviceGroup.name !== null && String(serviceGroup.name).trim() !== '';

        if (!hasRequiredField || keys.length === 0) {
          return;
        }

        // For service groups, we can't easily check existing IDs without service_id mapping
        // Just warn that IDs will be auto-generated
        if (serviceGroup.id) {
          conflicts.push({
            type: 'Info',
            name: `${serviceGroup.name || 'Unnamed'} Service Group (ID: ${serviceGroup.id})`,
            existing: `ID from export`,
            imported: `ID will be ignored - new auto-increment ID will be assigned`
          });
        }
      });
    }

    // Validate Cross-Service Connections (warn that they won't be imported)
    if (fileData.crossServiceConnections.length > 0) {
      conflicts.push({
        type: 'Warning',
        name: `${fileData.crossServiceConnections.length} Cross-Service Connections`,
        existing: 'Not supported',
        imported: 'Will be skipped - requires service items import (complex ID mapping needed)'
      });
    }

    // Generate preview
    const previewId = `preview_${Date.now()}`;

    // Calculate summary counts AND categorize items
    const existingItemNames = new Set(existingItems.rows.map(i => i.name));
    const existingGroupNames = new Set(existingGroups.rows.map(g => g.name));

    let newCount = 0;
    let updateCount = 0;
    let skipCount = 0;

    const itemsNew = [];
    const itemsUpdate = [];
    const itemsSkip = [];
    const groupsNew = [];
    const groupsUpdate = [];
    const groupsSkip = [];

    // Categorize CMDB Items
    fileData.cmdbItems.forEach(item => {
      const keys = Object.keys(item);
      const hasRequiredField = item.name !== undefined && item.name !== null && String(item.name).trim() !== '';
      const isMinimalData = keys.length <= 2 && !hasRequiredField;

      // Skip empty rows
      if (keys.length === 0 || isMinimalData) {
        skipCount++;
        itemsSkip.push({ ...item, reason: 'Empty or minimal data' });
        return;
      }

      // Check if new or update
      if (existingItemNames.has(item.name)) {
        updateCount++;
        itemsUpdate.push(item);
      } else if (hasRequiredField) {
        newCount++;
        itemsNew.push(item);
      } else {
        skipCount++;
        itemsSkip.push({ ...item, reason: 'Missing required field' });
      }
    });

    // Categorize Groups
    fileData.groups.forEach(group => {
      const keys = Object.keys(group);
      const hasRequiredField = group.name !== undefined && group.name !== null && String(group.name).trim() !== '';
      const isMinimalData = keys.length <= 2 && !hasRequiredField;

      if (keys.length === 0 || isMinimalData) {
        skipCount++;
        groupsSkip.push({ ...group, reason: 'Empty or minimal data' });
        return;
      }

      if (existingGroupNames.has(group.name)) {
        updateCount++;
        groupsUpdate.push(group);
      } else if (hasRequiredField) {
        newCount++;
        groupsNew.push(group);
      } else {
        skipCount++;
        groupsSkip.push({ ...group, reason: 'Missing required field' });
      }
    });

    const summary = {
      total: fileData.cmdbItems.length + fileData.groups.length,
      willImport: {
        cmdbItems: fileData.cmdbItems.length,
        groups: fileData.groups.length,
        services: 0,
        serviceItems: 0,
        crossServiceConnections: 0
      },
      new: newCount,
      update: updateCount,
      skip: skipCount
    };

    const itemsDetail = {
      new: itemsNew,
      update: itemsUpdate,
      skip: itemsSkip
    };

    const groupsDetail = {
      new: groupsNew,
      update: groupsUpdate,
      skip: groupsSkip
    };

    // Store preview for later import
    const { storePreview } = require('../utils/importStore');
    storePreview(previewId, { workspaceId, fileData, strategy, conflicts, summary, itemsDetail, groupsDetail });

    return {
      preview_id: previewId,
      conflicts,
      summary
    };
  } catch (err) {
    throw new Error(`Validation failed: ${err.message}`);
  }
}

/**
 * Execute import with resolutions
 */
async function executeImport(workspaceId, userId, previewId, strategy, resolutions) {
  try {
    const { getPreview } = require('../utils/importStore');
    const preview = getPreview(previewId);
    if (!preview) {
      throw new Error('Preview not found or expired');
    }

    const { fileData, strategy: importStrategy } = preview;

    // Validate input data
    if (!fileData || !fileData.cmdbItems || !fileData.groups) {
      throw new Error('Invalid import data: missing required entities');
    }

    const client = await pool.connect();

    try {
      await client.query('BEGIN');

      let imported = 0;
      let updated = 0;
      let skipped = 0;

      // Mapping untuk old_id → new_id (untuk update references)
      const itemIdMapping = new Map(); // old_id → new_id

      const existingItems = await client.query(
        'SELECT id, name, status FROM cmdb_items WHERE workspace_id = $1',
        [workspaceId]
      );
      const itemMap = new Map(existingItems.rows.map(i => [i.name, i]));

      // Import CMDB Items
      for (const item of fileData.cmdbItems) {
        // Check if row has insufficient data (likely empty row with only 1-2 minor fields)
        const keys = Object.keys(item);
        const hasRequiredField = item.name !== undefined && item.name !== null && String(item.name).trim() !== '';
        const isMinimalData = keys.length <= 2 && !hasRequiredField;

        // Skip if truly empty or only has minor fields without name
        if (keys.length === 0 || isMinimalData) {
          skipped++;
          continue;
        }

        // Skip items without name (required field) - only if there's substantial data
        if (!hasRequiredField && keys.length > 2) {
          console.warn('Skipping cmdb_item with empty name');
          skipped++;
          continue;
        }

        const existing = itemMap.get(item.name);

        if (existing) {
          if (importStrategy === 'overwrite') {
            await client.query(
              'UPDATE cmdb_items SET status = $1 WHERE id = $2',
              [item.status, existing.id]
            );
            updated++;
          } else if (importStrategy === 'merge') {
            // Update if different
            if (existing.status !== item.status) {
              await client.query(
                'UPDATE cmdb_items SET status = $1 WHERE id = $2',
                [item.status, existing.id]
              );
              updated++;
            } else {
              skipped++;
            }
          } else {
            // Skip
            skipped++;
          }

          // Mapping untuk existing item: old_id → existing_id
          if (item.id) {
            itemIdMapping.set(item.id, existing.id);
          }
        } else {
          // Insert new dengan ID dari Excel (jika ada)
          let result;
          if (item.id) {
            // Gunakan ID dari Excel
            result = await client.query(
              `INSERT INTO cmdb_items (id, name, type, status, workspace_id)
               VALUES ($1, $2, $3, $4, $5) RETURNING *`,
              [item.id, item.name, item.type, item.status || 'active', workspaceId]
            );
          } else {
            // Jika tidak ada ID di Excel, biarkan auto-increment
            result = await client.query(
              `INSERT INTO cmdb_items (name, type, status, workspace_id)
               VALUES ($1, $2, $3, $4) RETURNING *`,
              [item.name, item.type, item.status || 'active', workspaceId]
            );
          }
          const newItem = result.rows[0];
          imported++;

          // Mapping: old_id (dari Excel) → actual_id (dari database)
          itemIdMapping.set(item.id || newItem.id, newItem.id);
        }
      }

      // Import Groups
      const existingGroups = await client.query(
        'SELECT id, name FROM cmdb_groups WHERE workspace_id = $1',
        [workspaceId]
      );
      const groupMap = new Map(existingGroups.rows.map(g => [g.name, g]));

      for (const group of fileData.groups) {
        // Check if row has insufficient data (likely empty row with only 1-2 minor fields)
        const keys = Object.keys(group);
        const hasRequiredField = group.name !== undefined && group.name !== null && String(group.name).trim() !== '';
        const isMinimalData = keys.length <= 2 && !hasRequiredField;

        // Skip if truly empty or only has minor fields without name
        if (keys.length === 0 || isMinimalData) {
          skipped++;
          continue;
        }

        // Skip groups without name (required field) - only if there's substantial data
        if (!hasRequiredField && keys.length > 2) {
          console.warn('Skipping cmdb_group with empty name');
          skipped++;
          continue;
        }

        const existing = groupMap.get(group.name);
        if (!existing) {
          // Insert dengan ID dari Excel (jika ada)
          if (group.id) {
            await client.query(
              `INSERT INTO cmdb_groups (id, name, description, color, position, workspace_id)
               VALUES ($1, $2, $3, $4, $5, $6)`,
              [group.id, group.name, group.description, group.color, group.position, workspaceId]
            );
          } else {
            await client.query(
              `INSERT INTO cmdb_groups (name, description, color, position, workspace_id)
               VALUES ($1, $2, $3, $4, $5)`,
              [group.name, group.description, group.color, group.position, workspaceId]
            );
          }
          imported++;
        }
      }

      // Import Services
      // NOTE: Services cannot be imported directly because they require cmdb_item_id
      // and services table doesn't have workspace_id column.
      // Services are children of cmdb_items and need to be recreated manually.
      console.warn('Services import skipped - requires cmdb_item_id mapping');

      // Import Service Items
      // NOTE: Service Items cannot be imported directly because they require service_id
      // which needs to be mapped to imported services first.
      console.warn('Service Items import skipped - requires service_id mapping');

      // Import Cross-Service Connections
      // NOTE: Cross-service connections CANNOT be imported because:
      // 1. Service items are not imported (require service_id mapping)
      // 2. Connection references would be broken (old IDs don't exist)
      // Connections need to be recreated manually in the UI after import
      if (fileData.crossServiceConnections.length > 0) {
        console.warn(`Skipping ${fileData.crossServiceConnections.length} cross-service connections - requires service items to be imported first`);
        skipped += fileData.crossServiceConnections.length;
      }

      await client.query('COMMIT');

      return {
        success: true,
        imported,
        updated,
        skipped
      };
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  } catch (err) {
    throw new Error(`Import failed: ${err.message}`);
  }
}

module.exports = {
  getExportData,
  getImportTemplate,
  validateImportData,
  executeImport
};
