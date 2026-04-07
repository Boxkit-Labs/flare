import axios from 'axios';
import { randomUUID } from 'node:crypto';

const API_BASE = 'https://flare-f9yk.onrender.com/api';
const TEST_DEVICE_ID = `test-device-${Date.now()}`;

async function runTests() {
    console.log('🚀 Starting Backend Integration Test Suite...');
    let testUserId = '';

    try {
        // --- STAGE 1: IDENTITY & WALLET ---
        console.log('\n--- Stage 1: Identity & Wallet ---');
        
        // 1. Register User
        console.log(`Registering user with device_id: ${TEST_DEVICE_ID}...`);
        const regRes = await axios.post(`${API_BASE}/users/register`, { device_id: TEST_DEVICE_ID });
        testUserId = regRes.data.user_id;
        console.log('✅ User registered:', testUserId);
        console.log('   Stellar Public Key:', regRes.data.stellar_public_key);

        // 2. Fund Wallet
        console.log('Funding wallet (Stellar Testnet)...');
        const fundRes = await axios.post(`${API_BASE}/users/${testUserId}/fund`);
        console.log('✅ Wallet funded:', fundRes.data);

        // 3. Verify Balance
        const walletRes = await axios.get(`${API_BASE}/wallet/${testUserId}`);
        console.log('✅ Current Balances:', {
            USDC: walletRes.data.balance_usdc,
            XLM: walletRes.data.balance_xlm
        });

        // --- STAGE 2: WATCHERS ---
        console.log('\n--- Stage 2: Intelligence Agent Orchestration ---');

        // 1. Create Flight Watcher
        console.log('Creating Flight Watcher (Tokyo ANA)...');
        const flightWatcher = await axios.post(`${API_BASE}/watchers`, {
            user_id: testUserId,
            name: 'Tokyo Flights (ANA)',
            type: 'flight',
            parameters: { destination: 'Tokyo (NRT)', airline: 'ANA' },
            alert_conditions: { price_below: 800 },
            check_interval_minutes: 360,
            weekly_budget_usdc: 5.0,
            priority: 'high'
        });
        const watcherId = flightWatcher.data.watcher_id;
        console.log('✅ Flight Watcher created:', watcherId);

        // 2. Trigger Manual Check
        console.log('Triggering manual intelligence check...');
        const checkRes = await axios.post(`${API_BASE}/watchers/${watcherId}/check`);
        console.log('✅ Check executed:', checkRes.data.message);

        // 3. Verify Watcher Detail
        const detailRes = await axios.get(`${API_BASE}/watchers/${watcherId}`);
        console.log(`✅ Watcher Detail: ${detailRes.data.name} | Checks: ${detailRes.data.total_checks}`);

        // --- STAGE 3: ANALYTICS ---
        console.log('\n--- Stage 3: Financial & Performance Audit ---');
        const statsRes = await axios.get(`${API_BASE}/wallet/${testUserId}/stats`);
        console.log('✅ Wallet Stats:', statsRes.data);

        // --- STAGE 4: BRIEFINGS ---
        console.log('\n--- Stage 4: Intelligence Briefing Generation ---');
        console.log('Generating manual intelligence briefing...');
        const briefRes = await axios.post(`${API_BASE}/briefings/generate`, { user_id: testUserId });
        console.log('✅ Briefing generated:', briefRes.data.briefing_id);

        const todayRes = await axios.get(`${API_BASE}/briefings/today?user_id=${testUserId}`);
        console.log('✅ Today\'s Briefing Status:', todayRes.data ? 'Found' : 'Not Found');

        // --- STAGE 5: CLEANUP ---
        console.log('\n--- Stage 5: Cleanup ---');
        console.log(`Deleting watcher ${watcherId}...`);
        await axios.delete(`${API_BASE}/watchers/${watcherId}`);
        console.log('✅ Watcher deleted.');

        console.log('\n✨ Integration Test Suite Completed Successfully! ✨');

    } catch (error: any) {
        console.error('\n❌ Integration Test Failed!');
        if (error.response) {
            console.error('   Status:', error.response.status);
            console.error('   Data:', error.response.data);
        } else {
            console.error('   Message:', error.message);
        }
        process.exit(1);
    }
}

runTests();
