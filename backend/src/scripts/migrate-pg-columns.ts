import { Pool } from 'pg';
import 'dotenv/config';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

async function migrate() {
  const client = await pool.connect();
  try {
    console.log('Starting PostgreSQL column migration...');
    
    // Add columns to checks table
    await client.query(`
      ALTER TABLE checks 
      ADD COLUMN IF NOT EXISTS payment_method TEXT DEFAULT 'x402',
      ADD COLUMN IF NOT EXISTS channel_id TEXT;
    `);
    console.log('Updated checks table.');

    // Add columns to transactions table
    await client.query(`
      ALTER TABLE transactions 
      ADD COLUMN IF NOT EXISTS payment_method TEXT DEFAULT 'x402',
      ADD COLUMN IF NOT EXISTS channel_id TEXT;
    `);
    console.log('Updated transactions table.');

    console.log('Migration completed successfully.');
  } catch (err: any) {
    console.error('Migration failed:', err.message);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

migrate();
