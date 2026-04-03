import { x402Client } from '../../backend/src/services/x402-client.js';
import dotenv from 'dotenv';

dotenv.config();

// Use the operator keys for testing if funded, or a dedicated test key
const TEST_PAYER_SECRET = process.env.RECEIVING_SECRET || "SAGQKX7WQAT7DN4H7Z7EJLOQ77YE5ALF6WD3CCJAQR3F23LQPJG6NIKE";
const SERVICE_URL = "http://localhost:3001/api/flights";

async function runTest() {
  console.log("Starting paid request verification...");
  
  try {
    const result = await x402Client.payAndFetch({
      url: SERVICE_URL,
      method: "POST",
      body: { origin: "JFK", destination: "TYO" },
      payerSecretKey: TEST_PAYER_SECRET
    });

    console.log("Response Data:", JSON.stringify(result.data, null, 2));
    console.log("Transaction Hash:", result.txHash);
    console.log("Amount Paid:", result.amountPaid);
  } catch (err: any) {
    console.error("Test failed:", err.message);
    if (err.message.includes("friendbot") || err.message.includes("trustline") || err.message.includes("balance")) {
      console.log("\nNOTE: This failure is likely because the test account is not yet funded with USDC.");
      console.log("To fully test, you need to:");
      console.log("1. Fund the account: curl 'https://friendbot.stellar.org?addr=...'");
      console.log("2. Add USDC trustline and get testnet USDC tokens.");
    }
  }
}

runTest();
