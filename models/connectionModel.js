//connectionModel.js
const pool = require('../db');

const getAllConnections = () => pool.query('SELECT * FROM connections');

// Get connections for a specific item (both as source and target)
const getConnectionsByItemId = (itemId) => pool.query(
  'SELECT * FROM connections WHERE source_id = $1 OR target_id = $1',
  [itemId]
);

// Get items that depend on a specific item (targets where this item is source)
const getDependentItems = (itemId) => pool.query(
  `SELECT ci.* FROM cmdb_items ci
   INNER JOIN connections c ON ci.id = c.target_id
   WHERE c.source_id = $1`,
  [itemId]
);

// Get items that this item depends on (sources where this item is target)
const getDependencies = (itemId) => pool.query(
  `SELECT ci.* FROM cmdb_items ci
   INNER JOIN connections c ON ci.id = c.source_id
   WHERE c.target_id = $1`,
  [itemId]
);

// Create a new connection
const createConnection = (sourceId, targetId) =>
  pool.query(
    'INSERT INTO connections(source_id, target_id) VALUES($1, $2) RETURNING *',
    [sourceId, targetId]
  );

// Delete a connection
const deleteConnection = (sourceId, targetId) =>
  pool.query(
    'DELETE FROM connections WHERE source_id = $1 AND target_id = $2',
    [sourceId, targetId]
  );

// Delete all connections for an item
const deleteConnectionsByItemId = (itemId) =>
  pool.query(
    'DELETE FROM connections WHERE source_id = $1 OR target_id = $1',
    [itemId]
  );

// Get connection status cascade - recursive function to get all affected items
const getAffectedItems = async (itemId) => {
  const result = await pool.query(
    `WITH RECURSIVE affected AS (
      SELECT target_id as item_id, 1 as level
      FROM connections
      WHERE source_id = $1
      
      UNION
      
      SELECT c.target_id, a.level + 1
      FROM connections c
      INNER JOIN affected a ON c.source_id = a.item_id
      WHERE a.level < 10
    )
    SELECT DISTINCT ci.*, a.level
    FROM affected a
    INNER JOIN cmdb_items ci ON ci.id = a.item_id
    ORDER BY a.level`,
    [itemId]
  );
  return result;
};

const createItemToGroupConnection = (itemId, groupId) =>
  pool.query(
    'INSERT INTO connections(source_id, target_group_id) VALUES($1, $2) RETURNING *',
    [itemId, groupId]
  );

const deleteItemToGroupConnection = (itemId, groupId) =>
  pool.query(
    'DELETE FROM connections WHERE source_id = $1 AND target_group_id = $2',
    [itemId, groupId]
  );

const getConnectionsWithGroups = (itemId) => pool.query(
  'SELECT * FROM connections WHERE source_id = $1',
  [itemId]
);

const createGroupToItemConnection = (groupId, itemId) =>
  pool.query(
    'INSERT INTO connections(source_group_id, target_id) VALUES($1, $2) RETURNING *',
    [groupId, itemId]
  );

const deleteGroupToItemConnection = (groupId, itemId) =>
  pool.query(
    'DELETE FROM connections WHERE source_group_id = $1 AND target_id = $2',
    [groupId, itemId]
  );



module.exports = {
  getAllConnections,
  getConnectionsByItemId,
  getDependentItems,
  getDependencies,
  createConnection,
  deleteConnection,
  deleteConnectionsByItemId,
  getAffectedItems,
  createItemToGroupConnection,
  deleteItemToGroupConnection,
  getConnectionsWithGroups,
  createGroupToItemConnection,
  deleteGroupToItemConnection,
};