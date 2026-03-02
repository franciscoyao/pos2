import express from 'express';
import { body, validationResult } from 'express-validator';
import pool from '../database/db.js';
import { authenticate } from '../middleware/auth.js';
import { broadcastOrderUpdate } from '../websocket.js';

const router = express.Router();

// Get all orders
router.get('/', authenticate, async (req, res) => {
  const { status, table_number, waiter_id } = req.query;

  try {
    let query = `
      SELECT o.*, u.name as waiter_name 
      FROM orders o
      LEFT JOIN users u ON o.waiter_id = u.id
      WHERE 1=1
    `;
    const params = [];

    if (status) {
      params.push(status);
      query += ` AND o.status = $${params.length}`;
    }

    if (table_number) {
      params.push(table_number);
      query += ` AND o.table_number = $${params.length}`;
    }

    if (waiter_id) {
      params.push(waiter_id);
      query += ` AND o.waiter_id = $${params.length}`;
    }

    query += ' ORDER BY o.created_at DESC';

    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (error) {
    console.error('Get orders error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get active orders
router.get('/active', authenticate, async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT o.*, u.name as waiter_name 
      FROM orders o
      LEFT JOIN users u ON o.waiter_id = u.id
      WHERE o.status IN ('pending', 'sent', 'accepted', 'cooking', 'ready')
      ORDER BY o.created_at DESC
    `);
    res.json(result.rows);
  } catch (error) {
    console.error('Get active orders error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get order by ID with items
router.get('/:id', authenticate, async (req, res) => {
  const { id } = req.params;

  try {
    const orderResult = await pool.query(`
      SELECT o.*, u.name as waiter_name 
      FROM orders o
      LEFT JOIN users u ON o.waiter_id = u.id
      WHERE o.id = $1
    `, [id]);

    if (orderResult.rows.length === 0) {
      return res.status(404).json({ error: 'Order not found' });
    }

    const itemsResult = await pool.query(`
      SELECT oi.*, mi.name as menu_item_name, mi.station
      FROM order_items oi
      JOIN menu_items mi ON oi.menu_item_id = mi.id
      WHERE oi.order_id = $1
      ORDER BY oi.created_at
    `, [id]);

    res.json({
      ...orderResult.rows[0],
      items: itemsResult.rows
    });
  } catch (error) {
    console.error('Get order error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Create order
router.post('/', authenticate, [
  body('table_number').notEmpty(),
  body('items').isArray({ min: 1 })
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  const { table_number, type, items, waiter_id } = req.body;
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // Generate order number
    const orderNumber = `ORD-${Date.now()}`;

    // Calculate totals
    let subtotal = 0;
    for (const item of items) {
      subtotal += item.price_at_time * item.quantity;
    }

    const taxAmount = subtotal * 0.1; // 10% tax
    const serviceAmount = subtotal * 0.05; // 5% service
    const totalAmount = subtotal + taxAmount + serviceAmount;

    // Create order
    const orderResult = await client.query(
      `INSERT INTO orders (order_number, table_number, type, waiter_id, status, subtotal, tax_amount, service_amount, total_amount)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING *`,
      [orderNumber, table_number, type || 'dine-in', waiter_id || null, 'pending', subtotal, taxAmount, serviceAmount, totalAmount]
    );

    const order = orderResult.rows[0];

    // Create order items
    for (const item of items) {
      await client.query(
        'INSERT INTO order_items (order_id, menu_item_id, quantity, price_at_time, status) VALUES ($1, $2, $3, $4, $5)',
        [order.id, item.menu_item_id, item.quantity, item.price_at_time, 'pending']
      );
    }

    await client.query('COMMIT');

    // Broadcast update
    broadcastOrderUpdate({ type: 'order_created', order });

    res.status(201).json(order);
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Create order error:', error);
    res.status(500).json({ error: 'Internal server error' });
  } finally {
    client.release();
  }
});

// Update order status
router.patch('/:id/status', authenticate, async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;

  try {
    const result = await pool.query(
      'UPDATE orders SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *',
      [status, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Order not found' });
    }

    const order = result.rows[0];
    broadcastOrderUpdate({ type: 'order_updated', order });

    res.json(order);
  } catch (error) {
    console.error('Update order status error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Update order item status
router.patch('/items/:id/status', authenticate, async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;

  try {
    const result = await pool.query(
      'UPDATE order_items SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *',
      [status, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Order item not found' });
    }

    broadcastOrderUpdate({ type: 'item_updated', item: result.rows[0] });

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Update order item status error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Pay for order
router.post('/:id/pay', authenticate, async (req, res) => {
  const { id } = req.params;
  const { method, amount, items } = req.body;
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // Create payment
    await client.query(
      'INSERT INTO payments (order_id, amount, method, items_json, status) VALUES ($1, $2, $3, $4, $5)',
      [id, amount, method, JSON.stringify(items || []), 'completed']
    );

    // Update order status
    const orderResult = await client.query(
      'UPDATE orders SET status = $1, payment_method = $2, completed_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP WHERE id = $3 RETURNING *',
      ['paid', method, id]
    );

    // Update order items to paid
    if (items && items.length > 0) {
      const itemIds = items.map(i => i.id);
      await client.query(
        'UPDATE order_items SET status = $1 WHERE id = ANY($2)',
        ['paid', itemIds]
      );
    } else {
      await client.query(
        'UPDATE order_items SET status = $1 WHERE order_id = $2',
        ['paid', id]
      );
    }

    await client.query('COMMIT');

    const order = orderResult.rows[0];
    broadcastOrderUpdate({ type: 'order_paid', order });

    res.json(order);
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Pay order error:', error);
    res.status(500).json({ error: 'Internal server error' });
  } finally {
    client.release();
  }
});

// Split table
router.post('/split', authenticate, async (req, res) => {
  const { source_order_id, target_table, item_ids } = req.body;
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // Find or create target order
    const existingResult = await client.query(
      `SELECT * FROM orders WHERE table_number = $1 AND status NOT IN ('paid', 'cancelled', 'completed')`,
      [target_table]
    );

    let targetOrderId;

    if (existingResult.rows.length > 0) {
      targetOrderId = existingResult.rows[0].id;
    } else {
      const sourceOrder = await client.query('SELECT * FROM orders WHERE id = $1', [source_order_id]);
      const orderNumber = `ORD-${Date.now()}`;
      
      const newOrderResult = await client.query(
        `INSERT INTO orders (order_number, table_number, type, waiter_id, status, subtotal, tax_amount, service_amount, total_amount)
         VALUES ($1, $2, $3, $4, $5, 0, 0, 0, 0) RETURNING *`,
        [orderNumber, target_table, sourceOrder.rows[0].type, sourceOrder.rows[0].waiter_id, 'pending']
      );
      targetOrderId = newOrderResult.rows[0].id;
    }

    // Move items
    await client.query(
      'UPDATE order_items SET order_id = $1 WHERE id = ANY($2)',
      [targetOrderId, item_ids]
    );

    await client.query('COMMIT');

    broadcastOrderUpdate({ type: 'table_split', source_order_id, target_order_id: targetOrderId });

    res.json({ message: 'Table split successfully', target_order_id: targetOrderId });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Split table error:', error);
    res.status(500).json({ error: 'Internal server error' });
  } finally {
    client.release();
  }
});

// Merge tables
router.post('/merge', authenticate, async (req, res) => {
  const { from_table, to_table } = req.body;
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const fromOrders = await client.query(
      `SELECT * FROM orders WHERE table_number = $1 AND status NOT IN ('paid', 'cancelled', 'completed')`,
      [from_table]
    );

    if (fromOrders.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Source table has no active orders' });
    }

    const toOrders = await client.query(
      `SELECT * FROM orders WHERE table_number = $1 AND status NOT IN ('paid', 'cancelled', 'completed')`,
      [to_table]
    );

    if (toOrders.rows.length === 0) {
      // Just update table number
      await client.query(
        'UPDATE orders SET table_number = $1 WHERE id = $2',
        [to_table, fromOrders.rows[0].id]
      );
    } else {
      // Move all items to target order
      await client.query(
        'UPDATE order_items SET order_id = $1 WHERE order_id = $2',
        [toOrders.rows[0].id, fromOrders.rows[0].id]
      );

      // Cancel source order
      await client.query(
        'UPDATE orders SET status = $1 WHERE id = $2',
        ['cancelled', fromOrders.rows[0].id]
      );
    }

    await client.query('COMMIT');

    broadcastOrderUpdate({ type: 'tables_merged', from_table, to_table });

    res.json({ message: 'Tables merged successfully' });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Merge tables error:', error);
    res.status(500).json({ error: 'Internal server error' });
  } finally {
    client.release();
  }
});

export default router;
