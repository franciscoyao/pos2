import pg from 'pg';
const { Pool } = pg;

const pool = new Pool({
  host: '127.0.0.1',
  port: 5433,
  database: 'pos_system',
  user: 'postgres',
  password: 'postgres'
});

try {
  const result = await pool.query('SELECT version()');
  console.log('✅ Connected successfully!');
  console.log('PostgreSQL version:', result.rows[0].version);
  await pool.end();
} catch (error) {
  console.error('❌ Connection failed:', error.message);
  process.exit(1);
}
