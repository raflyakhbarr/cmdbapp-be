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
 * Get simplified export data (same structure as import - for backup & bulk edit)
 * Uses name references instead of technical IDs
 */
async function getSimplifiedExportData(workspaceId) {
  console.log('getSimplifiedExportData called with workspaceId:', workspaceId);

  // Validate workspaceId
  if (!workspaceId || isNaN(parseInt(workspaceId))) {
    throw new Error('Invalid workspace_id parameter');
  }

  // Require xlsx
  let XLSX;
  try {
    XLSX = require('xlsx');
    console.log('xlsx loaded successfully');
  } catch (err) {
    console.error('Failed to load xlsx:', err);
    throw new Error('xlsx library not available: ' + err.message);
  }

  try {
    console.log('Creating workbook...');
    const wb = XLSX.utils.book_new();
    console.log('Workbook created');

    // Fetch all data with name relationships
    console.log('Fetching data from database...');
    const [itemsResult, groupsResult, servicesResult, serviceItemsResult, serviceGroupsResult] = await Promise.all([
      pool.query(`
        SELECT
          ci.id, ci.name, ci.type, ci.status, ci.ip, ci.port, ci.description,
          ci.category, ci.location, ci.env_type, ci.alias as domain,
          g.name as group_name
        FROM cmdb_items ci
        LEFT JOIN cmdb_groups g ON ci.group_id = g.id
        WHERE ci.workspace_id = $1
        ORDER BY ci.name
      `, [workspaceId]),

      pool.query(`
        SELECT id, name, description, color
        FROM cmdb_groups
        WHERE workspace_id = $1
        ORDER BY name
      `, [workspaceId]),

      pool.query(`
        SELECT
          s.id, s.name, s.status, s.icon_type, s.icon_name, s.description,
          ci.name as cmdb_item_name
        FROM services s
        INNER JOIN cmdb_items ci ON s.cmdb_item_id = ci.id
        WHERE ci.workspace_id = $1
        ORDER BY s.name
      `, [workspaceId]),

      pool.query(`
        SELECT
          si.id, si.name, si.type, si.status, si.description,
          si.ip, si.domain, si.port, si.category, si.location,
          s.name as service_name
        FROM service_items si
        INNER JOIN services s ON si.service_id = s.id
        WHERE si.workspace_id = $1
        ORDER BY si.name
      `, [workspaceId]),

      pool.query(`
        SELECT
          sg.id, sg.name, sg.description, sg.color,
          s.name as service_name
        FROM service_groups sg
        INNER JOIN services s ON sg.service_id = s.id
        INNER JOIN cmdb_items ci ON s.cmdb_item_id = ci.id
        WHERE ci.workspace_id = $1
        ORDER BY sg.name
      `, [workspaceId])
    ]);

    console.log('Data fetched:', {
      items: itemsResult.rows.length,
      groups: groupsResult.rows.length,
      services: servicesResult.rows.length,
      serviceItems: serviceItemsResult.rows.length,
      serviceGroups: serviceGroupsResult.rows.length
    });

    // Transform data to simplified format (remove IDs, use name references)
    // Ensure empty arrays have correct structure for headers
    const cmdbItems = itemsResult.rows.length > 0 ? itemsResult.rows.map(row => ({
      Name: row.name,
      Type: row.type,
      Status: row.status,
      IP: row.ip || '',
      Domain: row.domain || '',
      Port: row.port || '',
      Category: row.category || '',
      Location: row.location || '',
      EnvType: row.env_type || '',
      GroupName: row.group_name || '',
      Description: row.description || ''
    })) : [{ Name: '', Type: '', Status: '', IP: '', Domain: '', Port: '', Category: '', Location: '', EnvType: '', GroupName: '', Description: '' }];

    const groups = groupsResult.rows.length > 0 ? groupsResult.rows.map(row => ({
      Name: row.name,
      Description: row.description || '',
      Color: row.color || ''
    })) : [{ Name: '', Description: '', Color: '' }];

    const services = servicesResult.rows.length > 0 ? servicesResult.rows.map(row => ({
      Name: row.name,
      CMDBItemName: row.cmdb_item_name,
      Status: row.status,
      Description: row.description || '',
      IconType: row.icon_type || '',
      IconName: row.icon_name || ''
    })) : [{ Name: '', CMDBItemName: '', Status: '', Description: '', IconType: '', IconName: '' }];

    const serviceItems = serviceItemsResult.rows.length > 0 ? serviceItemsResult.rows.map(row => ({
      Name: row.name,
      ServiceName: row.service_name,
      Type: row.type,
      Status: row.status,
      Description: row.description || '',
      IP: row.ip || '',
      Domain: row.domain || '',
      Port: row.port || '',
      Category: row.category || '',
      Location: row.location || ''
    })) : [{ Name: '', ServiceName: '', Type: '', Status: '', Description: '', IP: '', Domain: '', Port: '', Category: '', Location: '' }];

    const serviceGroups = serviceGroupsResult.rows.length > 0 ? serviceGroupsResult.rows.map(row => ({
      Name: row.name,
      ServiceName: row.service_name,
      Description: row.description || '',
      Color: row.color || ''
    })) : [{ Name: '', ServiceName: '', Description: '', Color: '' }];

    // Create sheets
    console.log('Creating sheets...');
    XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(cmdbItems), 'CMDB Items');
    console.log('CMDB Items sheet created');
    XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(groups), 'Groups');
    console.log('Groups sheet created');
    XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(services), 'Services');
    console.log('Services sheet created');
    XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(serviceItems), 'Service Items');
    console.log('Service Items sheet created');
    XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(serviceGroups), 'Service Groups');
    console.log('Service Groups sheet created');

    // Add metadata sheet
    const metadata = [
      { key: 'Export Type', value: 'Bulk Edit (Simplified Format)' },
      { key: 'Date', value: new Date().toISOString() },
      { key: 'workspace_id', value: workspaceId },
      { key: '', value: '' },
      { key: 'CMDB Items', value: cmdbItems.length },
      { key: 'Groups', value: groups.length },
      { key: 'Services', value: services.length },
      { key: 'Service Items', value: serviceItems.length },
      { key: 'Service Groups', value: serviceGroups.length },
      { key: '', value: '' },
      { key: 'NOTE', value: 'This export uses NAME references, not technical IDs' },
      { key: 'Purpose', value: 'For bulk editing in Excel and re-importing' },
    ];
    XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(metadata), 'Metadata');
    console.log('Metadata sheet created');

    console.log('Writing to buffer...');
    const buffer = XLSX.write(wb, { type: 'buffer', bookType: 'xlsx' });
    console.log('Buffer created, size:', buffer?.length);
    return buffer;
  } catch (err) {
    console.error('getSimplifiedExportData error:', err);
    throw new Error(`Failed to generate simplified export: ${err.message}`);
  }
}

