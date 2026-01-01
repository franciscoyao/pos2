const { Client } = require('pg');

const client = new Client({
  host: 'localhost',
  port: 5432,
  user: 'postgres',
  password: '1111',
  database: 'postgres', // Connect to default database
});

async function createDatabase() {
  try {
    await client.connect();
    console.log('Connected to postgres database');

    const res = await client.query("SELECT 1 FROM pg_database WHERE datname = 'pos_db'");
    if (res.rowCount === 0) {
      console.log('Creating pos_db database...');
      await client.query('CREATE DATABASE pos_db');
      console.log('Database pos_db created successfully');
    } else {
      console.log('Database pos_db already exists');
    }
  } catch (err) {
    console.error('Error creating database:', err);
  } finally {
    await client.end();
  }
}

createDatabase();
