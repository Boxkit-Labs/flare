import { Keypair, Networks, TransactionBuilder, Address, Contract, nativeToScVal, BASE_FEE } from '@stellar/stellar-sdk';
import { Server, Api, assembleTransaction } from '@stellar/stellar-sdk/rpc';
import pool from '../db/database.js';
import { decrypt } from '../utils/crypto.js';
import 'dotenv/config';

async function testTransfer() {
  const rpcUrl = process.env.SOROBAN_RPC_URL || 'https://soroban-testnet.stellar.org';
  const rpc = new Server(rpcUrl);

  const opSecret = process.env.OPERATOR_SECRET;
  if (!opSecret) throw new Error("No op secret");
  const operatorKp = Keypair.fromSecret(opSecret);

  const res = await pool.query('SELECT * FROM users ORDER BY created_at DESC LIMIT 1');
  if (!res.rows.length) throw new Error("No users");
  const user = res.rows[0];

  const encryptionKey = process.env.ENCRYPTION_KEY!;
  const userKp = Keypair.fromSecret(decrypt(user.stellar_secret_key_encrypted, encryptionKey));

  console.log("Sender:", userKp.publicKey());
  console.log("Receiver:", operatorKp.publicKey());

  const account = await rpc.getAccount(userKp.publicKey());
  const contract = new Contract('CBIELTK6YBZJU5UP2WWQEUCYKLPU6AUNZ2BQ4WWFEIE3USCIHMXQDAMA');

  console.log("Building transfer for 5000 stroops...");
  const transferOp = contract.call(
        'transfer',
        new Address(userKp.publicKey()).toScVal(),
        new Address(operatorKp.publicKey()).toScVal(),
        nativeToScVal(BigInt(5000), { type: 'i128' })
  );

  const tx = new TransactionBuilder(account, { fee: BASE_FEE, networkPassphrase: Networks.TESTNET })
    .addOperation(transferOp)
    .setTimeout(60)
    .build();

  console.log("Simulating...");
  const simResult = await rpc.simulateTransaction(tx);
  if (Api.isSimulationError(simResult)) {
    throw new Error(JSON.stringify(simResult));
  }
  
  const preparedTx = assembleTransaction(tx, simResult).build();
  preparedTx.sign(userKp);

  console.log("Sending...");
  const sendRes = await rpc.sendTransaction(preparedTx);
  console.log("Send hash:", sendRes.hash);

  console.log("Waiting for confirmation...");
  let finalRes;
  while(true) {
      finalRes = await rpc.getTransaction(sendRes.hash);
      if (finalRes.status !== 'NOT_FOUND') break;
      await new Promise(r => setTimeout(r, 2000));
  }
  console.log("Status:", finalRes.status);
  if (finalRes.status === 'FAILED') {
      console.log("Error trapped?", JSON.stringify(finalRes.resultXdr));
  }
}

testTransfer().catch(console.error);
