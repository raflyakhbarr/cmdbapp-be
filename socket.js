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
    const pool = require('./db');

    // Log input parameters
    console.log(`🔧 emitServiceUpdate called with: serviceIdOrItemId=${serviceIdOrItemId}, workspaceId=${workspaceId}`);

    // First, check if this ID is a service ID directly (since we're calling from service routes)
    const serviceResult = await pool.query(
      'SELECT id FROM services WHERE id = $1',
      [serviceIdOrItemId]
    );

    let actualServiceId;
    if (serviceResult.rows.length > 0) {
      // It's a service ID
      actualServiceId = serviceIdOrItemId;
      console.log(`✅ Confirmed as service ID: ${actualServiceId}`);
    } else {
      // Check if it's a service item ID
      const itemResult = await pool.query(
        'SELECT service_id FROM service_items WHERE id = $1',
        [serviceIdOrItemId]
      );

      if (itemResult.rows.length > 0) {
        // It's a service item ID, get the service_id
        actualServiceId = itemResult.rows[0].service_id;
        console.log(`✅ Converted from service item ID ${serviceIdOrItemId} to service ID: ${actualServiceId}`);
      } else {
        console.warn(`⚠️ Could not find service or service item with ID: ${serviceIdOrItemId}`);
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
const emitServiceItemStatusUpdate = async (serviceItemId, newStatus, workspaceId, serviceId) => {
  if (!io) {
    console.warn('⚠️ Socket.IO belum diinisialisasi. Lewati emit.');
    return;
  }
  try {
    console.log(`🔔 Emitting service_item_status_update: item=${serviceItemId}, status=${newStatus}, service=${serviceId}, workspace=${workspaceId}`);
    io.emit('service_item_status_update', {
      serviceItemId,
      newStatus,
      workspaceId,
      serviceId
    });
    console.log(`✅ Successfully emitted service_item_status_update event`);
  } catch (err) {
    console.error('❌ Failed to emit service item status update:', err);
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

// Emit event untuk external item position updates (for realtime shared view updates)
const emitExternalItemPositionUpdate = async (externalServiceItemId, position, workspaceId, serviceId) => {
  if (!io) {
    console.warn('⚠️ Socket.IO belum diinisialisasi. Lewati emit.');
    return;
  }
  try {
    console.log(`🔔 Emitting external_item_position_update: item=${externalServiceItemId}, service=${serviceId}, workspace=${workspaceId}, position=`, position);
    io.emit('external_item_position_update', {
      externalServiceItemId,
      position,
      workspaceId,
      serviceId
    });
    console.log(`✅ Successfully emitted external_item_position_update event`);
  } catch (err) {
    console.error('❌ Failed to emit external item position update:', err);
  }
};

module.exports = { initializeSocket, emitCmdbUpdate, emitServiceUpdate, emitServiceItemStatusUpdate, emitCrossServiceConnectionUpdate, emitExternalItemPositionUpdate };