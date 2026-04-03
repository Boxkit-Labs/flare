async function delay(ms: number) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function testFullLoop() {
    try {
        console.log("=== Agent Loop E2E Test ===");

        // 1. Register User
        console.log("\n[1] Registering User...");
        const regRes = await fetch('http://localhost:3000/api/users/register', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email: `testloop_${Date.now()}@example.com` })
        });
        const user = (await regRes.json()) as any;
        console.log(`✅ Registered user ID: ${user.user_id}`);

        // 2. Fund User
        console.log("\n[2] Funding user via Friendbot and Operator...");
        // Wait 2s for backend to initialize stellar if needed
        await delay(2000); 
        const fundRes = await fetch(`http://localhost:3000/api/users/${user.user_id}/fund`, { method: 'POST' });
        const fundData = await fundRes.json();
        console.log(`✅ User funded.\n`, fundData);

        // 3. Create Watcher
        console.log("\n[3] Creating Crypto Watcher with 1-min interval...");
        const createRes = await fetch('http://localhost:3000/api/watchers', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                user_id: user.user_id,
                name: "Bitcoin Loop Test",
                type: "crypto",
                parameters: { coin_id: "bitcoin" },
                alert_conditions: { property: "priceUsd", operator: "<", value: 100000000 },
                check_interval_minutes: 1, // 1 minute!
                weekly_budget_usdc: 5
            })
        });
        const watcher = (await createRes.json()) as any;
        console.log(`✅ Watcher created. ID: ${watcher.watcher_id}`);

        // 4. Wait
        console.log("\n[4] Waiting 65 seconds for the first scheduled check to fire (plus buffer)...");
        // We wait 65 seconds to allow the 1-minute interval scheduling to pick it up and process.
        // Technically, `scheduler.scheduleWatcher` sets the first timeout based on `next_check_at`. 
        // When we created the watcher, `next_check_at` was set to `now + 1 min`. 
        
        let elapsed = 0;
        const intervalId = setInterval(() => {
            elapsed += 5;
            console.log(`Waiting... ${elapsed}s / 65s`);
        }, 5000);

        await delay(65000);
        clearInterval(intervalId);
        console.log("\n\nWait complete.");

        // 5. Query Checks
        console.log("\n[5] Querying Checks...");
        const checksRes = await fetch(`http://localhost:3000/api/watchers/${watcher.watcher_id}`);
        const watcherData = (await checksRes.json()) as any;
        console.log("Recorded Checks:", watcherData.recent_checks);
        
        // 6. Query Transactions
        console.log("\n[6] Querying Transactions...");
        const txRes = await fetch(`http://localhost:3000/api/transactions?user_id=${user.user_id}`);
        const txs = (await txRes.json()) as any;
        console.log("Recorded Transactions:", txs);
        
        if (txs.length > 0) {
            console.log("\n✅ Test Success! Please verify the hash on Stellar Testnet Explorer:");
            console.log("https://stellar.expert/explorer/testnet/tx/" + txs[0].stellar_tx_hash);
        } else {
             console.log("\n❌ Test Failed. No transactions recorded. Did the check executor run?");
        }

    } catch (e) {
        console.error("Test failed:", e);
    }
}

testFullLoop();
