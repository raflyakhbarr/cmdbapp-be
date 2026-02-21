const express = require('express');
const http = require('http');
const cors = require('cors');
const path = require('path');
const session = require('express-session');
require('dotenv').config();

const app = express();
const server = http.createServer(app);

// Session middleware for password verification
app.use(session({
  secret: process.env.SESSION_SECRET || 'cmdb-share-session-secret',
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: process.env.NODE_ENV === 'production',
    httpOnly: true,
    maxAge: 24 * 60 * 60 * 1000 // 24 hours
  }
}));

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
const workspaceRoutes = require('./routes/workspaceRoutes');
const serviceRoutes = require('./routes/serviceRoutes');
const serviceEdgeHandleRoutes = require('./routes/serviceEdgeHandleRoutes');
const serviceGroupRoutes = require('./routes/serviceGroupRoutes');
const shareRoutes = require('./routes/shareRoutes');

app.use('/api/cmdb', cmdbRoutes);
app.use('/api/groups', groupRoutes);
app.use('/api/edge-handles', edgeHandleRoutes);
app.use('/api/workspaces', workspaceRoutes);
app.use('/api/services', serviceRoutes);
app.use('/api/service-items', serviceRoutes);
app.use('/api/service-connections', serviceRoutes);
app.use('/api/service-edge-handles', serviceEdgeHandleRoutes);
app.use('/api/service-groups', serviceGroupRoutes);
app.use('/api/share', shareRoutes);

const PORT = process.env.PORT;
server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});