/**
 * Allowed values for dropdowns
 */
const ALLOWED_VALUES = {
  type: ['Server', 'Database', 'Switch', 'Workstation', 'Hub', 'Firewall', 'Router', 'Web Application', 'Domain', 'Desktop Application', 'Mobile Application', 'API Service', 'Microservice', 'Container/Docker', 'Load Balancer', 'Proxy Server', 'Application Server', 'File Server', 'Print Server', 'Domain Controller'],
  status: ['active', 'inactive', 'maintenance', 'disabled'],
  category: ['internal', 'external'],
  envType: ['fisik', 'virtual', 'cloud'],
  iconType: ['preset', 'upload', 'emoji'],
  iconName: ['citrix', 'oracle', 'apache', 'nginx', 'mongodb', 'redis', 'postgresql', 'mysql', 'mssql', 'cloud', 'internet', 'security', 'firewall', 'vpn', 'cpu', 'storage', 'network']
};

/**
 * Generate import template with sample data (OLD FORMAT - for backup)
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

/**
 * Normalize object keys to handle different cases (e.g., Name, name, NAME)
 */
function normalizeKeys(obj) {
  const normalized = {};
  const keyMap = {
    'name': 'Name',
    'type': 'Type',
    'status': 'Status',
    'ip': 'IP',
    'domain': 'Domain',
    'port': 'Port',
    'category': 'Category',
    'location': 'Location',
    'envtype': 'EnvType',
    'env_type': 'EnvType',
    'groupname': 'GroupName',
    'group_name': 'GroupName',
    'description': 'Description',
    'cmdbitemname': 'CMDBItemName',
    'cmdb_item_name': 'CMDBItemName',
    'icontype': 'IconType',
    'icon_type': 'IconType',
    'iconname': 'IconName',
    'icon_name': 'IconName',
    'servicegroupname': 'ServiceGroupName',
    'service_group_name': 'ServiceGroupName',
    'servicename': 'ServiceName',
    'service_name': 'ServiceName',
  };

  for (const [key, value] of Object.entries(obj)) {
    const lowerKey = key.toLowerCase();
    let mappedKey = keyMap[lowerKey] || key;
    normalized[mappedKey] = value;
  }
  return normalized;
}

