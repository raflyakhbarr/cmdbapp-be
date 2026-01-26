const express = require('express');
const http = require('http');
const cors = require('cors');
const path = require('path');
require('dotenv').config();

const app = express();
const server = http.createServer(app);

const { initializeSocket } = require('./socket');
initializeSocket(server);

const corsOptions = {
  origin: ['http://localhost:5173', 'http://localhost:5000'],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
  exposedHeaders: ['Authorization']
};

app.use(cors(corsOptions));
app.use(express.json());

app.use('/uploads', (req, res, next) => {
  res.header('Access-Control-Allow-Origin', 'http://localhost:5173');
  res.header('Access-Control-Allow-Methods', 'GET');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.header('Cross-Origin-Resource-Policy', 'cross-origin');
  next();
}, express.static(path.join(__dirname, 'uploads')));

const cmdbRoutes = require('./routes/cmdbRoutes');
const groupRoutes = require('./routes/groupRoutes');
const edgeHandleRoutes = require('./routes/edgeHandleRoutes');
const workspaceRoutes = require('./routes/workspaceRoutes')

app.use('/api/cmdb', cmdbRoutes);
app.use('/api/groups', groupRoutes);
app.use('/api/edge-handles', edgeHandleRoutes);
app.use('/api/workspaces', workspaceRoutes);

const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});