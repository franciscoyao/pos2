import express from 'express';
import pool from '../database/db.js';
import { authenticate } from '../middleware/auth.js';

const router = express.Router();

// Get report statistics for a date range
router.get('/stats', authenticate, async (req, res) => {
  try {
    const { start, end } = req.query;
    
    if (!start || !end) {
      return res.status(400).json({ error: 'Start and end dates are required' });
    }

    // Get total sales and order count
    const salesResult = await pool.query(
      `SELECT 
        COALESCE(SUM(total_amount), 0) as total_sales,
        COUNT(*) as total_orders,
        COALESCE(AVG(total_amount), 0) as avg_order_value
      FROM orders 
      WHERE status = 'paid' 
        AND created_at >= $1 
        AND created_at <= $2`,
      [start, end]
    );

    // Get average wait time (time from order creation to completion)
    const waitTimeResult = await pool.query(
      `SELECT 
        COALESCE(AVG(EXTRACT(EPOCH FROM (updated_at - created_at))), 0) as avg_wait_seconds
      FROM orders 
      WHERE status IN ('paid', 'completed')
        AND created_at >= $1 
        AND created_at <= $2`,
      [start, end]
    );

    const stats = salesResult.rows[0];
    const avgWaitSeconds = parseFloat(waitTimeResult.rows[0].avg_wait_seconds);

    res.json({
      totalSales: parseFloat(stats.total_sales),
      totalOrders: parseInt(stats.total_orders),
      avgOrderValue: parseFloat(stats.avg_order_value),
      avgWaitTime: Math.round(avgWaitSeconds) // in seconds
    });
  } catch (error) {
    console.error('Error fetching report stats:', error);
    res.status(500).json({ error: 'Failed to fetch report statistics' });
  }
});

// Get sales by day
router.get('/sales-by-day', authenticate, async (req, res) => {
  try {
    const { start, end } = req.query;
    
    if (!start || !end) {
      return res.status(400).json({ error: 'Start and end dates are required' });
    }

    const result = await pool.query(
      `SELECT 
        DATE(created_at) as date,
        COALESCE(SUM(total_amount), 0) as total_sales,
        COUNT(*) as order_count
      FROM orders 
      WHERE status = 'paid'
        AND created_at >= $1 
        AND created_at <= $2
      GROUP BY DATE(created_at)
      ORDER BY date ASC`,
      [start, end]
    );

    res.json(result.rows.map(row => ({
      date: row.date,
      totalSales: parseFloat(row.total_sales),
      orderCount: parseInt(row.order_count)
    })));
  } catch (error) {
    console.error('Error fetching sales by day:', error);
    res.status(500).json({ error: 'Failed to fetch sales by day' });
  }
});

// Get sales by category
router.get('/sales-by-category', authenticate, async (req, res) => {
  try {
    const { start, end } = req.query;
    
    if (!start || !end) {
      return res.status(400).json({ error: 'Start and end dates are required' });
    }

    // Get total sales for percentage calculation
    const totalResult = await pool.query(
      `SELECT COALESCE(SUM(oi.price * oi.quantity), 0) as total
      FROM order_items oi
      JOIN orders o ON oi.order_id = o.id
      WHERE o.status = 'paid'
        AND o.created_at >= $1 
        AND o.created_at <= $2`,
      [start, end]
    );

    const totalSales = parseFloat(totalResult.rows[0].total);

    // Get sales by category
    const result = await pool.query(
      `SELECT 
        c.name as category_name,
        COALESCE(SUM(oi.price * oi.quantity), 0) as total_sales
      FROM order_items oi
      JOIN orders o ON oi.order_id = o.id
      JOIN menu_items mi ON oi.menu_item_id = mi.id
      JOIN categories c ON mi.category_id = c.id
      WHERE o.status = 'paid'
        AND o.created_at >= $1 
        AND o.created_at <= $2
      GROUP BY c.id, c.name
      ORDER BY total_sales DESC`,
      [start, end]
    );

    res.json(result.rows.map(row => {
      const sales = parseFloat(row.total_sales);
      return {
        categoryName: row.category_name,
        totalSales: sales,
        percentage: totalSales > 0 ? (sales / totalSales) * 100 : 0
      };
    }));
  } catch (error) {
    console.error('Error fetching sales by category:', error);
    res.status(500).json({ error: 'Failed to fetch sales by category' });
  }
});

// Get top selling items
router.get('/top-selling-items', authenticate, async (req, res) => {
  try {
    const { limit = 5, orderType } = req.query;

    let query = `
      SELECT 
        mi.name,
        mi.price,
        COUNT(oi.id) as count,
        SUM(oi.price * oi.quantity) as total_revenue,
        'available' as status
      FROM order_items oi
      JOIN orders o ON oi.order_id = o.id
      JOIN menu_items mi ON oi.menu_item_id = mi.id
      WHERE o.status = 'paid'
    `;

    const params = [];
    
    if (orderType) {
      query += ` AND o.order_type = $1`;
      params.push(orderType);
    }

    query += `
      GROUP BY mi.id, mi.name, mi.price
      ORDER BY count DESC
      LIMIT $${params.length + 1}
    `;
    params.push(parseInt(limit));

    const result = await pool.query(query, params);

    res.json(result.rows.map(row => ({
      name: row.name,
      price: parseFloat(row.price),
      count: parseInt(row.count),
      totalRevenue: parseFloat(row.total_revenue),
      status: row.status
    })));
  } catch (error) {
    console.error('Error fetching top selling items:', error);
    res.status(500).json({ error: 'Failed to fetch top selling items' });
  }
});

// Get revenue summary
router.get('/revenue-summary', authenticate, async (req, res) => {
  try {
    const { period = 'today' } = req.query;
    
    let startDate, endDate;
    const now = new Date();
    
    switch (period) {
      case 'today':
        startDate = new Date(now.setHours(0, 0, 0, 0));
        endDate = new Date(now.setHours(23, 59, 59, 999));
        break;
      case 'week':
        startDate = new Date(now.setDate(now.getDate() - 7));
        endDate = new Date();
        break;
      case 'month':
        startDate = new Date(now.setMonth(now.getMonth() - 1));
        endDate = new Date();
        break;
      default:
        startDate = new Date(now.setHours(0, 0, 0, 0));
        endDate = new Date(now.setHours(23, 59, 59, 999));
    }

    const result = await pool.query(
      `SELECT 
        COALESCE(SUM(total_amount), 0) as total_revenue,
        COUNT(*) as order_count,
        COALESCE(AVG(total_amount), 0) as avg_order_value
      FROM orders 
      WHERE status = 'paid'
        AND created_at >= $1 
        AND created_at <= $2`,
      [startDate, endDate]
    );

    const row = result.rows[0];
    res.json({
      period,
      totalRevenue: parseFloat(row.total_revenue),
      orderCount: parseInt(row.order_count),
      avgOrderValue: parseFloat(row.avg_order_value),
      startDate,
      endDate
    });
  } catch (error) {
    console.error('Error fetching revenue summary:', error);
    res.status(500).json({ error: 'Failed to fetch revenue summary' });
  }
});

export default router;
