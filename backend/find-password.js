import pg from 'pg';
const { Pool } = pg;

const passwords = ['postgres', 'password', 'admin', '', 'root', '123456'];

for (const pwd of passwords) {
  try {
    const pool = new Pool({
      host: 'localhost',
      port: 5432,
      database: 'postgres',
      user: 'postgres',
      password: pwd
    });
    
    await pool.query('SELECT 1');
    console.log(`✅ Found password: "${pwd}"`);
    await pool.end();
    process.exit(0);
  } catch (error) {
    console.log(`❌ Not: "${pwd}"`);
  }
}

console.log('Could not find password');
