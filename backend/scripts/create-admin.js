import bcrypt from 'bcryptjs';
import pool from '../src/database/db.js';

async function createAdmin() {
  try {
    const email = 'admin@pos.com';
    const password = 'admin123';
    const passwordHash = await bcrypt.hash(password, 10);

    await pool.query(
      `INSERT INTO users (email, password_hash, name, role) 
       VALUES ($1, $2, $3, $4) 
       ON CONFLICT (email) DO UPDATE 
       SET password_hash = $2`,
      [email, passwordHash, 'Admin User', 'admin']
    );

    console.log('✅ Admin user created/updated successfully');
    console.log('Email:', email);
    console.log('Password:', password);
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

createAdmin();
