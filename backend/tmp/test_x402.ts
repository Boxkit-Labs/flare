import { x402Client } from '../src/services/x402-client';
import dotenv from 'dotenv';
import { Keypair } from '@stellar/stellar-sdk';
import { stellarService } from '../src/services/stellar';

dotenv.config();

async function run() {
    const testUrl = 'https://xlm402.com/api/premium-data';

    // Get an account that is already funded with USDC and XLM on testnet.
    const operatorSecret = process.env.OPERATOR_SECRET;
    if (!operatorSecret) {
        console.error("OPERATOR_SECRET is required to run this test.");
        return;
    }

    const keypair = Keypair.fromSecret(operatorSecret);
    console.log(`Using Wallet: ${keypair.publicKey()}`);

    // Let's make sure it has balances
    const balances = await stellarService.getBalances(keypair.publicKey());
    console.log("Current Balances:", balances);

    console.log(`\n--- 1. Testing getPaymentCost() against ${testUrl} ---`);
    try {
        const cost = await x402Client.getPaymentCost(testUrl);
        if (cost) {
            console.log("Payment Required:");
            console.log(`- Amount: ${cost.amount} (atomic units)`);
            console.log(`- Asset Contract ID: ${cost.asset}`);
        } else {
             console.log("No payment required. (Perhaps it's not paywalled?)");
             return;
        }
    } catch (e: any) {
        // We know xlm402.com might be a placeholder in this mock environment, so we catch fetch errors.
        console.error("Fetch failed (Expected if xlm402.com is down):", e.message);
        console.log("\nSkipping Step 2 since the endpoint couldn't be reached.");
        return;
    }

    console.log(`\n--- 2. Testing payAndFetch() ---`);
    try {
        const result = await x402Client.payAndFetch({
            url: testUrl,
            method: 'GET',
            payerSecretKey: operatorSecret
        });

        console.log("Payment Successful!");
        console.log(`- Data Received:`, result.data);
        console.log(`- Amount Paid: ${result.amountPaid}`);
        if (result.txHash) {
             console.log(`- Transaction Hash: ${result.txHash}`);
             console.log(`- Explorer: https://stellar.expert/explorer/testnet/tx/${result.txHash}`);
        } else {
             console.log(`- Transaction Hash: Not returned by the facilitator header.`);
        }

    } catch (e: any) {
         console.error("Payment Flow Failed:", e.message);
    }
}

run().catch(console.error);
