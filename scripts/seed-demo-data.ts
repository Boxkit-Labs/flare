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
        INSERT INTO users (user_id, device_id, stellar_public_key, stellar_secret_key_encrypted, briefing_time, timezone, ghost_score, ghost_rank)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
        DEMO_USER_ID, 
        DEMO_DEVICE_ID, 
        'GDEMO' + randomBytes(24).toString('hex').toUpperCase().substring(0, 51),
        'SDEMO_ENCRYPTED_SECRET',
        '08:00',
        'UTC',
        87,
        'Agent Pro'
    );
    console.log('Demo user created.');

    let totalSpent = 0;
    let totalChecks = 0;
    let totalFindings = 0;

    const now = new Date();

    function addCheck(watcherId: string, service: string, payload: any, response: any, cost: number, time: Date, reasoning: string, isFinding: boolean = false) {
        const checkId = randomUUID();
        const txHash = generateStellarHash();

        db.prepare(`
            INSERT INTO checks (check_id, watcher_id, user_id, service_name, request_payload, response_data, cost_usdc, stellar_tx_hash, finding_detected, agent_reasoning, checked_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `).run(
            checkId, watcherId, DEMO_USER_ID, service,
            JSON.stringify(payload), JSON.stringify(response),
            cost, txHash, isFinding ? 1 : 0, reasoning, time.toISOString()
        );

        db.prepare(`
            INSERT INTO transactions (tx_id, user_id, watcher_id, check_id, amount_usdc, service_name, stellar_tx_hash, tx_type, timestamp)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        `).run(randomUUID(), DEMO_USER_ID, watcherId, checkId, cost, service, txHash, 'check', time.toISOString());

        totalSpent += cost;
        totalChecks++;
        return { checkId, txHash };
    }

    function addFinding(watcherId: string, checkId: string, txHash: string, type: string, headline: string, detail: string, data: any, cost: number, time: Date, confidence: number, tier: string, verified: boolean = true, collab: any = null) {
        const findingId = randomUUID();
        const verifyHash = verified ? generateStellarHash() : null;
        
        db.prepare(`
            INSERT INTO findings (finding_id, watcher_id, check_id, user_id, type, headline, detail, data, cost_usdc, stellar_tx_hash, verified, verification_tx_hash, collaboration_result, confidence_score, confidence_tier, found_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `).run(
            findingId, watcherId, checkId, DEMO_USER_ID, type,
            headline, detail, JSON.stringify(data), cost, txHash, 
            verified ? 1 : 0, verifyHash, collab ? JSON.stringify(collab) : null,
            confidence, tier, time.toISOString()
        );

        if (verified) {
            db.prepare(`
                INSERT INTO transactions (tx_id, user_id, watcher_id, amount_usdc, service_name, stellar_tx_hash, tx_type, timestamp)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            `).run(randomUUID(), DEMO_USER_ID, watcherId, 0.008, 'Security/Verify', verifyHash, 'verification', time.toISOString());
            totalSpent += 0.008;
        }

        if (collab) {
            db.prepare(`
                INSERT INTO transactions (tx_id, user_id, watcher_id, amount_usdc, service_name, stellar_tx_hash, tx_type, timestamp)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            `).run(randomUUID(), DEMO_USER_ID, watcherId, 0.008, 'Broker/Collab', collab.tx_hash, 'collaboration', time.toISOString());
            totalSpent += 0.008;
        }

        totalFindings++;
        return findingId;
    }

    // --- 1. TOKYO FLIGHTS (ANA) ---
    const w1Id = 'watcher-tokyo';
    const w1Date = new Date(now.getTime() - 5 * 24 * 60 * 60 * 1000);
    db.prepare(`INSERT INTO watchers (watcher_id, user_id, name, type, parameters, alert_conditions, check_interval_minutes, weekly_budget_usdc, status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`).run(w1Id, DEMO_USER_ID, 'Tokyo Flights (ANA)', 'flight', JSON.stringify({to:'HND'}), JSON.stringify({price:800}), 360, 5.0, 'active', w1Date.toISOString());
    for (let i = 0; i < 20; i++) {
        const time = new Date(w1Date.getTime() + i * 6 * 60 * 60 * 1000);
        const price = 1200 - i * 21;
        const isF = i === 19;
        const { checkId, txHash } = addCheck(w1Id, 'FlightService', {}, {price}, 0.008, time, `Analyzing SFO-HND price. Current: \$${price}. Threshold: \$800.`, isF);
        if (isF) addFinding(w1Id, checkId, txHash, 'flight', 'Tokyo Flight: $789 ✈️', 'Price hit target of $800. Seat availability: 4.', {price:789, savings:410}, 0.024, time, 94, 'Very High', true, {triggered_service:'news', safe:true, result_summary:'No travel advisories.', tx_hash: generateStellarHash()});
    }

    // --- 2. CRYPTO PORTFOLIO ---
    const w2Id = 'watcher-crypto';
    const w2Date = new Date(now.getTime() - 3 * 24 * 60 * 60 * 1000);
    db.prepare(`INSERT INTO watchers (watcher_id, user_id, name, type, parameters, alert_conditions, check_interval_minutes, weekly_budget_usdc, status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`).run(w2Id, DEMO_USER_ID, 'My Portfolio', 'crypto', JSON.stringify({assets:['ETH','XLM']}), JSON.stringify({value:50000}), 60, 10.0, 'active', w2Date.toISOString());
    for (let i = 0; i < 72; i++) {
        const time = new Date(w2Date.getTime() + i * 1 * 60 * 60 * 1000);
        const val = 42000 + i * 112;
        const isF = i === 71;
        const { checkId, txHash } = addCheck(w2Id, 'CryptoService', {}, {value:val}, 0.003, time, `Portfolio value: \$${val}. Goal: \$50,000.`, isF);
        if (isF) addFinding(w2Id, checkId, txHash, 'crypto', 'Portfolio Milestone: $50K! 🪙', 'Your tracked assets crossed the target valuation.', {value:50120, savings:0}, 0.016, time, 82, 'High');
    }

    // --- 3. STELLAR NEWS ---
    const w3Id = 'watcher-news';
    const w3Date = new Date(now.getTime() - 4 * 24 * 60 * 60 * 1000);
    db.prepare(`INSERT INTO watchers (watcher_id, user_id, name, type, parameters, alert_conditions, check_interval_minutes, weekly_budget_usdc, status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`).run(w3Id, DEMO_USER_ID, 'Stellar News', 'news', JSON.stringify({q:'SDF funding'}), JSON.stringify({count:1}), 720, 2.0, 'active', w3Date.toISOString());
    for (let i = 0; i < 8; i++) {
        const time = new Date(w3Date.getTime() + i * 12 * 60 * 60 * 1000);
        const isF = i === 7;
        const { checkId, txHash } = addCheck(w3Id, 'NewsService', {}, {count:isF?3:0}, 0.005, time, `Scanning sources for "SDF funding". Found: ${isF?3:0}.`, isF);
        if (isF) addFinding(w3Id, checkId, txHash, 'news', 'SDF Funding Boost 📰', '3 new articles published. Positive sentiment (0.85).', {sentiment: 0.85, articles: 3}, 0.008, time, 72, 'Moderate', false);
    }

    // --- 4. AIRPODS DEAL ---
    const w4Id = 'watcher-product';
    const w4Date = new Date(now.getTime() - 2 * 24 * 60 * 60 * 1000);
    db.prepare(`INSERT INTO watchers (watcher_id, user_id, name, type, parameters, alert_conditions, check_interval_minutes, weekly_budget_usdc, status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`).run(w4Id, DEMO_USER_ID, 'AirPods Deal', 'product', JSON.stringify({q:'AirPods Pro'}), JSON.stringify({price:200}), 480, 3.0, 'active', w4Date.toISOString());
    for (let i = 0; i < 12; i++) {
        const time = new Date(w4Date.getTime() + i * 8 * 60 * 60 * 1000);
        const price = i < 11 ? 249 : 189;
        const isF = i === 11;
        const { checkId, txHash } = addCheck(w4Id, 'ProductService', {}, {price}, 0.006, time, `Price at Amazon: \$${price}. Checking Best Buy and Walmart...`, isF);
        if (isF) addFinding(w4Id, checkId, txHash, 'product', 'AirPods Pro: $189 (Low) 📱', 'Lowest price in 6 months. Confirmed at 3 stores.', {price:189, savings:60}, 0.024, time, 91, 'Very High', true, {tx_hash: generateStellarHash(), result_summary: 'Verified at Amazon ($189), BB ($190), Walmart ($189).'});
    }

    // --- 5. REMOTE FLUTTER JOBS ---
    const w5Id = 'watcher-jobs';
    const w5Date = new Date(now.getTime() - 1 * 24 * 60 * 60 * 1000);
    db.prepare(`INSERT INTO watchers (watcher_id, user_id, name, type, parameters, alert_conditions, check_interval_minutes, weekly_budget_usdc, status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`).run(w5Id, DEMO_USER_ID, 'Remote Flutter Jobs', 'job', JSON.stringify({q:'Flutter'}), JSON.stringify({salary:200000}), 360, 2.0, 'active', w5Date.toISOString());
    for (let i = 0; i < 4; i++) {
        const time = new Date(w5Date.getTime() + i * 6 * 60 * 60 * 1000);
        const isF = i === 3;
        const { checkId, txHash } = addCheck(w5Id, 'JobService', {}, {count:isF?3:0}, 0.007, time, `Scraping Indeed and LinkedIn for senior roles. Match: ${isF?'YES':'NO'}.`, isF);
        if (isF) addFinding(w5Id, checkId, txHash, 'job', 'Google Flutter Role $220K 💼', 'Found 3 new listings. Google remote position is high match.', {salary:220000, match:0.95}, 0.008, time, 68, 'Moderate', false);
    }

    // --- 6. TECH PORTFOLIO (STOCK) ---
    const w6Id = 'watcher-stock';
    const w6Date = new Date(now.getTime() - 3 * 24 * 60 * 60 * 1000);
    db.prepare(`INSERT INTO watchers (watcher_id, user_id, name, type, parameters, alert_conditions, check_interval_minutes, weekly_budget_usdc, status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`).run(w6Id, DEMO_USER_ID, 'Tech Portfolio', 'stock', JSON.stringify({symbols:['AAPL','NVDA']}), JSON.stringify({nvda_spike:500}), 180, 4.0, 'active', w6Date.toISOString());
    for (let i = 0; i < 24; i++) {
        const time = new Date(w6Date.getTime() + i * 3 * 60 * 60 * 1000);
        const nvda = 450 + i * 2.5;
        const isF = i === 23;
        const { checkId, txHash } = addCheck(w6Id, 'StockService', {}, {nvda}, 0.004, time, `NVDA: \$${nvda.toFixed(2)}. Analyst consensus: Strong Buy.`, isF);
        if (isF) addFinding(w6Id, checkId, txHash, 'stock', 'NVDA Crossed $500! 📈', 'Goldman Sachs upgraded target. Resistance level broken.', {price: 507.50, analyst: 'Goldman Sachs'}, 0.016, time, 89, 'High', true);
    }

    // --- 7. AUSTIN APARTMENTS ---
    const w7Id = 'watcher-realestate';
    const w7Date = new Date(now.getTime() - 2 * 24 * 60 * 60 * 1000);
    db.prepare(`INSERT INTO watchers (watcher_id, user_id, name, type, parameters, alert_conditions, check_interval_minutes, weekly_budget_usdc, status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`).run(w7Id, DEMO_USER_ID, 'Austin Apartments', 'realestate', JSON.stringify({zip:'78701',beds:2}), JSON.stringify({price:2000}), 480, 5.0, 'active', w7Date.toISOString());
    for (let i = 0; i < 10; i++) {
        const time = new Date(w7Date.getTime() + i * 8 * 60 * 60 * 1000);
        const price = 2200 - i * 35;
        const isF = i === 9;
        const { checkId, txHash } = addCheck(w7Id, 'RealEstateService', {}, {price}, 0.01, time, `Zillow scan in 78701. Newest listing: \$${price}.`, isF);
        if (isF) addFinding(w7Id, checkId, txHash, 'realestate', 'New 2BR Austin $1,850 🏠', 'Listing found below market average ($2,100). Verified walk score.', {price:1850, savings:250}, 0.016, time, 85, 'High', true);
    }

    // --- 8. TAYLOR SWIFT TICKETS ---
    const w8Id = 'watcher-sports';
    const w8Date = new Date(now.getTime() - 1 * 24 * 60 * 60 * 1000);
    db.prepare(`INSERT INTO watchers (watcher_id, user_id, name, type, parameters, alert_conditions, check_interval_minutes, weekly_budget_usdc, status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`).run(w8Id, DEMO_USER_ID, 'Taylor Swift Tickets', 'sports', JSON.stringify({team:'Swift'}), JSON.stringify({price:200}), 90, 5.0, 'active', w8Date.toISOString());
    for (let i = 0; i < 15; i++) {
        const time = new Date(w8Date.getTime() + i * 90 * 60 * 1000);
        const price = 350 - i * 12;
        const isF = i === 14;
        const { checkId, txHash } = addCheck(w8Id, 'SportsService', {}, {price}, 0.009, time, `Ticketmaster/Stubhub scan. Floor seats: \$${price}.`, isF);
        if (isF) addFinding(w8Id, checkId, txHash, 'sports', 'Eras Tour Floor: $180 🏀', 'Massive price drop detected. Floor tickets available.', {price:182, savings:170}, 0.008, time, 78, 'High', false);
    }

    // 5. Update Watcher Stats
    db.prepare('UPDATE watchers SET total_checks = 20, total_findings = 1, total_spent_usdc = 1.25 WHERE watcher_id = ?').run(w1Id);
    db.prepare('UPDATE watchers SET total_checks = 72, total_findings = 1, total_spent_usdc = 0.52 WHERE watcher_id = ?').run(w2Id);

    // 6. Create Morning Briefing
    const todayStr = now.toISOString().split('T')[0];
    db.prepare(`INSERT INTO briefings (briefing_id, user_id, date, period_start, period_end, total_checks, total_findings, total_cost_usdc, generated_summary, generated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`).run(randomUUID(), DEMO_USER_ID, todayStr, new Date(now.getTime()-86400000).toISOString(), now.toISOString(), totalChecks, totalFindings, 3.47, "It's a historic morning for your Flare agents. Tokyo flights hit $789, your crypto portfolio crossed $50k, and we found Taylor Swift floor tickets for $180. Your estimated real-world savings this period is $715 across 8 categories.", now.toISOString());

    // Update specific briefing savings in schema? No, it's calculated or in state.
    
    console.log('\nDemo data expansion complete:');
    console.log(`- 8 watchers across all categories`);
    console.log(`- ${totalChecks} total intelligence checks`);
    console.log(`- 8 high-fidelity findings`);
    console.log(`- Ghost Score: 87 (Agent Pro)`);
    console.log(`- Est. Savings: \$715 | Total Cost: \$3.47`);
}

seed().catch(console.error);
