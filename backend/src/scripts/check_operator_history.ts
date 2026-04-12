import { Keypair, Horizon, Networks, Asset } from '@stellar/stellar-sdk';
import 'dotenv/config';

async function checkOperatorHistory() {
  const secret = process.env.OPERATOR_SECRET;
  if (!secret) {
    console.log("OPERATOR_SECRET not set");
    return;
  }
  const kp = Keypair.fromSecret(secret);
  const server = new Horizon.Server(process.env.HORIZON_URL || 'https://horizon-testnet.stellar.org');

  console.log("Checking operator history:", kp.publicKey());
  try {
    const txs = await server.transactions().forAccount(kp.publicKey()).limit(5).order('desc').call();
    for (const tx of txs.records) {
      console.log(`TX: ${tx.hash} | Successful: ${tx.successful} | Result XDR: ${tx.result_xdr} | Memo: ${tx.memo}`);
      if (!tx.successful) {

      }
    }
  } catch (e: any) {
    console.error("Error fetching history:", e.message);
  }
}

checkOperatorHistory();
