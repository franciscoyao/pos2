import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const { Pool } = pg;

const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'pos_system',
  user: 'postgres',
  password: '1111'
});

pool.on('error', (err) => {
  console.error('Unexpected database error:', err);
});

export default pool;
