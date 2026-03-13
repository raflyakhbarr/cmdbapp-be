const { Server } = require('socket.io');
let io = null;

const initializeSocket = (server) => {
  io = new Server(server, {
    cors: { origin: "http://localhost:5173" }
  });
  io.on('connection', (socket) => {
    console.log('✅ Client connected');
    socket.on('disconnect', () => {
      console.log('🔌 Client disconnected');
    });
  });
};

const emitCmdbUpdate = async () => {
  if (!io) {
    console.warn('⚠️ Socket.IO belum diinisialisasi. Lewati emit.');
    return;
  }
  try {
    // Ambil semua data CMDB item langsung dari database
    const pool = require('./db');
    const query = `
      SELECT
        ci.id, name, type, description, status, ip, category, location,
        env_type, group_id, order_in_group, position, workspace_id,
        COALESCE(ci.storage, NULL) as storage
      FROM cmdb_items ci
      ORDER BY ci.id DESC
    `;
    const result = await pool.query(query);
    io.emit('cmdb_update', result.rows);
  } catch (err) {
    console.error('Failed to emit CMDB update:', err);
  }
};

const emitServiceUpdate = async (serviceIdOrItemId, workspaceId) => {
  if (!io) {
    console.warn('⚠️ Socket.IO belum diinisialisasi. Lewati emit.');
    return;
  }
  try {
    // Check if the ID is a service item ID or service ID
    // by querying the service_items table first
    const pool = require('./db');
    const itemResult = await pool.query(
      'SELECT service_id FROM service_items WHERE id = $1',
      [serviceIdOrItemId]
    );

    let actualServiceId;
    if (itemResult.rows.length > 0) {
      // It's a service item ID, get the service_id
      actualServiceId = itemResult.rows[0].service_id;
    } else {
      // It might already be a service ID, verify it exists
      const serviceResult = await pool.query(
        'SELECT id FROM services WHERE id = $1',
        [serviceIdOrItemId]
      );
      if (serviceResult.rows.length > 0) {
        actualServiceId = serviceIdOrItemId;
      } else {
        console.warn('⚠️ Could not find service or service item for socket emit');
        return;
      }
    }

    // Emit event untuk service update dengan serviceId dan workspaceId
    io.emit('service_update', { serviceId: actualServiceId, workspaceId });
    console.log(`✅ Service update emitted: service=${actualServiceId}, workspace=${workspaceId}`);
  } catch (err) {
    console.error('Failed to emit service update:', err);
  }
};

// Emit event untuk service item status updates
const emitServiceItemStatusUpdate = async (serviceItemId, newStatus, workspaceId) => {
  if (!io) {
    console.warn('⚠️ Socket.IO belum diinisialisasi. Lewati emit.');
    return;
  }
  try {
    io.emit('service_item_status_update', {
      serviceItemId,
      newStatus,
      workspaceId
    });
  } catch (err) {
    console.error('Failed to emit service item status update:', err);
  }
};

// Emit event untuk cross-service connection updates
const emitCrossServiceConnectionUpdate = async (sourceServiceItemId, targetServiceItemId, workspaceId) => {
  if (!io) {
    console.warn('⚠️ Socket.IO belum diinisialisasi. Lewati emit.');
    return;
  }
  try {
    // Get service IDs for both service items with explicit ordering
    const pool = require('./db');
    const serviceQuery = `
      SELECT id, service_id
      FROM service_items
      WHERE id = $1 OR id = $2
    `;
    const result = await pool.query(serviceQuery, [sourceServiceItemId, targetServiceItemId]);

    if (result.rows.length === 2) {
      // Find the correct service IDs by matching the IDs
      const sourceRow = result.rows.find(row => row.id === parseInt(sourceServiceItemId));
      const targetRow = result.rows.find(row => row.id === parseInt(targetServiceItemId));

      if (sourceRow && targetRow) {
        const sourceServiceId = sourceRow.service_id;
        const targetServiceId = targetRow.service_id;

        // Emit event cross-service connection update dengan info service yang terpengaruh
        io.emit('cross_service_connection_update', {
          sourceServiceId,
          targetServiceId,
          workspaceId
        });
        console.log(`✅ Cross-service connection update emitted: sourceService=${sourceServiceId}, targetService=${targetServiceId}, workspace=${workspaceId}`);
      } else {
        console.warn('⚠️ Could not find both service items for socket emit');
      }
    }
  } catch (err) {
    console.error('Failed to emit cross-service connection update:', err);
  }
};

module.exports = { initializeSocket, emitCmdbUpdate, emitServiceUpdate, emitServiceItemStatusUpdate, emitCrossServiceConnectionUpdate };