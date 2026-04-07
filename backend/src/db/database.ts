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
        }
    } catch (error) {
        console.error('Failed to initialize database schema:', error);
        process.exit(1);
    }
};

export default pool;
