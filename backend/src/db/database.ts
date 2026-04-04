import Database from 'better-sqlite3';
import { readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import dotenv from 'dotenv';

dotenv.config();

/**
 * Singleton database instance initialization.
 * Configures the database path from .env (DB_PATH) or defaults to 'flare.sqlite'.
 */
const dbPath = process.env.DB_PATH || 'flare.sqlite';
const db = new Database(dbPath, { verbose: console.log });

// Enable foreign key constraints
db.pragma('foreign_keys = ON');

/**
 * Checks for the existence of core tables. 
 * If 'users' doesn't exist, it assumes the database is uninitialized and runs schema.sql.
 */
const initializeDatabase = () => {
    const tableCheck = db.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name='users'").get();

    if (!tableCheck) {
        console.log('Initializing database schema for the first time...');
        try {
            const schemaPath = join(__dirname, 'schema.sql');
            const schema = readFileSync(schemaPath, 'utf8');
            db.exec(schema);
            console.log('Database schema initialized successfully.');
        } catch (error) {
            console.error('Failed to initialize database schema:', error);
            process.exit(1);
        }
    }
};

initializeDatabase();

export default db;