/**
 * Validate bulk import data (simplified format with name references)
 */
async function validateBulkImportData(workspaceId, fileData) {
  try {
    const errors = [];
    const warnings = [];

    // Normalize all data keys first (handle case variations)
    if (fileData.cmdbItems) {
      fileData.cmdbItems = fileData.cmdbItems.map(normalizeKeys);
    }
    if (fileData.groups) {
      fileData.groups = fileData.groups.map(normalizeKeys);
    }
    if (fileData.services) {
      fileData.services = fileData.services.map(normalizeKeys);
    }
    if (fileData.serviceItems) {
      fileData.serviceItems = fileData.serviceItems.map(normalizeKeys);
    }
    if (fileData.serviceGroups) {
      fileData.serviceGroups = fileData.serviceGroups.map(normalizeKeys);
    }

    // Validate CMDB Items
    if (fileData.cmdbItems && fileData.cmdbItems.length > 0) {
      const itemNames = new Set();
      fileData.cmdbItems.forEach((item, idx) => {
        const row = idx + 2; // Excel row number (1-indexed + header)

        // Skip completely empty rows
        const keys = Object.keys(item);
        if (keys.length === 0) return;
        const hasAnyData = keys.some(k => item[k] !== undefined && item[k] !== null && String(item[k]).trim() !== '');
        if (!hasAnyData) return;

        // Check required fields
        if (!item.Name || String(item.Name).trim() === '') {
          errors.push({ sheet: 'CMDB Items', row, field: 'Name', message: 'Name is required' });
          return;
        }

        // Check for duplicate names
        if (itemNames.has(item.Name)) {
          errors.push({ sheet: 'CMDB Items', row, field: 'Name', message: `Name "${item.Name}" is duplicated` });
        }
        itemNames.add(item.Name);

        // Validate Type
        if (!item.Type) {
          errors.push({ sheet: 'CMDB Items', row, field: 'Type', message: 'Type is required' });
        } else if (!ALLOWED_VALUES.type.includes(item.Type)) {
          errors.push({
            sheet: 'CMDB Items',
            row,
            field: 'Type',
            message: `Invalid Type "${item.Type}". Options: ${ALLOWED_VALUES.type.slice(0, 5).join(', ')}...`
          });
        }

        // Validate Status
        if (!item.Status) {
          errors.push({ sheet: 'CMDB Items', row, field: 'Status', message: 'Status is required' });
        } else if (!ALLOWED_VALUES.status.includes(item.Status)) {
          errors.push({
            sheet: 'CMDB Items',
            row,
            field: 'Status',
            message: `Invalid Status "${item.Status}". Options: ${ALLOWED_VALUES.status.join(', ')}`
          });
        }

        // Validate Port if provided
        if (item.Port && item.Port !== '') {
          const port = parseInt(item.Port);
          if (isNaN(port) || port < 1 || port > 65535) {
            errors.push({ sheet: 'CMDB Items', row, field: 'Port', message: 'Port must be between 1 and 65535' });
          }
        }

        // Validate Category if provided
        if (item.Category && !ALLOWED_VALUES.category.includes(item.Category)) {
          errors.push({
            sheet: 'CMDB Items',
            row,
            field: 'Category',
            message: `Invalid Category "${item.Category}". Options: ${ALLOWED_VALUES.category.join(', ')}`
          });
        }

        // Validate EnvType if provided
        if (item.EnvType && !ALLOWED_VALUES.envType.includes(item.EnvType)) {
          errors.push({
            sheet: 'CMDB Items',
            row,
            field: 'EnvType',
            message: `Invalid EnvType "${item.EnvType}". Options: ${ALLOWED_VALUES.envType.join(', ')}`
          });
        }

        // Validate Color format (for GroupName reference, validated later)
      });

      // Check for existing names in database
      const existingItems = await pool.query('SELECT name FROM cmdb_items WHERE workspace_id = $1', [workspaceId]);
      const existingItemNames = new Set(existingItems.rows.map(i => i.name));

      fileData.cmdbItems.forEach((item, idx) => {
        const row = idx + 2;
        if (item.Name && existingItemNames.has(item.Name)) {
          warnings.push({
            sheet: 'CMDB Items',
            row,
            field: 'Name',
            message: `Name "${item.Name}" already exists in workspace`
          });
        }
      });
    }

    // Validate Groups
    if (fileData.groups && fileData.groups.length > 0) {
      const groupNames = new Set();
      fileData.groups.forEach((group, idx) => {
        const row = idx + 2;

        if (!group.Name || String(group.Name).trim() === '') {
          errors.push({ sheet: 'Groups', row, field: 'Name', message: 'Name is required' });
          return;
        }

        if (groupNames.has(group.Name)) {
          errors.push({ sheet: 'Groups', row, field: 'Name', message: `Name "${group.Name}" is duplicated` });
        }
        groupNames.add(group.Name);

        // Validate Color format
        if (group.Color && group.Color !== '') {
          const hexColorRegex = /^#[0-9A-Fa-f]{6}$/;
          if (!hexColorRegex.test(group.Color)) {
            errors.push({ sheet: 'Groups', row, field: 'Color', message: 'Color must be hex format (e.g., #10b981)' });
          }
        }
      });

      // Check for existing names
      const existingGroups = await pool.query('SELECT name FROM cmdb_groups WHERE workspace_id = $1', [workspaceId]);
      const existingGroupNames = new Set(existingGroups.rows.map(g => g.name));

      fileData.groups.forEach((group, idx) => {
        const row = idx + 2;
        if (group.Name && existingGroupNames.has(group.Name)) {
          warnings.push({
            sheet: 'Groups',
            row,
            field: 'Name',
            message: `Name "${group.Name}" already exists in workspace`
          });
        }
      });
    }

    // Validate Services (must have CMDB Item Name reference)
    if (fileData.services && fileData.services.length > 0) {
      const serviceNames = new Set();
      const cmdbItemNames = new Set(fileData.cmdbItems?.map(i => i.Name) || []);

      fileData.services.forEach((service, idx) => {
        const row = idx + 2;

        if (!service.Name || String(service.Name).trim() === '') {
          errors.push({ sheet: 'Services', row, field: 'Name', message: 'Name is required' });
          return;
        }

        if (serviceNames.has(service.Name)) {
          errors.push({ sheet: 'Services', row, field: 'Name', message: `Name "${service.Name}" is duplicated` });
        }
        serviceNames.add(service.Name);

        if (!service.CMDBItemName || String(service.CMDBItemName).trim() === '') {
          errors.push({ sheet: 'Services', row, field: 'CMDBItemName', message: 'CMDB Item Name is required' });
        } else if (!cmdbItemNames.has(service.CMDBItemName)) {
          errors.push({
            sheet: 'Services',
            row,
            field: 'CMDBItemName',
            message: `CMDB Item "${service.CMDBItemName}" not found in CMDB Items sheet`
          });
        }

        if (!service.Status) {
          errors.push({ sheet: 'Services', row, field: 'Status', message: 'Status is required' });
        } else if (!ALLOWED_VALUES.status.includes(service.Status)) {
          errors.push({
            sheet: 'Services',
            row,
            field: 'Status',
            message: `Invalid Status "${service.Status}". Options: ${ALLOWED_VALUES.status.join(', ')}`
          });
        }

        if (service.IconType && !ALLOWED_VALUES.iconType.includes(service.IconType)) {
          errors.push({
            sheet: 'Services',
            row,
            field: 'IconType',
            message: `Invalid IconType "${service.IconType}". Options: ${ALLOWED_VALUES.iconType.join(', ')}`
          });
        }

        // IconName validation - only warn if invalid, don't block import
        if (service.IconName && !ALLOWED_VALUES.iconName.includes(service.IconName)) {
          warnings.push({
            sheet: 'Services',
            row,
            field: 'IconName',
            message: `IconName "${service.IconName}" not in standard list, will use default icon`
          });
        }
      });
    }

    // Validate Service Items (must have Service Name reference)
    if (fileData.serviceItems && fileData.serviceItems.length > 0) {
      const serviceItemNames = new Set();
      const serviceNames = new Set(fileData.services?.map(s => s.Name) || []);

      fileData.serviceItems.forEach((item, idx) => {
        const row = idx + 2;

        if (!item.Name || String(item.Name).trim() === '') {
          errors.push({ sheet: 'Service Items', row, field: 'Name', message: 'Name is required' });
          return;
        }

        if (serviceItemNames.has(item.Name)) {
          errors.push({ sheet: 'Service Items', row, field: 'Name', message: `Name "${item.Name}" is duplicated` });
        }
        serviceItemNames.add(item.Name);

        if (!item.ServiceName || String(item.ServiceName).trim() === '') {
          errors.push({ sheet: 'Service Items', row, field: 'ServiceName', message: 'Service Name is required' });
        } else if (!serviceNames.has(item.ServiceName)) {
          errors.push({
            sheet: 'Service Items',
            row,
            field: 'ServiceName',
            message: `Service "${item.ServiceName}" not found in Services sheet`
          });
        }

        if (!item.Type) {
          errors.push({ sheet: 'Service Items', row, field: 'Type', message: 'Type is required' });
        } else if (!ALLOWED_VALUES.type.includes(item.Type)) {
          errors.push({
            sheet: 'Service Items',
            row,
            field: 'Type',
            message: `Invalid Type "${item.Type}". Options: ${ALLOWED_VALUES.type.slice(0, 5).join(', ')}...`
          });
        }

        if (!item.Status) {
          errors.push({ sheet: 'Service Items', row, field: 'Status', message: 'Status is required' });
        } else if (!ALLOWED_VALUES.status.includes(item.Status)) {
          errors.push({
            sheet: 'Service Items',
            row,
            field: 'Status',
            message: `Invalid Status "${item.Status}". Options: ${ALLOWED_VALUES.status.join(', ')}`
          });
        }

        if (item.Port && item.Port !== '') {
          const port = parseInt(item.Port);
          if (isNaN(port) || port < 1 || port > 65535) {
            errors.push({ sheet: 'Service Items', row, field: 'Port', message: 'Port must be between 1 and 65535' });
          }
        }

        if (item.Category && !ALLOWED_VALUES.category.includes(item.Category)) {
          errors.push({
            sheet: 'Service Items',
            row,
            field: 'Category',
            message: `Invalid Category "${item.Category}". Options: ${ALLOWED_VALUES.category.join(', ')}`
          });
        }
      });
    }

    // Validate Service Groups (must have Service Name reference)
    if (fileData.serviceGroups && fileData.serviceGroups.length > 0) {
      const serviceGroupNames = new Set();
      const serviceNames = new Set(fileData.services?.map(s => s.Name) || []);

      fileData.serviceGroups.forEach((sg, idx) => {
        const row = idx + 2;

        if (!sg.Name || String(sg.Name).trim() === '') {
          errors.push({ sheet: 'Service Groups', row, field: 'Name', message: 'Name is required' });
          return;
        }

        if (serviceGroupNames.has(sg.Name)) {
          errors.push({ sheet: 'Service Groups', row, field: 'Name', message: `Name "${sg.Name}" is duplicated` });
        }
        serviceGroupNames.add(sg.Name);

        if (!sg.ServiceName || String(sg.ServiceName).trim() === '') {
          errors.push({ sheet: 'Service Groups', row, field: 'ServiceName', message: 'Service Name is required' });
        } else if (!serviceNames.has(sg.ServiceName)) {
          errors.push({
            sheet: 'Service Groups',
            row,
            field: 'ServiceName',
            message: `Service "${sg.ServiceName}" not found in Services sheet`
          });
        }

        if (sg.Color && sg.Color !== '') {
          const hexColorRegex = /^#[0-9A-Fa-f]{6}$/;
          if (!hexColorRegex.test(sg.Color)) {
            errors.push({ sheet: 'Service Groups', row, field: 'Color', message: 'Color must be hex format (e.g., #10b981)' });
          }
        }
      });
    }

    // Validate GroupName references in CMDB Items
    if (fileData.cmdbItems && fileData.groups) {
      const groupNames = new Set(fileData.groups.map(g => g.Name));
      fileData.cmdbItems.forEach((item, idx) => {
        const row = idx + 2;
        if (item.GroupName && item.GroupName !== '' && !groupNames.has(item.GroupName)) {
          errors.push({
            sheet: 'CMDB Items',
            row,
            field: 'GroupName',
            message: `Group "${item.GroupName}" not found in Groups sheet`
          });
        }
      });
    }

    // Validate ServiceGroupName references in Services (NOT for Service Items - column doesn't exist)
    if (fileData.serviceGroups) {
      const serviceGroupNames = new Set(fileData.serviceGroups.map(sg => sg.Name));

      if (fileData.services) {
        fileData.services.forEach((service, idx) => {
          const row = idx + 2;
          if (service.ServiceGroupName && service.ServiceGroupName !== '' && !serviceGroupNames.has(service.ServiceGroupName)) {
            errors.push({
              sheet: 'Services',
              row,
              field: 'ServiceGroupName',
              message: `Service Group "${service.ServiceGroupName}" not found in Service Groups sheet`
            });
          }
        });
      }
    }

    // Generate summary
    const summary = {
      cmdbItems: (fileData.cmdbItems || []).length,
      groups: (fileData.groups || []).length,
      services: (fileData.services || []).length,
      serviceItems: (fileData.serviceItems || []).length,
      serviceGroups: (fileData.serviceGroups || []).length,
      total: (fileData.cmdbItems || []).length + (fileData.groups || []).length +
             (fileData.services || []).length + (fileData.serviceItems || []).length +
             (fileData.serviceGroups || []).length
    };

    return {
      valid: errors.length === 0,
      errors,
      warnings,
      summary
    };
  } catch (err) {
    throw new Error(`Validation failed: ${err.message}`);
  }
}

