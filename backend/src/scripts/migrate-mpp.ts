import { Pool } from 'pg';
import 'dotenv/config';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://postgres:postgres@localhost:5432/flare_db',
  ssl: process.env.DATABASE_URL ? { rejectUnauthorized: false } : false,
});

async function runMigration() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    await client.query(`
      CREATE TABLE IF NOT EXISTS mpp_channels (
        id SERIAL PRIMARY KEY,
        channel_id VARCHAR(255) NOT NULL UNIQUE,
        funder_address VARCHAR(255) NOT NULL,
        recipient_address VARCHAR(255) NOT NULL,
        commitment_pubkey VARCHAR(255) NOT NULL,
        commitment_secret VARCHAR(255) NOT NULL,
        cumulative_amount BIGINT NOT NULL DEFAULT 0,
        latest_signature TEXT,
        status VARCHAR(50) NOT NULL DEFAULT 'open',
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      )
    `);

    console.log('Successfully created mpp_channels table.');
    await client.query('COMMIT');
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Failed to run migration:', error);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

runMigration();
