import { Keypair, Horizon, Networks, Asset } from '@stellar/stellar-sdk';
import 'dotenv/config';

async function checkAccount(pk: string) {
  const server = new Horizon.Server(process.env.HORIZON_URL || 'https://horizon-testnet.stellar.org');

  console.log("Checking account:", pk);
  try {
    const acc = await server.loadAccount(pk);
    console.log("Balances:", JSON.stringify(acc.balances, null, 2));
  } catch (e: any) {
    console.error("Account not found or error:", e.message);
  }
}

const pk = "GBPBLW6VQKEMZLOXEBVSXBBG2LV4IKEDMC3VKPIZ272TOUPJN62EUV4N";
checkAccount(pk);
