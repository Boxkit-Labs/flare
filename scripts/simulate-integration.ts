import fetch from 'node-fetch';

async function runTest() {
    const baseUrl = 'http://127.0.0.1:3000';
    console.log('--- Phase 1: User Registration ---');
    const regRes = await fetch(`${baseUrl}/api/users/register`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ device_id: 'test-device-' + Date.now() })
    });
    const user = await regRes.json() as any;
    if (user.error) throw new Error('Reg failed: ' + user.error);
    const userId = user.user_id;
    console.log(`User created: ${userId}`);
    console.log(`Public Key: ${user.stellar_public_key}`);

    console.log('\n--- Phase 2: Funding ---');
    const fundRes = await fetch(`${baseUrl}/api/users/${userId}/fund`, { method: 'POST' });
    const fundData = await fundRes.json() as any;
    if (fundData.error) throw new Error('Fund failed: ' + fundData.error);
    console.log('Funding successful:', fundData.funded);

    // Wait for funding to complete (Soroban can be slow)
    console.log('Waiting 10s for Stellar trustlines...');
    await new Promise(r => setTimeout(r, 10000));

    console.log('\n--- Phase 3: Creating Watchers ---');
    const watchers = [
        {
            user_id: userId,
            name: "NYC to Tokyo Flight",
            type: "flight",
            parameters: { origin: "JFK", destination: "NRT", alert_price: 800 },
            alert_conditions: { price_below: 800 },
            check_interval_minutes: 1,
            weekly_budget_usdc: 10
        },
        {
            user_id: userId,
            name: "Crypto Portfolio Monitor",
            type: "crypto",
            parameters: { symbols: ["XLM", "ETH"], alert_change_percent: 5 },
            alert_conditions: { change_24h_percent: 5 },
            check_interval_minutes: 1,
            weekly_budget_usdc: 10
        },
        {
            user_id: userId,
            name: "Stellar Ecosystem News",
            type: "news",
            parameters: { keywords: ["stellar"] },
            alert_conditions: { min_relevance: 0.1 }, // Low relevance for testing
            check_interval_minutes: 1,
            weekly_budget_usdc: 10
        },
        {
            user_id: userId,
            name: "Headphone Price Drop",
            type: "product",
            parameters: { name: "Sony WH-1000XM5", alert_price: 280 },
            alert_conditions: { price_below: 280 },
            check_interval_minutes: 1,
            weekly_budget_usdc: 10
        }
    ];

    for (const w of watchers) {
        const res = await fetch(`${baseUrl}/api/watchers`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(w)
        });
        const data = await res.json() as any;
        if (data.error) {
            console.error(`Failed to create ${w.name}:`, data.error);
        } else {
            console.log(`Watcher created: ${data.name} (${data.watcher_id})`);
        }
    }

    console.log('\n--- Simulation Setup Complete ---');
    console.log('Please wait 3 minutes for checks to execute.');
}

runTest().catch(console.error);
