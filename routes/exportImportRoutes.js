// cmdbapp-be/routes/exportImportRoutes.js
const express = require('express');
const router = express.Router();
const XLSX = require('xlsx');
const { authenticateToken } = require('../middleware/auth');
const { getExportData, getSimplifiedExportData, getImportTemplate, getBulkImportTemplate, validateImportData, executeImport, validateBulkImportData, executeBulkImport } = require('../controllers/exportImportController');

// Export to Excel
router.get('/cmdb/export/excel', authenticateToken, async (req, res) => {
  try {
    const { workspace_id } = req.query;

    if (!workspace_id) {
      return res.status(400).json({ error: 'workspace_id is required' });
    }

    const data = await getExportData(workspace_id);

    // Helper function to create sheet with columns even if data is empty
    function createSheetWithColumns(dataArray, sampleObject) {
      if (dataArray && dataArray.length > 0) {
        return XLSX.utils.json_to_sheet(dataArray);
      }
      // If empty, create sheet with columns using sample object
      return XLSX.utils.json_to_sheet([sampleObject]);
    }

    // Convert to Excel
    const wb = XLSX.utils.book_new();

    // CMDB Items
    const itemsWs = createSheetWithColumns(data.cmdbItems, {
      id: null, name: null, type: null, description: null, status: null,
      ip: null, port: null, category: null, location: null, env_type: null,
      position: null, group_id: null, order_in_group: null, workspace_id: null,
      storage: null, alias: null
    });
    XLSX.utils.book_append_sheet(wb, itemsWs, 'CMDB Items');

    // Groups
    const groupsWs = createSheetWithColumns(data.groups, {
      id: null, name: null, description: null, color: null,
      position: null, created_at: null, workspace_id: null
    });
    XLSX.utils.book_append_sheet(wb, groupsWs, 'Groups');

    // Services
    const servicesWs = createSheetWithColumns(data.services, {
      id: null, cmdb_item_id: null, name: null, status: null,
      icon_type: null, icon_path: null, icon_name: null, description: null
    });
    XLSX.utils.book_append_sheet(wb, servicesWs, 'Services');

    // Service Items
    const serviceItemsWs = createSheetWithColumns(data.serviceItems, {
      id: null, service_id: null, name: null, type: null, description: null,
      status: null, ip: null, category: null, location: null,
      position: null, group_id: null, order_in_group: null, domain: null, port: null
    });
    XLSX.utils.book_append_sheet(wb, serviceItemsWs, 'Service Items');

    // Service Groups
    const serviceGroupsWs = createSheetWithColumns(data.serviceGroups, {
      id: null, service_id: null, name: null, description: null,
      color: null, position: null, created_at: null, workspace_id: null
    });
    XLSX.utils.book_append_sheet(wb, serviceGroupsWs, 'Service Groups');

    // Service Group Connections
    const serviceGroupConnectionsWs = createSheetWithColumns(data.serviceGroupConnections, {
      id: null, service_id: null, source_id: null, target_id: null,
      source_group_id: null, target_group_id: null, target_item_id: null,
      workspace_id: null, created_at: null
    });
    XLSX.utils.book_append_sheet(wb, serviceGroupConnectionsWs, 'Service Group Connections');

    // Cross-Service Connections
    const connectionsWs = createSheetWithColumns(data.crossServiceConnections, {
      id: null, source_service_item_id: null, target_service_item_id: null,
      connection_type: null, direction: null, workspace_id: null,
      created_at: null, updated_at: null
    });
    XLSX.utils.book_append_sheet(wb, connectionsWs, 'Cross-Service Connections');

    // Metadata
    const metadataWs = XLSX.utils.json_to_sheet(data.metadata);
    XLSX.utils.book_append_sheet(wb, metadataWs, 'Metadata');

    // Generate buffer
    const excelBuffer = XLSX.write(wb, { type: 'buffer', bookType: 'xlsx' });

    // Set headers
    const filename = `cmdb_export_${workspace_id}_${Date.now()}.xlsx`;
    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);

    res.send(excelBuffer);
  } catch (err) {
    console.error('Export Excel error:', err);
    res.status(500).json({ error: err.message });
  }
});

// Export to JSON
router.get('/cmdb/export/json', authenticateToken, async (req, res) => {
  try {
    const { workspace_id } = req.query;

    if (!workspace_id) {
      return res.status(400).json({ error: 'workspace_id is required' });
    }

    const data = await getExportData(workspace_id);

    const filename = `cmdb_export_${workspace_id}_${Date.now()}.json`;
    res.setHeader('Content-Type', 'application/json');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);

    res.json(data);
  } catch (err) {
    console.error('Export JSON error:', err);
    res.status(500).json({ error: err.message });
  }
});