/**
 * Execute bulk import with name-based references
 */
async function executeBulkImport(workspaceId, userId, fileData) {
  try {
    const client = await pool.connect();

    try {
      await client.query('BEGIN');

      let imported = 0;
      const nameToIdMaps = {
        groups: new Map(),
        cmdbItems: new Map(),
        services: new Map(),
        serviceGroups: new Map()
      };

      // Normalize all data keys first (handle case variations)
      if (fileData.cmdbItems) {
        fileData.cmdbItems = fileData.cmdbItems.map(normalizeKeys);
      }
      if (fileData.groups) {
        fileData.groups = fileData.groups.map(normalizeKeys);
      }
      if (fileData.services) {
        fileData.services = fileData.services.map(normalizeKeys);
      }
      if (fileData.serviceItems) {
        fileData.serviceItems = fileData.serviceItems.map(normalizeKeys);
      }
      if (fileData.serviceGroups) {
        fileData.serviceGroups = fileData.serviceGroups.map(normalizeKeys);
      }

      // Step 1: Import Groups (first, no dependencies)
      if (fileData.groups && fileData.groups.length > 0) {
        for (const group of fileData.groups) {
          if (!group.Name || String(group.Name).trim() === '') continue;

          // Check if already exists
          const existing = await client.query(
            'SELECT id FROM cmdb_groups WHERE workspace_id = $1 AND name = $2',
            [workspaceId, group.Name]
          );

          if (existing.rows.length > 0) {
            // Use existing ID
            nameToIdMaps.groups.set(group.Name, existing.rows[0].id);
          } else {
            // Insert new
            const result = await client.query(
              `INSERT INTO cmdb_groups (name, description, color, position, workspace_id)
               VALUES ($1, $2, $3, $4, $5) RETURNING id`,
              [
                group.Name,
                group.Description || null,
                group.Color || null,
                JSON.stringify({ x: Math.random() * 500, y: Math.random() * 500 }),
                workspaceId
              ]
            );
            nameToIdMaps.groups.set(group.Name, result.rows[0].id);
            imported++;
          }
        }
      }

      // Step 2: Import CMDB Items (depends on Groups)
      if (fileData.cmdbItems && fileData.cmdbItems.length > 0) {
        for (const item of fileData.cmdbItems) {
          if (!item.Name || String(item.Name).trim() === '') continue;

          // Check if already exists
          const existing = await client.query(
            'SELECT id FROM cmdb_items WHERE workspace_id = $1 AND name = $2',
            [workspaceId, item.Name]
          );

          if (existing.rows.length > 0) {
            nameToIdMaps.cmdbItems.set(item.Name, existing.rows[0].id);
          } else {
            // Get group_id if GroupName is specified
            let groupId = null;
            if (item.GroupName && nameToIdMaps.groups.has(item.GroupName)) {
              groupId = nameToIdMaps.groups.get(item.GroupName);
            }

            const result = await client.query(
              `INSERT INTO cmdb_items (name, type, status, ip, port, description, category, location, env_type, group_id, position, workspace_id)
               VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) RETURNING id`,
              [
                item.Name,
                item.Type,
                item.Status || 'active',
                item.IP || null,
                item.Port ? parseInt(item.Port) : null,
                item.Description || null,
                item.Category || null,
                item.Location || null,
                item.EnvType || null,
                groupId,
                JSON.stringify({ x: Math.random() * 500, y: Math.random() * 500 }),
                workspaceId
              ]
            );
            nameToIdMaps.cmdbItems.set(item.Name, result.rows[0].id);
            imported++;
          }
        }
      }

      // Step 3: Import Services (depends on CMDB Items)
      if (fileData.services && fileData.services.length > 0) {
        for (const service of fileData.services) {
          if (!service.Name || String(service.Name).trim() === '') continue;

          // Get cmdb_item_id from name
          const cmdbItemId = nameToIdMaps.cmdbItems.get(service.CMDBItemName);
          if (!cmdbItemId) {
            throw new Error(`CMDB Item "${service.CMDBItemName}" not found for Service "${service.Name}"`);
          }

          // Check if already exists (by querying through cmdb_items)
          const existing = await client.query(
            `SELECT s.id FROM services s
             INNER JOIN cmdb_items ci ON s.cmdb_item_id = ci.id
             WHERE ci.workspace_id = $1 AND s.name = $2`,
            [workspaceId, service.Name]
          );

          if (existing.rows.length > 0) {
            nameToIdMaps.services.set(service.Name, existing.rows[0].id);
          } else {
            const result = await client.query(
              `INSERT INTO services (cmdb_item_id, workspace_id, name, status, icon_type, icon_name, description)
               VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id`,
              [
                cmdbItemId,
                workspaceId,
                service.Name,
                service.Status || 'active',
                service.IconType || 'preset',
                service.IconName || null,
                service.Description || null
              ]
            );
            nameToIdMaps.services.set(service.Name, result.rows[0].id);
            imported++;
          }
        }
      }

      // Step 4: Import Service Groups (depends on Services)
      if (fileData.serviceGroups && fileData.serviceGroups.length > 0) {
        for (const sg of fileData.serviceGroups) {
          if (!sg.Name || String(sg.Name).trim() === '') continue;

          // Get service_id from name
          const serviceId = nameToIdMaps.services.get(sg.ServiceName);
          if (!serviceId) {
            throw new Error(`Service "${sg.ServiceName}" not found for Service Group "${sg.Name}"`);
          }

          // Check if already exists
          const existing = await client.query(
            'SELECT id FROM service_groups WHERE workspace_id = $1 AND name = $2',
            [workspaceId, sg.Name]
          );

          if (existing.rows.length > 0) {
            nameToIdMaps.serviceGroups.set(sg.Name, existing.rows[0].id);
          } else {
            const result = await client.query(
              `INSERT INTO service_groups (service_id, name, description, color, position, workspace_id)
               VALUES ($1, $2, $3, $4, $5, $6) RETURNING id`,
              [
                serviceId,
                sg.Name,
                sg.Description || null,
                sg.Color || null,
                JSON.stringify({ x: Math.random() * 500, y: Math.random() * 500 }),
                workspaceId
              ]
            );
            nameToIdMaps.serviceGroups.set(sg.Name, result.rows[0].id);
            imported++;
          }
        }
      }

      // Step 5: Import Service Items (depends on Services)
      if (fileData.serviceItems && fileData.serviceItems.length > 0) {
        for (const si of fileData.serviceItems) {
          if (!si.Name || String(si.Name).trim() === '') continue;

          // Get service_id from name
          const serviceId = nameToIdMaps.services.get(si.ServiceName);
          if (!serviceId) {
            throw new Error(`Service "${si.ServiceName}" not found for Service Item "${si.Name}"`);
          }

          // Check if already exists
          const existing = await client.query(
            'SELECT id FROM service_items WHERE workspace_id = $1 AND name = $2',
            [workspaceId, si.Name]
          );

          if (existing.rows.length === 0) {
            await client.query(
              `INSERT INTO service_items (service_id, name, type, status, description, ip, domain, port, category, location, position, workspace_id)
               VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`,
              [
                serviceId,
                si.Name,
                si.Type,
                si.Status || 'active',
                si.Description || null,
                si.IP || null,
                si.Domain || null,
                si.Port ? parseInt(si.Port) : null,
                si.Category || null,
                si.Location || null,
                JSON.stringify({ x: Math.random() * 500, y: Math.random() * 500 }),
                workspaceId
              ]
            );
            imported++;
          }
        }
      }

      await client.query('COMMIT');

      return {
        success: true,
        imported,
        message: `Successfully imported ${imported} nodes`
      };
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  } catch (err) {
    throw new Error(`Bulk import failed: ${err.message}`);
  }
}

/**
 * Generate simplified bulk import template (NEW FORMAT - for bulk nodes)
 * Uses name references instead of technical IDs
 */
async function getBulkImportTemplate() {
  try {
    const XLSX = require('xlsx');
    const wb = XLSX.utils.book_new();

    // Sheet 1: CMDB Items (simplified, no IDs)
    const sampleItems = [
      {
        Name: 'Database Server',
        Type: 'Database',
        Status: 'active',
        IP: '192.168.1.10',
        Domain: '',
        Port: '',
        Category: 'internal',
        Location: 'Data Center 1',
        EnvType: 'fisik',
        GroupName: '',
        Description: 'Production database server'
      },
      {
        Name: 'Web Server',
        Type: 'Server',
        Status: 'active',
        IP: '192.168.1.20',
        Domain: 'example.com',
        Port: '443',
        Category: 'external',
        Location: 'Data Center 1',
        EnvType: 'virtual',
        GroupName: '',
        Description: 'Frontend web server'
      }
    ];

    // Sheet 2: Groups
    const sampleGroups = [
      {
        Name: 'Production',
        Description: 'Production servers',
        Color: '#10b981'
      },
      {
        Name: 'Development',
        Description: 'Development environment',
        Color: '#3b82f6'
      }
    ];

    // Sheet 3: Services (with CMDB Item Name reference)
    const sampleServices = [
      {
        Name: 'API Service',
        CMDBItemName: 'Web Server',
        Status: 'active',
        Description: 'Backend API service',
        IconType: 'preset',
        IconName: 'cloud',
        ServiceGroupName: ''
      }
    ];

    // Sheet 4: Service Items (with Service Name reference)
    const sampleServiceItems = [
      {
        Name: 'API Pod 1',
        ServiceName: 'API Service',
        Type: 'Server',
        Status: 'active',
        Description: 'API server pod 1',
        IP: '192.168.1.21',
        Domain: '',
        Port: '8080',
        Category: 'internal',
        Location: 'Data Center 1'
      }
    ];

    // Sheet 5: Service Groups
    const sampleServiceGroups = [
      {
        Name: 'API Components',
        ServiceName: 'API Service',
        Description: 'API related components',
        Color: '#3b82f6'
      }
    ];

    // Create sheets
    XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(sampleItems), 'CMDB Items');
    XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(sampleGroups), 'Groups');
    XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(sampleServices), 'Services');
    XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(sampleServiceItems), 'Service Items');
    XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(sampleServiceGroups), 'Service Groups');

    // Add validation info sheet
    const validationInfo = [
      { key: 'Template Type', value: 'CMDB Bulk Import - Simplified Format' },
      { key: 'Version', value: '2.0' },
      { key: 'Date', value: new Date().toISOString() },
      { key: '', value: '' },
      { key: 'IMPORTANT', value: 'This template uses NAME references, not IDs' },
      { key: 'workspace_id', value: 'Automatically filled from current user' },
      { key: 'Positions', value: 'Auto-generated for new nodes' },
      { key: '', value: '' },
      { key: 'CMDB Items - Required Fields', value: 'Name, Type, Status' },
      { key: 'CMDB Items - Type Options', value: ALLOWED_VALUES.type.join(', ') },
      { key: 'CMDB Items - Status Options', value: ALLOWED_VALUES.status.join(', ') },
      { key: 'CMDB Items - EnvType Options', value: ALLOWED_VALUES.envType.join(', ') },
      { key: '', value: '' },
      { key: 'Groups - Required Fields', value: 'Name' },
      { key: 'Groups - Color Format', value: 'Hex color code (e.g., #10b981)' },
      { key: '', value: '' },
      { key: 'Services - Required Fields', value: 'Name, CMDB Item Name, Status' },
      { key: 'Services - CMDB Item Name', value: 'Must match a Name from CMDB Items sheet' },
      { key: 'Services - IconType Options', value: ALLOWED_VALUES.iconType.join(', ') },
      { key: 'Services - IconName Options', value: ALLOWED_VALUES.iconName.join(', ') },
      { key: '', value: '' },
      { key: 'Service Items - Required Fields', value: 'Name, Service Name, Type, Status' },
      { key: 'Service Items - Service Name', value: 'Must match a Name from Services sheet' },
      { key: '', value: '' },
      { key: 'Service Groups - Required Fields', value: 'Name, Service Name' },
      { key: 'Service Groups - Service Name', value: 'Must match a Name from Services sheet' },
      { key: '', value: '' },
      { key: 'Import Order', value: 'Groups → CMDB Items → Services → Service Groups → Service Items' },
      { key: 'Parent References', value: 'Services reference CMDB Items by Name' },
      { key: '', value: 'Service Items reference Services by Name' },
      { key: '', value: 'Service Groups reference Services by Name' },
    ];
    XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(validationInfo), 'Validation Info');

    return XLSX.write(wb, { type: 'buffer', bookType: 'xlsx' });
  } catch (err) {
    throw new Error(`Failed to generate bulk import template: ${err.message}`);
  }
}

module.exports = {
  getExportData,
  getSimplifiedExportData,
  getImportTemplate,
  getBulkImportTemplate,
  validateImportData,
  executeImport,
  validateBulkImportData,
  executeBulkImport
};
