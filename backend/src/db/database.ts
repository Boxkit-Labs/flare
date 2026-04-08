import pg from 'pg';
import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import dotenv from 'dotenv';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

dotenv.config();

const { Pool } = pg;

const defaultConnectionString = 'postgresql://postgres:postgres@localhost:5432/postgres';

if (!process.env.DATABASE_URL) {
    console.warn("WARNING: DATABASE_URL not set. Falling back to local development defaults.");
}

const pool = new Pool({
    connectionString: process.env.DATABASE_URL || defaultConnectionString,
    ssl: process.env.DATABASE_URL ? { rejectUnauthorized: false } : false
});

export const initializeDatabase = async () => {
    try {
        const tableCheck = await pool.query(`
            SELECT EXISTS (
                SELECT FROM information_schema.tables 
                WHERE table_name = 'users'
            );
        `);

        if (!tableCheck.rows[0].exists) {
            console.log('Initializing database schema for the first time...');
            const schemaPath = join(__dirname, 'schema.sql');
            const schema = readFileSync(schemaPath, 'utf8');
            await pool.query(schema);
            console.log('Database schema initialized successfully.');
        } else {
            // Existing DB: Ensure all columns from recent schema updates are present
            console.log('Checking for database schema updates...');
            
            // Add tx_type to transactions if missing
            await pool.query(`
                ALTER TABLE transactions 
                ADD COLUMN IF NOT EXISTS tx_type TEXT 
                DEFAULT 'check' 
                CHECK (tx_type IN ('check', 'verification', 'collaboration'));
            `);

            // Add error_message to watchers if missing
            await pool.query(`
                ALTER TABLE watchers 
                ADD COLUMN IF NOT EXISTS error_message TEXT;
            `);

            // Create notifications table if missing
            console.log('Ensuring notifications table exists...');
            await pool.query(`
                CREATE TABLE IF NOT EXISTS notifications (
                    notification_id TEXT PRIMARY KEY,
                    user_id TEXT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
                    title TEXT NOT NULL,
                    body TEXT NOT NULL,
                    type TEXT NOT NULL,
                    data_id TEXT,
                    read BOOLEAN DEFAULT false,
                    created_at TIMESTAMPTZ DEFAULT NOW()
                );
            `);

            await pool.query(`
                CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
            `);
            console.log('Notifications table check complete.');

            console.log('Database schema updates verified.');
        }
    } catch (error) {
        console.error('Failed to initialize database schema:', error);
        // We don't exit(1) on migration failure if it might be a 'column already exists' error 
        // that IF NOT EXISTS didn't catch, but pg is generally good with IF NOT EXISTS.
    }
};

export default pool;
