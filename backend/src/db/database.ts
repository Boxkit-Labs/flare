import pg from "pg";
// sqlite3 removed from top-level to avoid GLIBC errors on Render
import { promisify } from "node:util";
import { readFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import dotenv from "dotenv";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

dotenv.config();

const { Pool } = pg;
const defaultConnectionString =
  "postgresql://postgres:postgres@localhost:5432/postgres";

let pool: any;
let isSqlite = false;

// ─────────────────────────────────────────────────────────────────────────────
// Database Initialization
// ─────────────────────────────────────────────────────────────────────────────

async function getPool() {
  if (pool) return pool;

  try {
    console.log("[Database] Attempting PostgreSQL connection...");
    const p = new Pool({
      connectionString: process.env.DATABASE_URL || defaultConnectionString,
      ssl: process.env.DATABASE_URL ? { rejectUnauthorized: false } : false,
      connectionTimeoutMillis: 10000,
    });

    // Test connection immediately
    await p.query("SELECT 1");
    console.log("[Database] Connected to PostgreSQL.");

    p.on("error", (err: any) =>
      console.error("[Database] Postgres Pool Error:", err),
    );
    pool = p;
    return pool;
  } catch (e: any) {
    console.warn(
      `[Database] PostgreSQL connection failed: ${e.message}. Falling back to SQLite.`,
    );
    isSqlite = true;
    const { default: sqlite3 } = await import("sqlite3");

    const dbPath = process.env.DB_PATH || "flare.sqlite";
    const db = new sqlite3.Database(dbPath);

    // Promisify sqlite methods
    const run = promisify(db.run.bind(db)) as any;
    const all = promisify(db.all.bind(db)) as any;
    const get = promisify(db.get.bind(db)) as any;
    const exec = promisify(db.exec.bind(db)) as any;

    console.log(`[Database] Connected to SQLite at ${dbPath}`);

    pool = {
      isSqlite: true,
      query: async (text: string, params?: any[]) => {
        const sql = text
          .replace(/\$(\d+)/g, "?")
          .replace(/TIMESTAMPTZ/g, "TEXT")
          .replace(/NOW\(\)/g, "CURRENT_TIMESTAMP")
          .replace(/SERIAL PRIMARY KEY/g, "INTEGER PRIMARY KEY AUTOINCREMENT");

        try {
          if (sql.includes(';') && (sql.match(/;/g) || []).length > 1) {
            // Multi-statement query (e.g. schema loading)
            await exec(sql);
            return { rows: [], rowCount: 1 };
          } else if (sql.trim().toUpperCase().startsWith("SELECT")) {
            const rows = (await all(sql, params || [])) as any[];
            return { rows, rowCount: rows.length };
          } else {
            await run(sql, params || []);
            return { rows: [], rowCount: 1 };
          }
        } catch (err: any) {
          // Silently ignore 'already exists' errors during migration fallbacks
          if (
            err.message.includes("already exists") ||
            err.message.includes("duplicate column")
          ) {
            return { rows: [], rowCount: 0 };
          }
          throw err;
        }
      },
      on: () => {},
      end: async () => new Promise((resolve) => db.close(() => resolve(null))),
    };
    return pool;
  }
}

export const initializeDatabase = async () => {
  const p = await getPool();
  try {
    let exists = false;
    if (p.isSqlite) {
      const tableCheck = await p.query(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='users'",
      );
      exists = tableCheck.rows.length > 0;
    } else {
      const tableCheck = await p.query(`
                SELECT EXISTS (
                    SELECT FROM information_schema.tables 
                    WHERE table_name = 'users'
                );
            `);
      exists = tableCheck.rows[0].exists;
    }

    if (!exists) {
      console.log("Initializing database schema for the first time...");
      const schemaPath = join(__dirname, "schema.sql");
      const schema = readFileSync(schemaPath, "utf8");
      await p.query(schema);
      console.log("Database schema initialized successfully.");
    } else {
      console.log("Database schema already exists.");
    }
  } catch (error) {
    console.error("Failed to initialize database schema:", error);
  }
};

export default {
  query: async (text: string, params?: any[]) => {
    const p = await getPool();
    return p.query(text, params);
  },
  end: async () => {
    const p = await getPool();
    if (p && typeof p.end === 'function') {
      return p.end();
    }
  }
};
