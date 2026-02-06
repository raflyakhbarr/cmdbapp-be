const pool = require('../db');

// Get all items by workspace
const getAllItems = (workspaceId = null) => {
  if (workspaceId) {
    return pool.query(
      'SELECT * FROM cmdb_items WHERE workspace_id = $1 ORDER BY group_id, order_in_group NULLS LAST',
      [workspaceId]
    );
  }
  return pool.query('SELECT * FROM cmdb_items ORDER BY group_id, order_in_group NULLS LAST');
};

const getItemById = (id) => pool.query('SELECT * FROM cmdb_items WHERE id = $1', [id]);

const createItem = (name, type, description, status = 'active', ip, category, location, group_id, env_type, position = null, workspace_id) =>
  pool.query(
    `INSERT INTO cmdb_items(
        name, type, description, status, ip, category, location, group_id, order_in_group, env_type, position, workspace_id
     )
     VALUES(
        $1, $2, $3, $4, $5, $6, $7, $8,
        COALESCE((SELECT MAX(order_in_group) + 1 FROM cmdb_items WHERE group_id = $8 AND workspace_id = $11), 0),
        $9, $10, $11
     ) RETURNING *`,
    [name, type, description, status, ip, category, location, group_id, env_type, position ? JSON.stringify(position) : null, workspace_id]
  );

const updateItem = (id, name, type, description, status, ip, category, location, group_id, env_type) =>
  pool.query(
    `UPDATE cmdb_items
     SET name = $1, type = $2, description = $3, status = $4, ip = $5, category = $6, location = $7, group_id = $8, env_type = $9
     WHERE id = $10
     RETURNING *`,
    [name, type, description, status, ip, category, location, group_id, env_type, id]
  );

const deleteItem = (id) => pool.query('DELETE FROM cmdb_items WHERE id = $1', [id]);

const updateItemPosition = (id, position) =>
  pool.query(
    'UPDATE cmdb_items SET position = $1 WHERE id = $2 RETURNING *',
    [position, id]
  );

// Update status and propagate to dependent items
const updateItemStatus = async (id, status) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    
    // Update the main item
    const result = await client.query(
      'UPDATE cmdb_items SET status = $1 WHERE id = $2 RETURNING *',
      [status, id]
    );
    
    await client.query('COMMIT');
    return result;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

const updateItemGroup = async (id, groupId, orderInGroup = null) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    
    // Get current item info
    const currentItem = await client.query('SELECT group_id, order_in_group, workspace_id FROM cmdb_items WHERE id = $1', [id]);
    const oldGroupId = currentItem.rows[0]?.group_id;
    const oldOrder = currentItem.rows[0]?.order_in_group;
    const workspaceId = currentItem.rows[0]?.workspace_id;
    
    // If moving from one group to another or removing from group
    if (oldGroupId !== groupId) {
      // Reorder items in old group (close the gap)
      if (oldGroupId) {
        await client.query(
          'UPDATE cmdb_items SET order_in_group = order_in_group - 1 WHERE group_id = $1 AND order_in_group > $2 AND workspace_id = $3',
          [oldGroupId, oldOrder, workspaceId]
        );
      }
      
      // Set order in new group
      if (groupId) {
        if (orderInGroup !== null) {
          // Insert at specific position - shift others down
          await client.query(
            'UPDATE cmdb_items SET order_in_group = order_in_group + 1 WHERE group_id = $1 AND order_in_group >= $2 AND workspace_id = $3',
            [groupId, orderInGroup, workspaceId]
          );
        } else {
          // Add at the end
          const maxOrder = await client.query(
            'SELECT COALESCE(MAX(order_in_group), -1) as max FROM cmdb_items WHERE group_id = $1 AND workspace_id = $2',
            [groupId, workspaceId]
          );
          orderInGroup = maxOrder.rows[0].max + 1;
        }
      } else {
        orderInGroup = null;
      }
    }
    
    // Update the item
    const result = await client.query(
      'UPDATE cmdb_items SET group_id = $1, order_in_group = $2 WHERE id = $3 RETURNING *',
      [groupId, orderInGroup, id]
    );
    
    await client.query('COMMIT');
    return result;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

const reorderItemInGroup = async (itemId, newOrder) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    
    // Get item info
    const item = await client.query(
      'SELECT group_id, order_in_group, workspace_id FROM cmdb_items WHERE id = $1',
      [itemId]
    );
    
    if (!item.rows[0]) {
      throw new Error('Item not found');
    }
    
    if (!item.rows[0].group_id) {
      throw new Error('Item not in a group');
    }
    
    const groupId = item.rows[0].group_id;
    const oldOrder = item.rows[0].order_in_group || 0;
    const workspaceId = item.rows[0].workspace_id;
    
    console.log(`Reordering item ${itemId} in group ${groupId}: ${oldOrder} -> ${newOrder}`);
    
    if (oldOrder === newOrder) {
      await client.query('COMMIT');
      return item;
    }
    
    if (oldOrder < newOrder) {
      // Moving down: shift items up
      await client.query(
        'UPDATE cmdb_items SET order_in_group = order_in_group - 1 WHERE group_id = $1 AND order_in_group > $2 AND order_in_group <= $3 AND workspace_id = $4',
        [groupId, oldOrder, newOrder, workspaceId]
      );
    } else {
      // Moving up: shift items down
      await client.query(
        'UPDATE cmdb_items SET order_in_group = order_in_group + 1 WHERE group_id = $1 AND order_in_group >= $2 AND order_in_group < $3 AND workspace_id = $4',
        [groupId, newOrder, oldOrder, workspaceId]
      );
    }
    
    // Update the item's order
    const result = await client.query(
      'UPDATE cmdb_items SET order_in_group = $1 WHERE id = $2 RETURNING *',
      [newOrder, itemId]
    );
    
    await client.query('COMMIT');
    console.log(`Successfully reordered item ${itemId}`);
    return result;
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(`Error reordering item ${itemId}:`, err);
    throw err;
  } finally {
    client.release();
  }
};

module.exports = {
  getAllItems,
  getItemById,
  createItem,
  updateItem,
  deleteItem,
  updateItemPosition,
  updateItemStatus,
  updateItemGroup,
  reorderItemInGroup,
};