import fetch from 'node-fetch';
import { createInterface } from 'node:readline/promises';
import { stdin as input, stdout as output } from 'node:process';

const BACKEND_URL = 'http://localhost:3000';
const SERVICES = [
    { name: 'Flight Data', url: 'http://localhost:3001/health' },
    { name: 'Crypto Data', url: 'http://localhost:3002/health' },
    { name: 'News Data', url: 'http://localhost:3003/health' },
    { name: 'Product Data', url: 'http://localhost:3004/health' },
    { name: 'Job Data', url: 'http://localhost:3005/health' },
];

const DEMO_USER_ID = 'demo-user-1';

async function wait(ms: number) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function checkHealth() {
    console.log('--- Checking Service Health ---');
    
    try {
        const res = await fetch(`${BACKEND_URL}/health`);
        const data = await res.json() as any;
        console.log(`✅ Backend: OK (v${data.version})`);
    } catch (e) {
        console.log(`❌ Backend: OFFLINE`);
        return false;
    }

    for (const service of SERVICES) {
        try {
            const res = await fetch(service.url);
            if (res.ok) {
                console.log(`✅ ${service.name}: OK`);
            } else {
                console.log(`❌ ${service.name}: ERROR (${res.status})`);
            }
        } catch (e) {
            console.log(`❌ ${service.name}: OFFLINE`);
        }
    }
    return true;
}

async function runDemo() {
    console.log('\n🚀 Starting Live Demo Scenario\n');

    const ok = await checkHealth();
    if (!ok) {
        console.log('\nAborting: Ensure all services are running.');
        return;
    }

    const rl = createInterface({ input, output });

    // Step 1: Create Watcher (Interactive)
    console.log('\nSTEP 1: Create a new watcher from the app now.');
    await rl.question('Press [Enter] once you have shown the creation flow on camera...');

    // Step 2: Trigger Checks
    console.log('\nSTEP 2: Forcing a check on all active watchers...');
    
    // Fetch user's watchers first
    const watchersRes = await fetch(`${BACKEND_URL}/api/watchers?user_id=${DEMO_USER_ID}`);
    const watchers = await watchersRes.json() as any[];
    
    console.log(`Found ${watchers.length} active watchers. Triggering...`);

    const results = [];
    for (const watcher of watchers) {
        console.log(`   Triggering ${watcher.name}...`);
        const res = await fetch(`${BACKEND_URL}/api/watchers/${watcher.watcher_id}/check`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' }
        });
        const data = await res.json() as any;
        results.push(data);
        console.log(`   Result: ${data.message}`);
    }

    // Step 3: Finding Notification
    console.log('\nSTEP 3: Finding should appear as push notification NOW');
    console.log('   (Waiting 5 seconds for notification delivery simulation...)');
    await wait(5000);

    // Step 4: Morning Briefing
    console.log('\nSTEP 4: Generating morning briefing...');
    const briefingRes = await fetch(`${BACKEND_URL}/api/briefings/generate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ user_id: DEMO_USER_ID })
    });
    const briefing = await briefingRes.json() as any;
    console.log(`✅ Briefing generated: ${(briefing.generated_summary || briefing.error || 'No summary available').substring(0, 100)}...`);
    console.log('   Notification sent to phone.');

    // Step 5: Summary
    console.log('\n--- Demo Complete ---');
    console.log(`Checks executed: ${watchers.length}`);
    
    const transactionsRes = await fetch(`${BACKEND_URL}/api/transactions?user_id=${DEMO_USER_ID}`);
    const transactions = await transactionsRes.json() as any[];
    const recentTxs = transactions.slice(0, watchers.length);

    console.log(`Stellar transactions: ${recentTxs.length}`);
    console.log('\nStellar Explorer Links:');
    recentTxs.forEach((tx: any) => {
        console.log(`- ${tx.watcher_name || 'Check'}: https://stellar.expert/explorer/testnet/tx/${tx.stellar_tx_hash}`);
    });

    rl.close();
}

runDemo().catch(console.error);
