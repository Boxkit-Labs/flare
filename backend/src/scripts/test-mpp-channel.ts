import dotenv from 'dotenv';
import {
  Keypair,
  Networks,
  TransactionBuilder,
  Address,
  nativeToScVal,
  BASE_FEE,
  xdr,
  Operation,
  Account,
  Asset,
  Contract,
} from '@stellar/stellar-sdk';
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const RPC_URL            = 'https://soroban-testnet.stellar.org';
const NETWORK_PASSPHRASE = Networks.TESTNET;
const HORIZON_URL        = 'https://horizon-testnet.stellar.org';
const USDC_ISSUER        = process.env.USDC_ISSUER ?? 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5';
const USDC_CONTRACT_ID   = 'CBIELTK6YBZJU5UP2WWQEUCYKLPU6AUNZ2BQ4WWFEIE3USCIHMXQDAMA';
const OPERATOR_SECRET    = process.env.OPERATOR_SECRET!;
const CONTRACT_ID        = process.env.MPP_CHANNEL_CONTRACT_ID!;
const USDC_FACTOR        = 10_000_000n;

async function rpcFetch(method: string, params: any) {
  let attempts = 0;
  while (attempts < 3) {
    try {
      const res = await fetch(RPC_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ jsonrpc: '2.0', id: Date.now(), method, params }),
      });
      if (!res.ok) throw new Error(`RPC HTTP Error: ${res.status}`);
      const json = await res.json() as any;
      if (json.error) throw new Error(`RPC Error (${method}): ${JSON.stringify(json.error)}`);
      return json.result;
    } catch (e) {
      attempts++;
      if (attempts >= 3) throw e;
      console.log(`  RPC ${method} failed, retrying (${attempts}/3) [${(e as Error).message}]...`);
      await new Promise(r => setTimeout(r, 2000));
    }
  }
}

async function getAccount(address: string): Promise<Account> {

  let attempts = 0;
  while (attempts < 3) {
    try {
      const res = await fetch(`${HORIZON_URL}/accounts/${address}`);
      if (!res.ok) throw new Error(`Horizon Error for ${address}: ${res.statusText}`);
      const data = await res.json() as any;
      return new Account(address, data.sequence);
    } catch (e) {
      attempts++;
      if (attempts >= 3) throw e;
      console.log(`  Horizon fetch failed, retrying (${attempts}/3) [${(e as Error).message}]...`);
      await new Promise(r => setTimeout(r, 2000));
    }
  }
  throw new Error('Failed to fetch account after 3 attempts');
}

async function pollTx(hash: string): Promise<any> {
    const start = Date.now();
    process.stdout.write(`    Polling TX ${hash.slice(0, 12)}...`);
    while (Date.now() - start < 120_000) {
      const result = await rpcFetch('getTransaction', { hash });
      if (result.status === 'SUCCESS') {
        console.log(' OK');
        return result;
      }
      if (result.status === 'FAILED') {
        throw new Error(`TX FAILED: ${hash}\nResult XDR: ${result.resultXdr}`);
      }
      await new Promise(r => setTimeout(r, 3000));
      process.stdout.write('.');
    }
    throw new Error(`TX Timed out: ${hash}`);
}

async function simulateAndSend(account: Account, op: any, keypair: Keypair) {

    const tempTx = new TransactionBuilder(account, {
        fee: '100000',
        networkPassphrase: NETWORK_PASSPHRASE,
    })
    .addOperation(op)
    .setTimeout(60)
    .build();

    const simulateRes = await rpcFetch('simulateTransaction', { transaction: tempTx.toXDR() });
    if (simulateRes.error) throw new Error(`Simulation Failed: ${simulateRes.error}`);

    const txData = xdr.SorobanTransactionData.fromXDR(simulateRes.transactionData, 'base64');
    const minFee = BigInt(simulateRes.minResourceFee);

    const finalTx = new TransactionBuilder(account, {
        fee: (100000n + minFee).toString(),
        networkPassphrase: NETWORK_PASSPHRASE,
    })
    .addOperation(op)
    .setSorobanData(txData)
    .setTimeout(60)
    .build();

    finalTx.sign(keypair);

    const sendRes = await rpcFetch('sendTransaction', { transaction: finalTx.toXDR() });
    if (sendRes.error) throw new Error(`Send Failed: ${JSON.stringify(sendRes.error)}`);
    return await pollTx(sendRes.hash);
}

