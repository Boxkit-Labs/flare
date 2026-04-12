import { Keypair, Networks, TransactionBuilder, Address, Contract, nativeToScVal, BASE_FEE, Operation, xdr } from '@stellar/stellar-sdk';
import { Server, Api, assembleTransaction } from '@stellar/stellar-sdk/rpc';
import pool from '../db/database.js';
import { decrypt } from '../utils/crypto.js';
import crypto from 'node:crypto';
import 'dotenv/config';

async function waitForTransaction(rpc: Server, hash: string, timeoutMs = 45000): Promise<Api.GetTransactionResponse> {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    const res = await rpc.getTransaction(hash);
    if (res.status === "SUCCESS") return res;
    if (res.status === "FAILED") throw new Error(`Transaction ${hash} failed on-chain.`);
    await new Promise((r) => setTimeout(r, 2000));
  }
  throw new Error(`Transaction ${hash} timed out.`);
}

async function testFull() {
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

  const wasmHashBuffer = Buffer.from(process.env.MPP_CHANNEL_WASM_HASH!, "hex");
  const salt = crypto.randomBytes(32);
  const NETWORK_PASSPHRASE = Networks.TESTNET;

  const usdcAddress = 'CBIELTK6YBZJU5UP2WWQEUCYKLPU6AUNZ2BQ4WWFEIE3USCIHMXQDAMA';

  let account = await rpc.getAccount(userKp.publicKey());
  const createContractArgs = new xdr.CreateContractArgsV2({
      contractIdPreimage: xdr.ContractIdPreimage.contractIdPreimageFromAddress(
        new xdr.ContractIdPreimageFromAddress({
          address: Address.fromString(userKp.publicKey()).toScAddress(),
          salt,
        }),
      ),
      executable: xdr.ContractExecutable.contractExecutableWasm(wasmHashBuffer),
      constructorArgs: [],
  });

  const createOp = Operation.invokeHostFunction({
      func: xdr.HostFunction.hostFunctionTypeCreateContractV2(createContractArgs),
      auth: [],
  });

  const createTx = new TransactionBuilder(account, { fee: "100000", networkPassphrase: NETWORK_PASSPHRASE })
      .addOperation(createOp).setTimeout(60).build();

  const simCreate = await rpc.simulateTransaction(createTx);
  if (Api.isSimulationError(simCreate)) throw new Error("Create sim err");

  const preparedCreate = assembleTransaction(createTx, simCreate).build();
  preparedCreate.sign(userKp);
  const sendRes = await rpc.sendTransaction(preparedCreate);
  const txRes = await waitForTransaction(rpc, sendRes.hash);
  const contractAddress = Address.fromScVal((txRes as any).returnValue).toString();
  console.log("Deployed:", contractAddress);

  account = await rpc.getAccount(userKp.publicKey());
  const channelContract = new Contract(contractAddress);
  const commitmentKeypair = Keypair.random();
  const initTx = new TransactionBuilder(account, { fee: "100000", networkPassphrase: NETWORK_PASSPHRASE })
      .addOperation(
        channelContract.call(
          "init",
          xdr.ScVal.scvBytes(commitmentKeypair.rawPublicKey()),
          new Address(userKp.publicKey()).toScVal(),
          new Address(operatorKp.publicKey()).toScVal(),
          new Address(usdcAddress).toScVal(),
        ),
      ).setTimeout(60).build();

  const simInit = await rpc.simulateTransaction(initTx);
  if (Api.isSimulationError(simInit)) throw new Error("Init sim err");

  const preparedInit = assembleTransaction(initTx, simInit).build();
  preparedInit.sign(userKp);
  const sendInit = await rpc.sendTransaction(preparedInit);
  await waitForTransaction(rpc, sendInit.hash);
  console.log("Initialized!");

  account = await rpc.getAccount(userKp.publicKey());
  const topupTx = new TransactionBuilder(account, { fee: "100000", networkPassphrase: NETWORK_PASSPHRASE })
      .addOperation(
        channelContract.call(
          "top_up",
          nativeToScVal(BigInt(100000), { type: 'i128' }),
        ),
      ).setTimeout(60).build();

  console.log("Simulating top_up...");
  const simTopup = await rpc.simulateTransaction(topupTx);
  if (Api.isSimulationError(simTopup)) {
      console.log(JSON.stringify(simTopup.error, null, 2));
      throw new Error("Topup sim err");
  }

  const preparedTopup = assembleTransaction(topupTx, simTopup).build();
  preparedTopup.sign(userKp);

  console.log("Sending top_up...");
  const sendTopup = await rpc.sendTransaction(preparedTopup);
  console.log("Topup sent:", sendTopup.hash);
  try {
      await waitForTransaction(rpc, sendTopup.hash);
      console.log("Topup Success!");
  } catch(e) {
      const r = await rpc.getTransaction(sendTopup.hash);
      console.log("Topup Failed on-chain! Status:", r.status);
      if (r.status === 'FAILED') console.log("XDR:", JSON.stringify((r as any).resultXdr, null, 2));
  }
}

testFull().catch(console.error);
