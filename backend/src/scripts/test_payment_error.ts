import { Keypair, Horizon, Networks, Asset, Operation, TransactionBuilder } from '@stellar/stellar-sdk';
import 'dotenv/config';

async function testPayment() {
  const server = new Horizon.Server('https://horizon-testnet.stellar.org');
  const opSecret = process.env.OPERATOR_SECRET!;
  const opKp = Keypair.fromSecret(opSecret);
  
  const targetPk = "GA5XVNXZFYKR6ELWTPCV32KVPHH4JFOOHWMV7FVT6PSNVGG22PJQ6VYK";
  const usdcAsset = new Asset('USDC', 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5');

  console.log("Attempting payment of 1.0 USDC from Op to", targetPk);
  try {
    const account = await server.loadAccount(opKp.publicKey());
    const tx = new TransactionBuilder(account, {
      fee: "1000",
      networkPassphrase: Networks.TESTNET
    })
    .addOperation(Operation.payment({
      destination: targetPk,
      asset: usdcAsset,
      amount: "1.0"
    }))
    .setTimeout(30)
    .build();
    
    tx.sign(opKp);
    const res = await server.submitTransaction(tx);
    console.log("Success! Hash:", res.hash);
  } catch (e: any) {
    console.error("FAILED!");
    console.error("Message:", e.message);
    if (e.response && e.response.data) {
      console.error("Result Codes:", JSON.stringify(e.response.data.extras?.result_codes, null, 2));
      console.error("Detail:", e.response.data.detail);
    }
  }
}

testPayment();
