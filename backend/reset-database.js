import pg from 'pg';
const { Pool } = pg;

// Connect to postgres database to drop/create pos_system
const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'postgres',
  user: 'postgres',
  password: '1111'
});

try {
  console.log('Dropping existing database...');
  await pool.query('DROP DATABASE IF EXISTS pos_system');
  console.log('✅ Database dropped');
  
  console.log('Creating fresh database...');
  await pool.query('CREATE DATABASE pos_system');
  console.log('✅ Database created');
  
  await pool.end();
  console.log('\nNow run: npm run migrate');
} catch (error) {
  console.error('❌ Error:', error.message);
  process.exit(1);
}
