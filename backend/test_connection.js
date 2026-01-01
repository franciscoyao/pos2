const { Client } = require('pg');

const client = new Client({
  host: 'localhost',
  port: 5432,
  user: 'postgres',
  password: '1111',
  database: 'pos_db',
});

async function checkConnection() {
  try {
    await client.connect();
    console.log('✅ Successfully connected to PostgreSQL database "pos_db"');
    
    const res = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
      ORDER BY table_name;
    `);
    
    console.log('\nFound the following tables:');
    if (res.rows.length === 0) {
      console.log('No tables found (TypeORM might still be synchronizing)');
    } else {
      res.rows.forEach(row => console.log(`- ${row.table_name}`));
    }
    
  } catch (err) {
    console.error('❌ Connection failed:', err);
  } finally {
    await client.end();
  }
}

checkConnection();
