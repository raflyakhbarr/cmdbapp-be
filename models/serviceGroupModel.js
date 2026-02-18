const pool = require('../db');

// ==================== SERVICE GROUPS CRUD ====================

const getAllServiceGroups = (serviceId, workspaceId) => {
  return pool.query(
    'SELECT * FROM service_groups WHERE service_id = $1 AND workspace_id = $2 ORDER BY created_at',
    [serviceId, workspaceId]
  );
};

const getServiceGroupById = (id) => {
  return pool.query('SELECT * FROM service_groups WHERE id = $1', [id]);
};

const createServiceGroup = (serviceId, name, description, color, position, workspaceId) => {
  return pool.query(
    `INSERT INTO service_groups(service_id, name, description, color, position, workspace_id)
     VALUES($1, $2, $3, $4, $5, $6)
     RETURNING *`,
    [serviceId, name, description, color || '#e0e7ff', position ? JSON.stringify(position) : null, workspaceId]
  );
};

const updateServiceGroup = (id, name, description, color, position) => {
  return pool.query(
    `UPDATE service_groups
     SET name = $1, description = $2, color = $3, position = $4
     WHERE id = $5
     RETURNING *`,
    [name, description, color, position ? JSON.stringify(position) : null, id]
  );
};

const deleteServiceGroup = (id) => {
  return pool.query('DELETE FROM service_groups WHERE id = $1 RETURNING *', [id]);
};

const updateServiceGroupPosition = (id, position) => {
  return pool.query(
    'UPDATE service_groups SET position = $1 WHERE id = $2 RETURNING *',
    [JSON.stringify(position), id]
  );
};

// ==================== SERVICE GROUP CONNECTIONS ====================

// Get semua koneksi: group-to-group (source_id) dan group-to-item (source_group_id)
const getAllServiceGroupConnections = (serviceId, workspaceId) => {
  return pool.query(
    `SELECT * FROM service_group_connections
     WHERE service_id = $1 AND workspace_id = $2
     ORDER BY created_at`,
    [serviceId, workspaceId]
  );
};

// Buat koneksi group-to-group: source_id → target_id (keduanya service_groups)
const createServiceGroupConnection = (serviceId, sourceId, targetId, workspaceId) => {
  return pool.query(
    `INSERT INTO service_group_connections(service_id, source_id, target_id, workspace_id)
     VALUES($1, $2, $3, $4)
     ON CONFLICT DO NOTHING
     RETURNING *`,
    [serviceId, sourceId, targetId, workspaceId]
  );
};

// Buat koneksi group-to-item: source_group_id → target_item_id (service_items)
// PERBAIKAN: pakai target_item_id bukan target_id agar tidak konflik FK
const createServiceGroupToItemConnection = (serviceId, sourceGroupId, targetItemId, workspaceId) => {
  return pool.query(
    `INSERT INTO service_group_connections(service_id, source_group_id, target_item_id, workspace_id)
     VALUES($1, $2, $3, $4)
     ON CONFLICT DO NOTHING
     RETURNING *`,
    [serviceId, sourceGroupId, targetItemId, workspaceId]
  );
};

// Hapus koneksi group-to-group
const deleteServiceGroupConnection = (serviceId, sourceId, targetId) => {
  return pool.query(
    `DELETE FROM service_group_connections
     WHERE service_id = $1 AND source_id = $2 AND target_id = $3
     RETURNING *`,
    [serviceId, sourceId, targetId]
  );
};

// Hapus koneksi group-to-item
// PERBAIKAN: pakai target_item_id bukan target_id
const deleteServiceGroupToItemConnection = (serviceId, sourceGroupId, targetItemId) => {
  return pool.query(
    `DELETE FROM service_group_connections
     WHERE service_id = $1 AND source_group_id = $2 AND target_item_id = $3
     RETURNING *`,
    [serviceId, sourceGroupId, targetItemId]
  );
};

// ==================== SERVICE ITEM GROUP ASSIGNMENT ====================

const updateServiceItemGroup = async (id, groupId, orderInGroup = null) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const currentItem = await client.query(
      'SELECT group_id, order_in_group, service_id, workspace_id FROM service_items WHERE id = $1',
      [id]
    );

    if (currentItem.rows.length === 0) {
      throw new Error('Service item not found');
    }

    const oldGroupId = currentItem.rows[0].group_id;
    const oldOrder = currentItem.rows[0].order_in_group;
    const serviceId = currentItem.rows[0].service_id;
    const workspaceId = currentItem.rows[0].workspace_id;

    if (oldGroupId !== groupId) {
      if (oldGroupId) {
        await client.query(
          'UPDATE service_items SET order_in_group = order_in_group - 1 WHERE group_id = $1 AND order_in_group > $2 AND service_id = $3 AND workspace_id = $4',
          [oldGroupId, oldOrder, serviceId, workspaceId]
        );
      }

      if (groupId) {
        if (orderInGroup !== null) {
          await client.query(
            'UPDATE service_items SET order_in_group = order_in_group + 1 WHERE group_id = $1 AND order_in_group >= $2 AND service_id = $3 AND workspace_id = $4',
            [groupId, orderInGroup, serviceId, workspaceId]
          );
        } else {
          const maxOrder = await client.query(
            'SELECT COALESCE(MAX(order_in_group), -1) as max FROM service_items WHERE group_id = $1 AND service_id = $2 AND workspace_id = $3',
            [groupId, serviceId, workspaceId]
          );
          orderInGroup = maxOrder.rows[0].max + 1;
        }
      } else {
        orderInGroup = null;
      }
    }

    const result = await client.query(
      'UPDATE service_items SET group_id = $1, order_in_group = $2 WHERE id = $3 RETURNING *',
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

const reorderServiceItemInGroup = async (itemId, newOrder) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const item = await client.query(
      'SELECT group_id, order_in_group, service_id, workspace_id FROM service_items WHERE id = $1',
      [itemId]
    );

    if (!item.rows[0]) throw new Error('Service item not found');
    if (!item.rows[0].group_id) throw new Error('Service item not in a group');

    const groupId = item.rows[0].group_id;
    const oldOrder = item.rows[0].order_in_group || 0;
    const serviceId = item.rows[0].service_id;
    const workspaceId = item.rows[0].workspace_id;

    if (oldOrder === newOrder) {
      await client.query('COMMIT');
      return item;
    }

    if (oldOrder < newOrder) {
      await client.query(
        'UPDATE service_items SET order_in_group = order_in_group - 1 WHERE group_id = $1 AND order_in_group > $2 AND order_in_group <= $3 AND service_id = $4 AND workspace_id = $5',
        [groupId, oldOrder, newOrder, serviceId, workspaceId]
      );
    } else {
      await client.query(
        'UPDATE service_items SET order_in_group = order_in_group + 1 WHERE group_id = $1 AND order_in_group >= $2 AND order_in_group < $3 AND service_id = $4 AND workspace_id = $5',
        [groupId, newOrder, oldOrder, serviceId, workspaceId]
      );
    }

    const result = await client.query(
      'UPDATE service_items SET order_in_group = $1 WHERE id = $2 RETURNING *',
      [newOrder, itemId]
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

module.exports = {
  getAllServiceGroups,
  getServiceGroupById,
  createServiceGroup,
  updateServiceGroup,
  deleteServiceGroup,
  updateServiceGroupPosition,
  getAllServiceGroupConnections,
  createServiceGroupConnection,
  createServiceGroupToItemConnection,
  deleteServiceGroupConnection,
  deleteServiceGroupToItemConnection,
  updateServiceItemGroup,
  reorderServiceItemInGroup,
};