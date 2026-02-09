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

module.exports = { initializeSocket, emitCmdbUpdate };