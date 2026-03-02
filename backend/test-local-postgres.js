import pg from 'pg';
const { Pool } = pg;

const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'postgres',
  user: 'postgres',
  password: '1111'
});

try {
  const result = await pool.query('SELECT version()');
  console.log('✅ Connected successfully with password "1111"!');
  console.log('PostgreSQL version:', result.rows[0].version);
  
  // Try to create the pos_system database
  try {
    await pool.query('CREATE DATABASE pos_system');
    console.log('✅ Database "pos_system" created!');
  } catch (err) {
    if (err.code === '42P04') {
      console.log('✅ Database "pos_system" already exists');
    } else {
      console.log('⚠️  Could not create database:', err.message);
    }
  }
  
  await pool.end();
} catch (error) {
  console.error('❌ Connection failed:', error.message);
  process.exit(1);
}
