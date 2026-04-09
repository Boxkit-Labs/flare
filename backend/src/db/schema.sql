-- Flare Backend SQLite Schema

-- Users table
CREATE TABLE IF NOT EXISTS users (
  user_id TEXT PRIMARY KEY,
  device_id TEXT UNIQUE NOT NULL,
  stellar_public_key TEXT NOT NULL,
  stellar_secret_key_encrypted TEXT NOT NULL,
  fcm_token TEXT,
  briefing_time TEXT DEFAULT '07:00',
  timezone TEXT DEFAULT 'UTC',
  dnd_start TEXT DEFAULT '23:00',
  dnd_end TEXT DEFAULT '07:00',
  global_daily_cap REAL,
  ghost_score INTEGER DEFAULT 0,
  ghost_rank TEXT DEFAULT 'Novice',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Watchers table
CREATE TABLE IF NOT EXISTS watchers (
  watcher_id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('flight','crypto','news','product','job','custom','stock','realestate','sports')),
  parameters TEXT NOT NULL, -- JSON string
  alert_conditions TEXT NOT NULL, -- JSON string
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

-- Checks table
CREATE TABLE IF NOT EXISTS checks (
  check_id TEXT PRIMARY KEY,
  watcher_id TEXT NOT NULL REFERENCES watchers(watcher_id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  service_name TEXT NOT NULL,
  request_payload TEXT, -- JSON
  response_data TEXT, -- JSON
  cost_usdc REAL NOT NULL,
  stellar_tx_hash TEXT,
  finding_detected BOOLEAN DEFAULT false,
  finding_id TEXT,
  agent_reasoning TEXT,
  checked_at TIMESTAMPTZ DEFAULT NOW()
);

-- Findings table
CREATE TABLE IF NOT EXISTS findings (
  finding_id TEXT PRIMARY KEY,
  watcher_id TEXT NOT NULL REFERENCES watchers(watcher_id) ON DELETE CASCADE,
  check_id TEXT NOT NULL REFERENCES checks(check_id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  headline TEXT NOT NULL,
  detail TEXT,
  data TEXT, -- JSON
  action_url TEXT,
  cost_usdc REAL NOT NULL,
  stellar_tx_hash TEXT,
  read BOOLEAN DEFAULT false,
  notified BOOLEAN DEFAULT false,
  verified BOOLEAN DEFAULT false,
  verification_tx_hash TEXT,
  verification_check_id TEXT,
  collaboration_result TEXT, -- JSON
  confidence_score INTEGER DEFAULT 0,
  confidence_tier TEXT,
  found_at TIMESTAMPTZ DEFAULT NOW()
);

-- Briefings table
CREATE TABLE IF NOT EXISTS briefings (
  briefing_id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  date TEXT NOT NULL,
  period_start TEXT NOT NULL,
  period_end TEXT NOT NULL,
  total_checks INTEGER DEFAULT 0,
  total_findings INTEGER DEFAULT 0,
  total_cost_usdc REAL DEFAULT 0.0,
  findings_json TEXT, -- JSON array of IDs
  watcher_summaries_json TEXT, -- JSON
  generated_summary TEXT,
  read BOOLEAN DEFAULT false,
  generated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Transactions table
CREATE TABLE IF NOT EXISTS transactions (
  tx_id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  watcher_id TEXT NOT NULL,
  check_id TEXT,
  amount_usdc REAL NOT NULL,
  service_name TEXT NOT NULL,
  stellar_tx_hash TEXT NOT NULL,
  tx_type TEXT DEFAULT 'check' CHECK (tx_type IN ('check', 'verification', 'collaboration')),
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- Optimization Indexes
CREATE INDEX IF NOT EXISTS idx_watchers_user_id ON watchers(user_id);
CREATE INDEX IF NOT EXISTS idx_checks_watcher_id ON checks(watcher_id);
CREATE INDEX IF NOT EXISTS idx_findings_user_id ON findings(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON transactions(user_id);

-- Notifications table
CREATE TABLE IF NOT EXISTS notifications (
  notification_id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  type TEXT NOT NULL, -- 'finding', 'briefing', 'budget_warning', 'low_balance', etc.
  data_id TEXT,       -- optional link to specific finding/briefing/watcher
  read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);

-- MPP Channels table
CREATE TABLE IF NOT EXISTS mpp_channels (
  channel_id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  service_id TEXT NOT NULL,
  sender_address TEXT NOT NULL,
  receiver_address TEXT NOT NULL,
  commitment_public_key TEXT,
  commitment_secret_key_encrypted TEXT,
  deposit_usdc REAL NOT NULL,
  spent_usdc REAL NOT NULL DEFAULT 0,
  latest_proof TEXT,
  open_tx_hash TEXT NOT NULL,
  opened_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  status TEXT DEFAULT 'open' CHECK (status IN ('open', 'closed', 'expired')),
  close_tx_hash TEXT
);
