import pool from './database.js';

async function migrate() {
  console.log('Starting migration: adding tx_type to transactions table...');
  try {
    await pool.query(`
      ALTER TABLE transactions
      ADD COLUMN IF NOT EXISTS tx_type TEXT
      DEFAULT 'check'
      CHECK (tx_type IN ('check', 'verification', 'collaboration'));
    `);
    console.log('SUCCESS: tx_type column added or already exists.');

    await pool.query(`
      ALTER TABLE watchers
      ADD COLUMN IF NOT EXISTS error_message TEXT;
    `);
    console.log('SUCCESS: watchers.error_message verified.');

  } catch (err) {
    console.error('Migration failed:', err);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

migrate();
