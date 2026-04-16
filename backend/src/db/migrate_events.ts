import db from './database.js';

async function migrate() {
  console.log('[Migration] Starting event service database migration...');

  try {
    // 1. Create event_price_history table
    console.log('[Migration] Creating event_price_history table...');
    await db.query(`
      CREATE TABLE IF NOT EXISTS event_price_history (
        history_id SERIAL PRIMARY KEY,
        watcher_id TEXT NOT NULL REFERENCES watchers(watcher_id) ON DELETE CASCADE,
        external_id TEXT NOT NULL,
        platform TEXT NOT NULL,
        tier_name TEXT NOT NULL,
        min_price REAL NOT NULL,
        max_price REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'USD',
        available INTEGER NOT NULL,
        quantity_remaining INTEGER,
        quantity_total INTEGER,
        event_status TEXT NOT NULL DEFAULT 'active',
        checked_at TIMESTAMPTZ DEFAULT NOW()
      );
    `);
    await db.query(`CREATE INDEX IF NOT EXISTS idx_event_price_history_watcher_at ON event_price_history(watcher_id, checked_at DESC);`);
    await db.query(`CREATE INDEX IF NOT EXISTS idx_event_price_history_lookup ON event_price_history(external_id, platform, tier_name, checked_at DESC);`);

    // 2. Create event_cache table
    console.log('[Migration] Creating event_cache table...');
    await db.query(`
      CREATE TABLE IF NOT EXISTS event_cache (
        external_id TEXT NOT NULL,
        platform TEXT NOT NULL,
        name TEXT NOT NULL,
        venue TEXT,
        city TEXT,
        country TEXT,
        event_date TEXT,
        image_url TEXT,
        event_url TEXT,
        is_free BOOLEAN,
        category TEXT,
        updated_at TIMESTAMPTZ DEFAULT NOW(),
        PRIMARY KEY (external_id, platform)
      );
    `);

    // 3. Update watchers table type constraint
    console.log('[Migration] Checking watchers table type constraint...');
    let isSqlite = false;
    try {
      await db.query("SELECT 1 FROM sqlite_master LIMIT 1");
      isSqlite = true;
    } catch (e) {
      isSqlite = false;
    }

    if (isSqlite) {
      console.log('[Migration] Database is SQLite, checking schema...');
      const result = await db.query("SELECT sql FROM sqlite_master WHERE type='table' AND name='watchers'");
      const sql = result.rows[0]?.sql || '';
      
      if (!sql.includes("'event'")) {
        console.log('[Migration] Updating watchers table to include "event" type...');
        
        await db.query('PRAGMA foreign_keys=OFF;');
        await db.query('BEGIN TRANSACTION;');
        await db.query('ALTER TABLE watchers RENAME TO watchers_old;');
        
        await db.query(`
          CREATE TABLE watchers (
            watcher_id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
            name TEXT NOT NULL,
            type TEXT NOT NULL CHECK (type IN ('flight','crypto','news','product','job','custom','stock','realestate','sports','event')),
            parameters TEXT NOT NULL,
            alert_conditions TEXT NOT NULL,
            check_interval_minutes INTEGER NOT NULL DEFAULT 360,
            weekly_budget_usdc REAL NOT NULL DEFAULT 0.50,
            spent_this_week_usdc REAL NOT NULL DEFAULT 0.0,
            week_start TIMESTAMPTZ DEFAULT NOW(),
            priority TEXT DEFAULT 'medium' CHECK (priority IN ('low','medium','high')),
            status TEXT DEFAULT 'active' CHECK (status IN ('active','paused_budget','paused_manual','paused_wallet','error')),
            error_message TEXT,
            last_check_at TEXT,
            next_check_at TEXT,
            total_checks INTEGER DEFAULT 0,
            total_findings INTEGER DEFAULT 0,
            total_spent_usdc REAL DEFAULT 0.0,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
          );
        `);
        
        await db.query('INSERT INTO watchers SELECT * FROM watchers_old;');
        await db.query('DROP TABLE watchers_old;');
        await db.query('CREATE INDEX IF NOT EXISTS idx_watchers_user_id ON watchers(user_id);');
        await db.query('COMMIT;');
        await db.query('PRAGMA foreign_keys=ON;');
        console.log('[Migration] watchers table updated successfully (SQLite).');
      } else {
        console.log('[Migration] watchers table already supports "event" type (SQLite).');
      }
    } else {
      console.log('[Migration] Database is PostgreSQL, checking constraints...');
      // Get the existing constraint name
      const constraintCheck = await db.query(`
        SELECT conname 
        FROM pg_constraint 
        WHERE conrelid = 'watchers'::regclass 
        AND contype = 'c' 
        AND pg_get_constraintdef(oid) LIKE '%type % IN%';
      `);

      if (constraintCheck.rows.length > 0) {
        const constraintName = constraintCheck.rows[0].conname;
        
        // Let's check if the current constraint definition already includes 'event'
        const defCheck = await db.query(`SELECT pg_get_constraintdef(oid) as def FROM pg_constraint WHERE conname = '${constraintName}'`);
        const currentDef = defCheck.rows[0].def;
        
        if (!currentDef.includes("'event'")) {
          console.log(`[Migration] Dropping old constraint ${constraintName} and adding new one...`);
          await db.query(`ALTER TABLE watchers DROP CONSTRAINT "${constraintName}"`);
          await db.query("ALTER TABLE watchers ADD CONSTRAINT checkers_type_check CHECK (type IN ('flight','crypto','news','product','job','custom','stock','realestate','sports','event'))");
          console.log('[Migration] watchers table updated successfully (PostgreSQL).');
        } else {
          console.log('[Migration] watchers table already supports "event" type (PostgreSQL).');
        }
      }
    }

    console.log('[Migration] Event module migration completed successfully.');
  } catch (error) {
    console.error('[Migration] Migration failed:', error);
    process.exit(1);
  }
}

migrate();
