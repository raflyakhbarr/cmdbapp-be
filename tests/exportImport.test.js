// cmdbapp-be/tests/exportImport.test.js
const request = require('supertest');
const express = require('express');
const exportImportRoutes = require('../routes/exportImportRoutes');
const { pool } = require('../db');

// Mock authentication middleware
jest.mock('../middleware/auth', () => ({
  authenticateToken: (req, res, next) => {
    req.user = { id: 1, username: 'test_user' };
    next();
  }
}));

// Setup test app
const app = express();
app.use(express.json());
app.use('/api', exportImportRoutes);

describe('Export/Import API', () => {

  beforeEach(async () => {
    // Setup test database - clean test data
    try {
      await pool.query('TRUNCATE TABLE cross_service_connections CASCADE');
      await pool.query('TRUNCATE TABLE service_items CASCADE');
      await pool.query('TRUNCATE TABLE services CASCADE');
      await pool.query('TRUNCATE TABLE cmdb_groups CASCADE');
      await pool.query('TRUNCATE TABLE cmdb_items CASCADE');
    } catch (err) {
      console.log('Cleanup skipped (tables may not exist yet):', err.message);
    }
  });

  afterAll(async () => {
    // Cleanup after all tests
    await pool.end();
  });

  describe('GET /api/cmdb/export/excel', () => {

    test('should return 401 without authentication', async () => {
      // Temporarily remove auth mock to test auth failure
      const auth = require('../middleware/auth');
      const originalAuthenticate = auth.authenticateToken;
      auth.authenticateToken = (req, res, next) => {
        res.status(401).json({ error: 'Unauthorized' });
      };

      const response = await request(app)
        .get('/api/cmdb/export/excel?workspace_id=1')
        .expect(401);

      // Restore auth mock
      auth.authenticateToken = originalAuthenticate;
    });

    test('should export data when authenticated', async () => {
      // Insert test data
      await pool.query(
        'INSERT INTO cmdb_items (name, type, status, workspace_id) VALUES ($1, $2, $3, $4)',
        ['Test Server', 'server', 'active', 1]
      );

      const response = await request(app)
        .get('/api/cmdb/export/excel?workspace_id=1')
        .expect('Content-Type', /vnd.openxmlformats/)
        .expect(200);

      expect(response.body).toBeInstanceOf(Buffer);
      expect(response.body.length).toBeGreaterThan(0);
    });

    test('should return 400 without workspace_id', async () => {
      const response = await request(app)
        .get('/api/cmdb/export/excel')
        .expect(400); // Should fail validation
    });

  });

  describe('GET /api/cmdb/export/json', () => {

    test('should return 401 without authentication', async () => {
      // Temporarily remove auth mock to test auth failure
      const auth = require('../middleware/auth');
      const originalAuthenticate = auth.authenticateToken;
      auth.authenticateToken = (req, res, next) => {
        res.status(401).json({ error: 'Unauthorized' });
      };

      const response = await request(app)
        .get('/api/cmdb/export/json?workspace_id=1')
        .expect(401);

      // Restore auth mock
      auth.authenticateToken = originalAuthenticate;
    });

    test('should export JSON data when authenticated', async () => {
      // Insert test data
      await pool.query(
        'INSERT INTO cmdb_items (name, type, status, workspace_id) VALUES ($1, $2, $3, $4)',
        ['Test Server', 'server', 'active', 1]
      );

      const response = await request(app)
        .get('/api/cmdb/export/json?workspace_id=1')
        .expect(200)
        .expect('Content-Type', /json/);

      expect(response.body).toHaveProperty('cmdbItems');
      expect(response.body).toHaveProperty('groups');
      expect(response.body).toHaveProperty('services');
      expect(Array.isArray(response.body.cmdbItems)).toBe(true);
    });

  });

  describe('GET /api/cmdb/import/template', () => {

    test('should return 401 without authentication', async () => {
      // Temporarily remove auth mock to test auth failure
      const auth = require('../middleware/auth');
      const originalAuthenticate = auth.authenticateToken;
      auth.authenticateToken = (req, res, next) => {
        res.status(401).json({ error: 'Unauthorized' });
      };

      const response = await request(app)
        .get('/api/cmdb/import/template')
        .expect(401);

      // Restore auth mock
      auth.authenticateToken = originalAuthenticate;
    });

    test('should return template file when authenticated', async () => {
      const response = await request(app)
        .get('/api/cmdb/import/template')
        .expect(200)
        .expect('Content-Type', /vnd.openxmlformats/);

      expect(response.body).toBeInstanceOf(Buffer);
      expect(response.body.length).toBeGreaterThan(0);
    });

  });

  describe('POST /api/cmdb/import/preview', () => {

    test('should return 401 without authentication', async () => {
      // Temporarily remove auth mock to test auth failure
      const auth = require('../middleware/auth');
      const originalAuthenticate = auth.authenticateToken;
      auth.authenticateToken = (req, res, next) => {
        res.status(401).json({ error: 'Unauthorized' });
      };

      const importData = {
        workspace_id: 1,
        file_data: {
          cmdbItems: [{ id: 1, name: 'Test Item', type: 'server', status: 'active' }],
          groups: [],
          services: [],
          serviceItems: [],
          crossServiceConnections: []
        },
        strategy: 'merge'
      };

      const response = await request(app)
        .post('/api/cmdb/import/preview')
        .send(importData)
        .expect(401);

      // Restore auth mock
      auth.authenticateToken = originalAuthenticate;
    });

    test('should validate import data when authenticated', async () => {
      const importData = {
        workspace_id: 1,
        file_data: {
          cmdbItems: [{ name: 'New Item', type: 'server', status: 'active' }],
          groups: [],
          services: [],
          serviceItems: [],
          crossServiceConnections: []
        },
        strategy: 'merge'
      };

      const response = await request(app)
        .post('/api/cmdb/import/preview')
        .send(importData)
        .expect(200)
        .expect('Content-Type', /json/);

      expect(response.body).toHaveProperty('preview_id');
      expect(response.body).toHaveProperty('conflicts');
      expect(response.body).toHaveProperty('summary');
    });

    test('should return 400 without workspace_id', async () => {
      const response = await request(app)
        .post('/api/cmdb/import/preview')
        .send({
          file_data: {},
          strategy: 'merge'
        })
        .expect(400); // Should fail validation
    });

  });

  describe('POST /api/cmdb/import/confirm', () => {

    test('should return 401 without authentication', async () => {
      // Temporarily remove auth mock to test auth failure
      const auth = require('../middleware/auth');
      const originalAuthenticate = auth.authenticateToken;
      auth.authenticateToken = (req, res, next) => {
        res.status(401).json({ error: 'Unauthorized' });
      };

      const response = await request(app)
        .post('/api/cmdb/import/confirm')
        .send({
          workspace_id: 1,
          preview_id: 'test_preview_123'
        })
        .expect(401);

      // Restore auth mock
      auth.authenticateToken = originalAuthenticate;
    });

    test('should import data when authenticated with valid preview', async () => {
      // First create a preview
      const importData = {
        workspace_id: 1,
        file_data: {
          cmdbItems: [{ name: 'Imported Server', type: 'server', status: 'active' }],
          groups: [],
          services: [],
          serviceItems: [],
          crossServiceConnections: []
        },
        strategy: 'merge'
      };

      const previewResponse = await request(app)
        .post('/api/cmdb/import/preview')
        .send(importData)
        .expect(200);

      const { preview_id } = previewResponse.body;

      // Confirm the import
      const confirmResponse = await request(app)
        .post('/api/cmdb/import/confirm')
        .send({
          workspace_id: 1,
          preview_id: preview_id
        })
        .expect(200)
        .expect('Content-Type', /json/);

      expect(confirmResponse.body).toHaveProperty('success');
      expect(confirmResponse.body).toHaveProperty('imported');

      // Verify database state
      const result = await pool.query(
        'SELECT * FROM cmdb_items WHERE name = $1 AND workspace_id = $2',
        ['Imported Server', 1]
      );

      expect(result.rows.length).toBeGreaterThan(0);
      expect(result.rows[0].name).toBe('Imported Server');
      expect(result.rows[0].type).toBe('server');
    });

  });

});
