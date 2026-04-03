import { payForService } from '../backend/src/services/stellar-pay-client.js';
import { StellarService } from '../backend/src/services/stellar.js';
import { Keypair } from '@stellar/stellar-sdk';
import dotenv from 'dotenv';
import path from 'path';

// Load env from backend/.env for operator secret
dotenv.config({ path: path.join(process.cwd(), 'backend/.env') });

const SOROBAN_RPC_URL = 'https://soroban-testnet.stellar.org';

const SERVICES = [
  { name: "Flight Data", url: "http://localhost:3001/api/flights", body: { origin: "JFK", destination: "LHR" } },
  { name: "Crypto Data", url: "http://localhost:3002/api/crypto", body: { symbols: ["BTC", "ETH"] } },
  { name: "News Data", url: "http://localhost:3003/api/news", body: { keywords: ["stellar"] } },
  { name: "Product Data", url: "http://localhost:3004/api/products", body: { product_name: "Sony" } },
  { name: "Job Data", url: "http://localhost:3005/api/jobs", body: { keywords: ["Flutter"] } }
];

async function verifyAll() {
  console.log("=== Starting Full Suite x402 Verification (Direct Stellar) ===\n");

  const stellar = new StellarService();
  
  // 1. Setup Buyer
  console.log("Setting up temporary buyer wallet...");
  const buyerKp = Keypair.random();
  console.log(`  Public Key: ${buyerKp.publicKey()}`);
  
  console.log("  Funding with XLM...");
  await stellar.fundWithFriendbot(buyerKp.publicKey());
  
  console.log("  Adding USDC trustline...");
  await stellar.addUsdcTrustline(buyerKp.secret());
  
  console.log("  Funding with 5 USDC from operator...");
  await stellar.fundNewUserWithUsdc(buyerKp.publicKey(), "5");
  
  await new Promise(r => setTimeout(r, 2000));

  // 2. Test each service
  for (const service of SERVICES) {
    console.log(`Testing ${service.name}...`);
    try {
      const result = await payForService({
        serviceUrl: service.url,
        method: "POST",
        body: service.body,
        payerSecretKey: buyerKp.secret(),
        rpcUrl: SOROBAN_RPC_URL
      });

      console.log(`  [SUCCESS] Data received.`);
      console.log(`  [TX HASH] ${result.txHash}`);
      console.log(`  [PREVIEW] ${JSON.stringify(result.data).substring(0, 80)}...`);
    } catch (e: any) {
      console.error(`  [FAILED] ${service.name}:`, e.message);
    }
    console.log("");
  }
}

verifyAll().catch(console.error);