// Export for Bulk Edit (simplified format with name references)
router.get('/cmdb/export/bulk-edit', authenticateToken, async (req, res) => {
  try {
    const { workspace_id } = req.query;

    if (!workspace_id) {
      return res.status(400).json({ error: 'workspace_id is required' });
    }

    console.log('Starting bulk-edit export for workspace:', workspace_id);
    const excelBuffer = await getSimplifiedExportData(workspace_id);
    console.log('Export completed, buffer size:', excelBuffer?.length);

    const filename = `cmdb_bulk_edit_${workspace_id}_${Date.now()}.xlsx`;
    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);

    res.send(excelBuffer);
  } catch (err) {
    console.error('Bulk edit export error:', err);
    res.status(500).json({ error: 'Export failed: ' + err.message });
  }
});

// Download template (OLD FORMAT - for backup/restore with IDs)
router.get('/cmdb/import/template', authenticateToken, async (req, res) => {
  try {
    const template = await getImportTemplate();

    const filename = `cmdb_import_template_${Date.now()}.xlsx`;
    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);

    res.send(template);
  } catch (err) {
    console.error('Template download error:', err);
    res.status(500).json({ error: err.message });
  }
});

// Download bulk import template (NEW FORMAT - simplified with name references)
router.get('/cmdb/import/bulk-template', authenticateToken, async (req, res) => {
  try {
    const template = await getBulkImportTemplate();

    const filename = `cmdb_bulk_import_template_${Date.now()}.xlsx`;
    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);

    res.send(template);
  } catch (err) {
    console.error('Bulk template download error:', err);
    res.status(500).json({ error: err.message });
  }
});

// Import Excel - Parse & Preview
router.post('/cmdb/import/preview', authenticateToken, async (req, res) => {
  try {
    const { workspace_id, file_data, strategy } = req.body;

    if (!workspace_id || !file_data) {
      return res.status(400).json({ error: 'workspace_id and file_data are required' });
    }

    // Validate strategy
    const VALID_STRATEGIES = ['merge', 'overwrite', 'skip'];
    if (strategy && !VALID_STRATEGIES.includes(strategy)) {
      return res.status(400).json({
        error: 'Invalid strategy',
        message: `Strategy must be one of: ${VALID_STRATEGIES.join(', ')}`
      });
    }

    const preview = await validateImportData(workspace_id, file_data, strategy);

    res.json(preview);
  } catch (err) {
    console.error('Import preview error:', err);
    res.status(500).json({ error: err.message });
  }
});

// Get stored preview data
router.get('/cmdb/import/preview', authenticateToken, async (req, res) => {
  try {
    const { preview_id } = req.query;

    if (!preview_id) {
      return res.status(400).json({ error: 'preview_id is required' });
    }

    const { getPreview } = require('../utils/importStore');
    const preview = getPreview(preview_id);

    if (!preview) {
      return res.status(404).json({ error: 'Preview not found or expired' });
    }

    res.json({
      preview_id: preview_id,
      conflicts: preview.conflicts,
      summary: preview.summary,
      itemsDetail: preview.itemsDetail,
      groupsDetail: preview.groupsDetail
    });
  } catch (err) {
    console.error('Get preview error:', err);
    res.status(500).json({ error: err.message });
  }
});

// Import Excel - Confirm
router.post('/cmdb/import/confirm', authenticateToken, async (req, res) => {
  try {
    const { workspace_id, user_id, preview_id, strategy, resolutions } = req.body;

    if (!workspace_id || !preview_id) {
      return res.status(400).json({ error: 'workspace_id and preview_id are required' });
    }

    const result = await executeImport(workspace_id, user_id, preview_id, strategy, resolutions);

    res.json(result);
  } catch (err) {
    console.error('Import confirm error:', err);
    res.status(500).json({ error: err.message });
  }
});

// ============ BULK IMPORT ROUTES (NEW - Simplified Format) ============

// Bulk Import - Validate
router.post('/cmdb/import/bulk/validate', authenticateToken, async (req, res) => {
  try {
    const { workspace_id, file_data } = req.body;

    if (!workspace_id || !file_data) {
      return res.status(400).json({ error: 'workspace_id and file_data are required' });
    }

    const result = await validateBulkImportData(workspace_id, file_data);

    res.json(result);
  } catch (err) {
    console.error('Bulk import validate error:', err);
    res.status(500).json({ error: err.message });
  }
});

// Bulk Import - Execute
router.post('/cmdb/import/bulk/execute', authenticateToken, async (req, res) => {
  try {
    const { workspace_id, user_id, file_data } = req.body;

    if (!workspace_id || !file_data) {
      return res.status(400).json({ error: 'workspace_id and file_data are required' });
    }

    const result = await executeBulkImport(workspace_id, user_id, file_data);

    res.json(result);
  } catch (err) {
    console.error('Bulk import execute error:', err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
