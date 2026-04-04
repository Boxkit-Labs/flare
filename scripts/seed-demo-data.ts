import Database from 'better-sqlite3';
import { randomUUID, randomBytes } from 'node:crypto';
import { join } from 'node:path';
import { readFileSync, existsSync } from 'node:fs';

const DB_PATH = join(process.cwd(), 'backend', 'flare.sqlite');
const SCHEMA_PATH = join(process.cwd(), 'backend', 'src', 'db', 'schema.sql');

const db = new Database(DB_PATH);

// Enable foreign keys
db.pragma('foreign_keys = ON');

function initializeDatabase() {
    const tableCheck = db.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name='users'").get();
    if (!tableCheck) {
        console.log('Initializing database schema...');
        const schema = readFileSync(SCHEMA_PATH, 'utf8');
        db.exec(schema);
        console.log('Database schema initialized successfully.');
    }
}

function generateStellarHash() {
    return randomBytes(32).toString('hex').toUpperCase();
}

const DEMO_USER_ID = 'demo-user-1';
const DEMO_DEVICE_ID = 'demo-device-1';

async function seed() {
    console.log('--- Flare Demo Seeding ---');
    initializeDatabase();
    
    // 0. Clean old demo data
    db.prepare('DELETE FROM users WHERE user_id = ?').run(DEMO_USER_ID);

    // 1. Create Demo User
    db.prepare(`
        INSERT INTO users (user_id, device_id, stellar_public_key, stellar_secret_key_encrypted, briefing_time, timezone)
        VALUES (?, ?, ?, ?, ?, ?)
    `).run(
        DEMO_USER_ID, 
        DEMO_DEVICE_ID, 
        'GDEMO' + randomBytes(24).toString('hex').toUpperCase().substring(0, 51),
        'SDEMO_ENCRYPTED_SECRET',
        '08:00',
        'UTC'
    );
    console.log('Demo user created.');

    let totalSpent = 0;
    let totalChecks = 0;
    let totalFindings = 0;

    const now = new Date();

    // --- Watcher 1: Tokyo Flights ---
    const watcher1Id = 'watcher-tokyo';
    const w1CreateDate = new Date(now.getTime() - 5 * 24 * 60 * 60 * 1000);
    db.prepare(`
        INSERT INTO watchers (watcher_id, user_id, name, type, parameters, alert_conditions, check_interval_minutes, weekly_budget_usdc, status, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
        watcher1Id, DEMO_USER_ID, 'Tokyo Flights', 'flight',
        JSON.stringify({ from: 'SFO', to: 'HND' }),
        JSON.stringify({ price_below: 800 }),
        360, 5.0, 'active', w1CreateDate.toISOString()
    );

    const prices = [1247, 1230, 1198, 1210, 1189, 1195, 1150, 1120, 1089, 1050, 1020, 950, 920, 870, 890, 860, 840, 820, 810, 789];
    for (let i = 0; i < prices.length; i++) {
        const checkId = randomUUID();
        const checkTime = new Date(w1CreateDate.getTime() + i * 6 * 60 * 60 * 1000);
        const cost = 0.008;
        const isFinding = i === prices.length - 1; // Last one is finding
        const txHash = generateStellarHash();

        db.prepare(`
            INSERT INTO checks (check_id, watcher_id, user_id, service_name, request_payload, response_data, cost_usdc, stellar_tx_hash, finding_detected, agent_reasoning, checked_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `).run(
            checkId, watcher1Id, DEMO_USER_ID, 'FlightService',
            JSON.stringify({}), JSON.stringify({ price: prices[i] }),
            cost, txHash, isFinding ? 1 : 0, 
            `Analyzing flight prices for SFO -> HND. Current price: $${prices[i]}. ${isFinding ? 'Target threshold $800 reached!' : 'Waiting for further drops.'}`, 
            checkTime.toISOString()
        );

        db.prepare(`
            INSERT INTO transactions (tx_id, user_id, watcher_id, check_id, amount_usdc, service_name, stellar_tx_hash, timestamp)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        `).run(randomUUID(), DEMO_USER_ID, watcher1Id, checkId, cost, 'FlightService', txHash, checkTime.toISOString());

        if (isFinding) {
            const findingId = randomUUID();
            db.prepare(`
                INSERT INTO findings (finding_id, watcher_id, check_id, user_id, type, headline, detail, data, cost_usdc, stellar_tx_hash, found_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            `).run(
                findingId, watcher1Id, checkId, DEMO_USER_ID, 'flight',
                'Price drop for Tokyo!', `Price found at $${prices[i]} which is below your $800 threshold.`,
                JSON.stringify({ price: prices[i] }), 0.0, txHash, checkTime.toISOString()
            );
            totalFindings++;
        }

        totalSpent += cost;
        totalChecks++;
    }
    console.log('- Tokyo Flights seeded (20 checks, 1 finding)');

    // --- Watcher 2: Crypto Watch ---
    const watcher2Id = 'watcher-crypto';
    const w2CreateDate = new Date(now.getTime() - 3 * 24 * 60 * 60 * 1000);
    db.prepare(`
        INSERT INTO watchers (watcher_id, user_id, name, type, parameters, alert_conditions, check_interval_minutes, weekly_budget_usdc, status, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
        watcher2Id, DEMO_USER_ID, 'Crypto Watch', 'crypto',
        JSON.stringify({ assets: ['ETH', 'XLM'] }),
        JSON.stringify({ eth_spike: 5 }),
        60, 10.0, 'active', w2CreateDate.toISOString()
    );

    for (let i = 0; i < 72; i++) {
        const checkId = randomUUID();
        const checkTime = new Date(w2CreateDate.getTime() + i * 1 * 60 * 60 * 1000);
        const cost = 0.003;
        const ethPrice = 3100 + Math.random() * 200;
        const xlmPrice = 0.13 + Math.random() * 0.02;
        const isFinding = i === 45; // Arbitrary finding at hour 45
        if (isFinding) totalFindings++;
        const txHash = generateStellarHash();

        db.prepare(`
            INSERT INTO checks (check_id, watcher_id, user_id, service_name, request_payload, response_data, cost_usdc, stellar_tx_hash, finding_detected, agent_reasoning, checked_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `).run(
            checkId, watcher2Id, DEMO_USER_ID, 'CryptoService',
            JSON.stringify({}), JSON.stringify({ eth: isFinding ? 3500 : ethPrice, xlm: xlmPrice }),
            cost, txHash, isFinding ? 1 : 0, 
            `Monitoring ETH and XLM. Prices stable. ${isFinding ? 'ETH Spiked!' : ''}`, 
            checkTime.toISOString()
        );

        db.prepare(`
            INSERT INTO transactions (tx_id, user_id, watcher_id, check_id, amount_usdc, service_name, stellar_tx_hash, timestamp)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        `).run(randomUUID(), DEMO_USER_ID, watcher2Id, checkId, cost, 'CryptoService', txHash, checkTime.toISOString());

        if (isFinding) {
            db.prepare(`
                INSERT INTO findings (finding_id, watcher_id, check_id, user_id, type, headline, detail, data, cost_usdc, stellar_tx_hash, found_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            `).run(
                randomUUID(), watcher2Id, checkId, DEMO_USER_ID, 'crypto',
                'ETH Volatility Alert', 'ETH price spiked 12% in the last hour.',
                JSON.stringify({ eth: 3500 }), 0.0, txHash, checkTime.toISOString()
            );
        }

        totalSpent += cost;
        totalChecks++;
    }
    console.log('- Crypto Watch seeded (72 checks, 1 finding)');

    // --- Watcher 3: Stellar News ---
    const watcher3Id = 'watcher-news';
    const w3CreateDate = new Date(now.getTime() - 4 * 24 * 60 * 60 * 1000);
    db.prepare(`
        INSERT INTO watchers (watcher_id, user_id, name, type, parameters, alert_conditions, check_interval_minutes, weekly_budget_usdc, status, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
        watcher3Id, DEMO_USER_ID, 'Stellar News', 'news',
        JSON.stringify({ keywords: ['stellar', 'soroban'] }),
        JSON.stringify({ new_articles: 1 }),
        720, 2.0, 'active', w3CreateDate.toISOString()
    );

    for (let i = 0; i < 8; i++) {
        const checkId = randomUUID();
        const checkTime = new Date(w3CreateDate.getTime() + i * 12 * 60 * 60 * 1000);
        const cost = 0.005;
        const isFinding = i === 6;
        if (isFinding) totalFindings++;
        const txHash = generateStellarHash();

        db.prepare(`
            INSERT INTO checks (check_id, watcher_id, user_id, service_name, request_payload, response_data, cost_usdc, stellar_tx_hash, finding_detected, agent_reasoning, checked_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `).run(
            checkId, watcher3Id, DEMO_USER_ID, 'NewsService',
            JSON.stringify({}), JSON.stringify({ count: isFinding ? 3 : 0 }),
            cost, txHash, isFinding ? 1 : 0, 
            `Scanned news for "stellar, soroban". ${isFinding ? 'Found 3 new articles.' : 'No new relevant articles.'}`, 
            checkTime.toISOString()
        );

        db.prepare(`
            INSERT INTO transactions (tx_id, user_id, watcher_id, check_id, amount_usdc, service_name, stellar_tx_hash, timestamp)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        `).run(randomUUID(), DEMO_USER_ID, watcher3Id, checkId, cost, 'NewsService', txHash, checkTime.toISOString());

        if (isFinding) {
            db.prepare(`
                INSERT INTO findings (finding_id, watcher_id, check_id, user_id, type, headline, detail, data, cost_usdc, stellar_tx_hash, found_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            `).run(
                randomUUID(), watcher3Id, checkId, DEMO_USER_ID, 'news',
                'New Stellar Ecosystem News', 'Found articles regarding Soroban adoption and SDK updates.',
                JSON.stringify({ count: 3 }), 0.0, txHash, checkTime.toISOString()
            );
        }

        totalSpent += cost;
        totalChecks++;
    }
    console.log('- Stellar News seeded (8 checks, 1 finding)');

    // --- Watcher 4: Job Search ---
    const watcher4Id = 'watcher-jobs';
    const w4CreateDate = new Date(now.getTime() - 2 * 24 * 60 * 60 * 1000);
    db.prepare(`
        INSERT INTO watchers (watcher_id, user_id, name, type, parameters, alert_conditions, check_interval_minutes, weekly_budget_usdc, status, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
        watcher4Id, DEMO_USER_ID, 'Job Search', 'job',
        JSON.stringify({ keywords: ['flutter developer', 'remote'] }),
        JSON.stringify({ new_jobs: 1 }),
        1440, 1.0, 'active', w4CreateDate.toISOString()
    );

    for (let i = 0; i < 2; i++) {
        const checkId = randomUUID();
        const checkTime = new Date(w4CreateDate.getTime() + i * 24 * 60 * 60 * 1000);
        const cost = 0.007;
        const isFinding = i === 1;
        if (isFinding) totalFindings++;
        const txHash = generateStellarHash();

        db.prepare(`
            INSERT INTO checks (check_id, watcher_id, user_id, service_name, request_payload, response_data, cost_usdc, stellar_tx_hash, finding_detected, agent_reasoning, checked_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `).run(
            checkId, watcher4Id, DEMO_USER_ID, 'JobService',
            JSON.stringify({}), JSON.stringify({ jobs: isFinding ? 2 : 0 }),
            cost, txHash, isFinding ? 1 : 0, 
            `Checking for remote Flutter jobs. ${isFinding ? '2 matching jobs found.' : 'Search returned 0 new results.'}`, 
            checkTime.toISOString()
        );

        db.prepare(`
            INSERT INTO transactions (tx_id, user_id, watcher_id, check_id, amount_usdc, service_name, stellar_tx_hash, timestamp)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        `).run(randomUUID(), DEMO_USER_ID, watcher4Id, checkId, cost, 'JobService', txHash, checkTime.toISOString());

        if (isFinding) {
            db.prepare(`
                INSERT INTO findings (finding_id, watcher_id, check_id, user_id, type, headline, detail, data, cost_usdc, stellar_tx_hash, found_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            `).run(
                randomUUID(), watcher4Id, checkId, DEMO_USER_ID, 'job',
                '2 Remote Flutter Jobs Found', 'New openings at Boxkit and Flare-Tech.',
                JSON.stringify({ count: 2 }), 0.0, txHash, checkTime.toISOString()
            );
        }

        totalSpent += cost;
        totalChecks++;
    }
    console.log('- Job Search seeded (2 checks, 1 finding)');

    // 5. Update Watcher Totals in DB
    db.prepare('UPDATE watchers SET total_checks = 20, total_findings = 1, total_spent_usdc = 20 * 0.008 WHERE watcher_id = ?').run(watcher1Id);
    db.prepare('UPDATE watchers SET total_checks = 72, total_findings = 1, total_spent_usdc = 72 * 0.003 WHERE watcher_id = ?').run(watcher2Id);
    db.prepare('UPDATE watchers SET total_checks = 8, total_findings = 1, total_spent_usdc = 8 * 0.005 WHERE watcher_id = ?').run(watcher3Id);
    db.prepare('UPDATE watchers SET total_checks = 2, total_findings = 1, total_spent_usdc = 2 * 0.007 WHERE watcher_id = ?').run(watcher4Id);

    // 6. Create Morning Briefing for Today
    const briefingId = randomUUID();
    const todayStr = now.toISOString().split('T')[0];
    db.prepare(`
        INSERT INTO briefings (briefing_id, user_id, date, period_start, period_end, total_checks, total_findings, total_cost_usdc, generated_summary, generated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
        briefingId, 
        DEMO_USER_ID, 
        todayStr, 
        new Date(now.getTime() - 24 * 60 * 60 * 1000).toISOString(),
        now.toISOString(),
        totalChecks, 
        totalFindings, 
        totalSpent,
        "It's been a busy morning. Tokyo flight prices finally dropped below your $800 target, and we spotted a significant spike in ETH. You also have 3 new articles about the Stellar ecosystem and 2 new remote Flutter jobs to check out.",
        now.toISOString()
    );
    console.log('Morning briefing created.');

    const walletBalance = 10.00 - totalSpent;

    console.log('\nDemo data seeded:');
    console.log(`- 4 watchers (20, 72, 8, 2 checks)`);
    console.log(`- 4 findings`);
    console.log(`- ${totalChecks} total checks`);
    console.log(`- 1 morning briefing`);
    console.log(`- Wallet: $${walletBalance.toFixed(2)} USDC`);
}

seed().catch(console.error);
