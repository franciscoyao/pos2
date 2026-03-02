import express from 'express';
import pool from '../database/db.js';
import { authenticate } from '../middleware/auth.js';

const router = express.Router();

// Get all tables
router.get('/', authenticate, async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT t.*, o.id as current_order_id, o.status as order_status
      FROM tables t
      LEFT JOIN orders o ON t.table_number = o.table_number 
        AND o.status NOT IN ('paid', 'cancelled', 'completed')
      ORDER BY t.table_number
    `);
    res.json(result.rows);
  } catch (error) {
    console.error('Get tables error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get table status
router.get('/:table_number/status', authenticate, async (req, res) => {
  const { table_number } = req.params;

  try {
    const ordersResult = await pool.query(`
      SELECT o.*, u.name as waiter_name
      FROM orders o
      LEFT JOIN users u ON o.waiter_id = u.id
      WHERE o.table_number = $1 AND o.status NOT IN ('paid', 'cancelled', 'completed')
      ORDER BY o.created_at DESC
    `, [table_number]);

    if (ordersResult.rows.length === 0) {
      return res.json({ status: 'available', orders: [] });
    }

    const orders = [];
    for (const order of ordersResult.rows) {
      const itemsResult = await pool.query(`
        SELECT oi.*, mi.name as menu_item_name, mi.station
        FROM order_items oi
        JOIN menu_items mi ON oi.menu_item_id = mi.id
        WHERE oi.order_id = $1
        ORDER BY oi.created_at
      `, [order.id]);

      orders.push({
        ...order,
        items: itemsResult.rows
      });
    }

    res.json({ status: 'occupied', orders });
  } catch (error) {
    console.error('Get table status error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Create table
router.post('/', authenticate, async (req, res) => {
  const { table_number, capacity } = req.body;

  try {
    const result = await pool.query(
      'INSERT INTO tables (table_number, capacity) VALUES ($1, $2) RETURNING *',
      [table_number, capacity || 4]
    );
    res.status(201).json(result.rows[0]);
  } catch (error) {
    if (error.code === '23505') {
      return res.status(400).json({ error: 'Table number already exists' });
    }
    console.error('Create table error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Update table
router.put('/:id', authenticate, async (req, res) => {
  const { id } = req.params;
  const { table_number, capacity, status } = req.body;

  try {
    const result = await pool.query(
      'UPDATE tables SET table_number = $1, capacity = $2, status = $3 WHERE id = $4 RETURNING *',
      [table_number, capacity, status, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Table not found' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Update table error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Delete table
router.delete('/:id', authenticate, async (req, res) => {
  const { id } = req.params;

  try {
    const result = await pool.query('DELETE FROM tables WHERE id = $1 RETURNING id', [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Table not found' });
    }

    res.json({ message: 'Table deleted successfully' });
  } catch (error) {
    console.error('Delete table error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
