import express from 'express';
import { body, validationResult } from 'express-validator';
import pool from '../database/db.js';
import { authenticate, authorize } from '../middleware/auth.js';

const router = express.Router();

// Get all categories
router.get('/categories', authenticate, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM categories WHERE active = true ORDER BY display_order, name'
    );
    res.json(result.rows);
  } catch (error) {
    console.error('Get categories error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Create category
router.post('/categories', authenticate, authorize('admin'), [
  body('name').notEmpty()
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  const { name, description, display_order } = req.body;

  try {
    const result = await pool.query(
      'INSERT INTO categories (name, description, display_order) VALUES ($1, $2, $3) RETURNING *',
      [name, description || null, display_order || 0]
    );
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Create category error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Update category
router.put('/categories/:id', authenticate, authorize('admin'), async (req, res) => {
  const { id } = req.params;
  const { name, description, display_order, active } = req.body;

  try {
    const result = await pool.query(
      'UPDATE categories SET name = $1, description = $2, display_order = $3, active = $4 WHERE id = $5 RETURNING *',
      [name, description, display_order, active, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Category not found' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Update category error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get all menu items
router.get('/items', authenticate, async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT mi.*, c.name as category_name 
      FROM menu_items mi
      LEFT JOIN categories c ON mi.category_id = c.id
      WHERE mi.available = true
      ORDER BY c.display_order, mi.name
    `);
    res.json(result.rows);
  } catch (error) {
    console.error('Get menu items error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Create menu item
router.post('/items', authenticate, authorize('admin'), [
  body('name').notEmpty(),
  body('price').isFloat({ min: 0 })
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  const { category_id, name, description, price, station, image_url } = req.body;

  try {
    const result = await pool.query(
      'INSERT INTO menu_items (category_id, name, description, price, station, image_url) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
      [category_id || null, name, description || null, price, station || null, image_url || null]
    );
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Create menu item error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Update menu item
router.put('/items/:id', authenticate, authorize('admin'), async (req, res) => {
  const { id } = req.params;
  const { category_id, name, description, price, station, image_url, available } = req.body;

  try {
    const result = await pool.query(
      'UPDATE menu_items SET category_id = $1, name = $2, description = $3, price = $4, station = $5, image_url = $6, available = $7, updated_at = CURRENT_TIMESTAMP WHERE id = $8 RETURNING *',
      [category_id, name, description, price, station, image_url, available, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Menu item not found' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Update menu item error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Delete menu item
router.delete('/items/:id', authenticate, authorize('admin'), async (req, res) => {
  const { id } = req.params;

  try {
    const result = await pool.query('DELETE FROM menu_items WHERE id = $1 RETURNING id', [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Menu item not found' });
    }

    res.json({ message: 'Menu item deleted successfully' });
  } catch (error) {
    console.error('Delete menu item error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
