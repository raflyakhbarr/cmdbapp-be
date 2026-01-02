const pool = require('../db');

const getAllGroups = () => pool.query('SELECT * FROM cmdb_groups');

const getGroupById = (id) => pool.query('SELECT * FROM cmdb_groups WHERE id = $1', [id]);

const createGroup = (name, description, color = '#e0e7ff', position = null) =>
  pool.query(
    'INSERT INTO cmdb_groups(name, description, color, position) VALUES($1, $2, $3, $4) RETURNING *',
    [name, description, color, position]
  );

const updateGroup = (id, name, description, color, position) =>
  pool.query(
    'UPDATE cmdb_groups SET name = $1, description = $2, color = $3, position = $4 WHERE id = $5 RETURNING *',
    [name, description, color, position ? JSON.stringify(position) : null, id]
  );

const deleteGroup = (id) => pool.query('DELETE FROM cmdb_groups WHERE id = $1', [id]);

const updateGroupPosition = (id, position) =>
  pool.query(
    'UPDATE cmdb_groups SET position = $1 WHERE id = $2 RETURNING *',
    [JSON.stringify(position), id]
  );

// Group connections
const getAllGroupConnections = () => pool.query('SELECT * FROM group_connections');

const createGroupConnection = (sourceId, targetId) =>
  pool.query(
    'INSERT INTO group_connections(source_id, target_id) VALUES($1, $2) RETURNING *',
    [sourceId, targetId]
  );

const deleteGroupConnection = (sourceId, targetId) =>
  pool.query(
    'DELETE FROM group_connections WHERE source_id = $1 AND target_id = $2',
    [sourceId, targetId]
  );

const getConnectionsByGroupId = (groupId) => pool.query(
  `SELECT 
    'item-to-group' as type,
    c.source_id as source_id,
    ci.name as source_name,
    ci.type as source_type,
    $1 as target_id,
    'group' as target_type
  FROM connections c
  JOIN cmdb_items ci ON c.source_id = ci.id
  WHERE c.target_group_id = $1
  
  UNION ALL
  
  SELECT 
    'group-to-item' as type,
    $1 as source_id,
    'group' as source_type,
    c.target_id,
    ci.name as target_name,
    ci.type as target_type
  FROM connections c
  JOIN cmdb_items ci ON c.target_id = ci.id
  WHERE c.source_id IN (SELECT id FROM cmdb_items WHERE group_id = $1)
  
  UNION ALL
  
  SELECT 
    'group-to-group' as type,
    gc.source_id,
    'group' as source_type,
    gc.target_id,
    'group' as target_type,
    NULL as extra
  FROM group_connections gc
  WHERE gc.source_id = $1 OR gc.target_id = $1`,
  [groupId]
);

module.exports = {
  getAllGroups,
  getGroupById,
  createGroup,
  updateGroup,
  deleteGroup,
  updateGroupPosition,
  getAllGroupConnections,
  createGroupConnection,
  deleteGroupConnection,
  getConnectionsByGroupId,
};