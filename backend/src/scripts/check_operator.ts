import { Keypair, Horizon, Networks, Asset } from '@stellar/stellar-sdk';
import 'dotenv/config';

async function checkOperator() {
  const secret = process.env.OPERATOR_SECRET;
  if (!secret) {
    console.log("OPERATOR_SECRET not set");
    return;
  }
  const kp = Keypair.fromSecret(secret);
  const server = new Horizon.Server(process.env.HORIZON_URL || 'https://horizon-testnet.stellar.org');
  
  console.log("Checking operator:", kp.publicKey());
  try {
    const acc = await server.loadAccount(kp.publicKey());
    console.log("Balances:", JSON.stringify(acc.balances, null, 2));
  } catch (e: any) {
    console.error("Operator not found or error:", e.message);
  }
}

checkOperator();
