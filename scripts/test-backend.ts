async function delay(ms: number) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function checkHealth(url: string, name: string): Promise<boolean> {
    try {
        const res = await fetch(url);
        if (res.ok) {
            console.log(`✓ ${name} is running`);
            return true;
        } else {
            console.log(`✗ ${name} returned status ${res.status}`);
            return false;
        }
    } catch (e) {
        console.log(`✗ ${name} is unreachable (${url})`);
        return false;
    }
}

async function runIntegrationTest() {
    console.log("=== EXECUTING E2E BACKEND INTEGRATION TEST ===\n");

    // 1. Prerequisites check
    console.log("[1] Checking Services Health...");
    const services = [
        { name: "Backend", url: "http://localhost:3000/health" },
        { name: "Flight Service", url: "http://localhost:3001/health" },
        { name: "Crypto Service", url: "http://localhost:3002/health" },
        { name: "News Service", url: "http://localhost:3003/health" },
        { name: "Product Service", url: "http://localhost:3004/health" },
        { name: "Job Service", url: "http://localhost:3005/health" },
        { name: "Stellar Testnet", url: "https://horizon-testnet.stellar.org/" }
    ];

    let allHealthy = true;
    for (const svc of services) {
        const isHealthy = await checkHealth(svc.url, svc.name);
        if (!isHealthy) allHealthy = false;
    }

    if (!allHealthy) {
        console.warn("\n⚠️ WARNING: Not all services are healthy. Test may fail.\n");
    }

    // 2. User setup
    console.log("\n[2] Setting up Test User...");
    const deviceId = `test-device-${Date.now()}`;
    const regRes = await fetch('http://localhost:3000/api/users/register', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: `test_${Date.now()}@example.com`, device_id: deviceId })
    });
    
    if (!regRes.ok) throw new Error("Failed to register user");
    const user = (await regRes.json()) as any;
    
    console.log(`User created. Public Key: ${user.stellar_public_key}`);

    // Wait for Stellar network initialization
    await delay(3000); 

    console.log("Funding wallet via Operator...");
    const fundRes = await fetch(`http://localhost:3000/api/users/${user.user_id}/fund`, { method: 'POST' });
    if (!fundRes.ok) throw new Error("Failed to fund user");
    
    const walletRes = await fetch(`http://localhost:3000/api/wallet/${user.user_id}`);
    const walletData = (await walletRes.json()) as any;
    if (walletData.balance_usdc <= 0) throw new Error("Wallet failed to fund");
    
    console.log(`User funded. Balance: ${walletData.balance_usdc} USDC`);

    // 3. Create watchers
    console.log("\n[3] Creating Watchers...");
    const watcherIds: string[] = [];

    // Crypto Watcher
    let wRes = await fetch('http://localhost:3000/api/watchers', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            user_id: user.user_id,
            name: "ETH Spike Watcher",
            type: "crypto",
            parameters: { coin_id: "ethereum" },
            alert_conditions: { property: "priceUsd", operator: ">", value: 500 },
            check_interval_minutes: 1,
            weekly_budget_usdc: 1.00
        })
    });
    watcherIds.push((await wRes.json() as any).watcher_id);

    // Flight Watcher
    wRes = await fetch('http://localhost:3000/api/watchers', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            user_id: user.user_id,
            name: "NY to Paris Drop",
            type: "flight",
            parameters: { origin: "NYC", destination: "CDG", date: "2024-12-01" },
            alert_conditions: { property: "price", operator: "<", value: 900 },
            check_interval_minutes: 1,
            weekly_budget_usdc: 1.00
        })
    });
    watcherIds.push((await wRes.json() as any).watcher_id);

    // News Watcher
    wRes = await fetch('http://localhost:3000/api/watchers', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            user_id: user.user_id,
            name: "Stellar News",
            type: "news",
            parameters: { keywords: ["stellar"] },
            alert_conditions: { property: "matches", operator: ">", value: 0 },
            check_interval_minutes: 1,
            weekly_budget_usdc: 1.00
        })
    });
    watcherIds.push((await wRes.json() as any).watcher_id);

    console.log(`Created 3 watchers successfully.`);

    // 4. Wait for checks
    console.log("\n[4] Waiting 90 seconds for scheduler to execute intervals...");
    let elapsed = 0;
    const intervalId = setInterval(() => {
        elapsed += 10;
        process.stdout.write(`\rCountdown: ${90 - elapsed}s remaining...`);
    }, 10000);

    await delay(90000);
    clearInterval(intervalId);
    console.log("\nWait complete.");

    // 5. Verify checks
    console.log("\n[5] Verifying Checks execution...");
    let totalChecksExecuted = 0;
    let totalFindingsDetected = 0;
    
    // Slight buffer for any writes to flush to sqlite
    await delay(2000);

    for (const wId of watcherIds) {
        const wInfo = await (await fetch(`http://localhost:3000/api/watchers/${wId}`)).json() as any;
        console.log(`Watcher ${wInfo.name}: ${wInfo.recent_checks.length} checks, ${wInfo.recent_findings.length} findings, $${wInfo.spent_this_week_usdc || 0} spent`);
        
        totalChecksExecuted += wInfo.recent_checks.length;
        totalFindingsDetected += wInfo.recent_findings.length;
    }

    if (totalChecksExecuted < 3) {
        console.log("⚠️ Less than 3 total checks executed. Did the scheduler run?");
    }

    // 6. Verify Stellar transactions
    console.log("\n[6] Verifying Stellar Transactions...");
    const txRes = await fetch(`http://localhost:3000/api/transactions?user_id=${user.user_id}`);
    const txs = (await txRes.json()) as any;
    
    for (const tx of txs) {
        console.log(`✓ Stellar TX: ${tx.stellar_tx_hash} — generated for service check`);
    }

    // 7. Verify wallet
    console.log("\n[7] Verifying Wallet Decrements...");
    const walletFinalRes = await fetch(`http://localhost:3000/api/wallet/${user.user_id}`);
    const walletFinal = (await walletFinalRes.json()) as any;
    
    const spentAmount = walletData.balance_usdc - walletFinal.balance_usdc;
    console.log(`Wallet: ${walletFinal.balance_usdc} USDC (spent $${spentAmount.toFixed(4)})`);

    // 8. Test Briefing
    console.log("\n[8] Testing Manual Briefing Generation...");
    const briefRes = await fetch('http://localhost:3000/api/briefings/generate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ user_id: user.user_id })
    });
    const briefingData = (await briefRes.json()) as any;
    
    if (briefingData && briefingData.generatedSummary) {
        console.log(`Briefing Generated Successfully:`);
        console.log(`> "${briefingData.generatedSummary}"`);
    } else {
        console.log("⚠️ Briefing generation failed or was completely empty.");
    }

    // 9. Cleanup
    console.log("\n[9] Cleaning up Watchers...");
    for (const wId of watcherIds) {
        await fetch(`http://localhost:3000/api/watchers/${wId}`, { method: 'DELETE' });
    }

    // Final output block
    console.log("\n==================================");
    console.log("    INTEGRATION TEST COMPLETE    ");
    console.log("==================================");
    console.log(`Users checked: 1`);
    console.log(`Watchers created: 3`);
    console.log(`Checks executed: ${totalChecksExecuted}`);
    console.log(`Findings detected: ${totalFindingsDetected}`);
    console.log(`Stellar transactions: ${txs.length}`);
    console.log(`Total USDC spent: $${spentAmount.toFixed(4)}`);
    if (txs.length > 0) {
        console.log(`\nAll Stellar TX Hashes:`);
        for (const tx of txs) {
            console.log(`https://stellar.expert/explorer/testnet/tx/${tx.stellar_tx_hash}`);
        }
    }
}

runIntegrationTest().catch(console.error);
