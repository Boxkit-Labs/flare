import pool from './database.js';

async function migrate() {
  console.log('Starting migration: adding finding verification columns...');
  try {
    const queries = [
      `ALTER TABLE findings ADD COLUMN IF NOT EXISTS verified BOOLEAN DEFAULT false;`,
      `ALTER TABLE findings ADD COLUMN IF NOT EXISTS verification_tx_hash TEXT;`,
      `ALTER TABLE findings ADD COLUMN IF NOT EXISTS verification_check_id TEXT;`,
      `ALTER TABLE findings ADD COLUMN IF NOT EXISTS collaboration_result TEXT;`,
      `ALTER TABLE findings ADD COLUMN IF NOT EXISTS confidence_score INTEGER DEFAULT 0;`,
      `ALTER TABLE findings ADD COLUMN IF NOT EXISTS confidence_tier TEXT;`
    ];

    for (const q of queries) {
      await pool.query(q);
    }
    
    console.log('SUCCESS: findings table successfully migrated.');
  } catch (err: any) {
    // If using SQLite, ignore "duplicate column name"
    if (err.message.includes('duplicate column')) {
      console.log('SUCCESS: columns already existed (SQLite).');
    } else {
      console.error('Migration failed:', err);
      process.exit(1);
    }
  } finally {
    await pool.end();
  }
}

migrate();
