const { Client } = require('pg');
const client = new Client({
  user: 'postgres',
  host: 'localhost',
  database: 'pos_db',
  password: '1234',
  port: 5433,
});
client.connect()
  .then(() => {
    console.log('Connected successfully with postgres user');
    process.exit(0);
  })
  .catch(err => {
    console.error('Connection error', err.stack);
    process.exit(1);
  });
