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

const emitCmdbUpdate = async (cmdbModel) => {
  if (!io) {
    console.warn('⚠️ Socket.IO belum diinisialisasi. Lewati emit.');
    return;
  }
  try {
    const result = await cmdbModel.getAllItems();
    io.emit('cmdb_update', result.rows);
  } catch (err) {
    console.error('Failed to emit CMDB update:', err);
  }
};

module.exports = { initializeSocket, emitCmdbUpdate };