async function main() {
  console.log('\n--------------------------------------------------------');
  console.log('   MPP One-Way Channel - Test Existing Contract');
  console.log('--------------------------------------------------------\n');

  console.log(`  Contract ID used: ${CONTRACT_ID}`);

  if (!CONTRACT_ID) throw new Error("MPP_CHANNEL_CONTRACT_ID is not set in .env!");

  const senderKp = Keypair.fromSecret(OPERATOR_SECRET);
  const receiverKp = Keypair.random();
  const commitmentKp = Keypair.random();

  console.log(`\nSTEP 0: Funding and Setting up RECEIVER (${receiverKp.publicKey()})...`);
  await fetch(`https://friendbot.stellar.org/?addr=${receiverKp.publicKey()}`);
  const rAcc = await getAccount(receiverKp.publicKey());
  const trustTx = new TransactionBuilder(rAcc, { fee: '100000', networkPassphrase: NETWORK_PASSPHRASE })
    .addOperation(Operation.changeTrust({ asset: new Asset('USDC', USDC_ISSUER) }))
    .setTimeout(60).build();
  trustTx.sign(receiverKp);
  const tRes = await rpcFetch('sendTransaction', { transaction: trustTx.toXDR() });
  await pollTx(tRes.hash);
  console.log(`  OK: Receiver funded and USDC trustline established.`);

  console.log('\nSTEP 1: Initializing with init()...');
  const initAccount = await getAccount(senderKp.publicKey());
  const initOp = new Contract(CONTRACT_ID).call(
      'init',
      xdr.ScVal.scvBytes(commitmentKp.rawPublicKey()),
      new Address(receiverKp.publicKey()).toScVal(),
      new Address(USDC_CONTRACT_ID).toScVal(),
  );

  await simulateAndSend(initAccount, initOp, senderKp);
  console.log(`  OK: Channel Initialized. Sender=${senderKp.publicKey()}`);

  console.log('\nSTEP 2: Funding Channel with 1 USDC via top_up()...');
  const topUpAccount = await getAccount(senderKp.publicKey());
  const topUpOp = new Contract(CONTRACT_ID).call(
      'top_up',
      nativeToScVal(10_000_000n)
  );

  await simulateAndSend(topUpAccount, topUpOp, senderKp);
  console.log(`  OK: Channel Funded at ${CONTRACT_ID}`);

  console.log('\nSTEP 3: Off-chain Micro-Payments via prepare_commitment()...');
  const payments = [0.005, 0.008, 0.005, 0.004, 0.006];
  let cumulative = 0n;
  let lastProof: any = null;

  for (let i = 0; i < payments.length; i++) {
    const amount = payments[i];
    cumulative += BigInt(Math.round(amount * 10_000_000));

    const prepOp = new Contract(CONTRACT_ID).call(
      'prepare_commitment',
      nativeToScVal(cumulative)
    );
    const tempTx = new TransactionBuilder(await getAccount(senderKp.publicKey()), { fee: '100000', networkPassphrase: NETWORK_PASSPHRASE })
      .addOperation(prepOp)
      .setTimeout(60).build();

    const simRes = await rpcFetch('simulateTransaction', { transaction: tempTx.toXDR() });
    if (!simRes.results || simRes.results.length === 0) throw new Error('Simulation failed for prepare_commitment');

    const resultXdr = xdr.ScVal.fromXDR(simRes.results[0].xdr, 'base64');
    const commitmentBytes = resultXdr.bytes();

    const secretKey = commitmentKp.rawSecretKey();
    const pkcs8 = Buffer.concat([Buffer.from('302e020100300506032b657004220420', 'hex'), secretKey]);
    const privateKey = crypto.createPrivateKey({ key: pkcs8, format: 'der', type: 'pkcs8' });
    const signature = crypto.sign(null, commitmentBytes, privateKey);

    lastProof = { amount: cumulative, signature: signature.toString('hex') };
    console.log(`  Payment ${i+1}: ${amount} USDC. Cumulative: ${Number(cumulative)/10_000_000} USDC`);
  }

  console.log('\nSTEP 4: Closing Channel (Claiming Proof)...');
  const closeAccount = await getAccount(receiverKp.publicKey());
  const closeOp = new Contract(CONTRACT_ID).call(
      'close',
      nativeToScVal(lastProof.amount),
      xdr.ScVal.scvBytes(Buffer.from(lastProof.signature, 'hex')),
  );

  await simulateAndSend(closeAccount, closeOp, receiverKp);
  console.log(`\n  OK: CHANNEL CLOSED SUCCESSFULLY!`);
  console.log(`  Proof verified on-chain. Receiver claimed off-chain payments.`);

  console.log('\n--------------------------------------------------------');
  console.log('   TEST COMPLETE - End-to-End Success');
  console.log('--------------------------------------------------------\n');
}

main().catch(err => {
    console.error(`\n❌ Test failed: ${err.message}`);
    if (err.stack) console.error(err.stack);
    process.exit(1);
});
