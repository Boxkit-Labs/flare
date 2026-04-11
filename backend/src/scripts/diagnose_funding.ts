import { Keypair, Horizon, Networks, Asset } from '@stellar/stellar-sdk';
import 'dotenv/config';

async function diagnose() {
  const server = new Horizon.Server(process.env.HORIZON_URL || 'https://horizon-testnet.stellar.org');
  const opSecret = process.env.OPERATOR_SECRET;
  const opKp = Keypair.fromSecret(opSecret!);
  
  const targetPk = process.argv[2] || "GA5XVNXZFYKR6ELWTPCV32KVPHH4JFOOHWMV7FVT6PSNVGG22PJQ6VYK";
  
  console.log("=== DIAGNOSIS ===");
  console.log("Operator:", opKp.publicKey());
  console.log("Target  :", targetPk);
  
  try {
    const opAcc = await server.loadAccount(opKp.publicKey());
    console.log("Operator Balances:", JSON.stringify(opAcc.balances, null, 2));
    console.log("Operator Sequence:", opAcc.sequence);
  } catch (e) { console.error("Op load failed"); }

  try {
    const targetAcc = await server.loadAccount(targetPk);
    console.log("Target Balances:", JSON.stringify(targetAcc.balances, null, 2));
    console.log("Target Sequence:", targetAcc.sequence);
  } catch (e) { console.error("Target load failed (unfunded?)"); }

  console.log("\nRecent Transactions for Target:");
  try {
    const txs = await server.transactions().forAccount(targetPk).limit(10).order('desc').call();
    txs.records.forEach(tx => {
        console.log(`- ${tx.hash} | OK: ${tx.successful} | Result XDR: ${tx.result_xdr}`);
    });
  } catch (e) { console.log("No transactions found for target."); }

  console.log("\nRecent Transactions for Operator:");
  try {
    const txs = await server.transactions().forAccount(opKp.publicKey()).limit(10).order('desc').call();
    txs.records.forEach(tx => {
        console.log(`- ${tx.hash} | OK: ${tx.successful} | Result XDR: ${tx.result_xdr}`);
    });
  } catch (e) { console.log("No transactions found for operator."); }
}

diagnose();
