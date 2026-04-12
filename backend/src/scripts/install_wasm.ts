import { Keypair, Networks, TransactionBuilder, Operation, xdr } from '@stellar/stellar-sdk';
import { Server, Api, assembleTransaction } from '@stellar/stellar-sdk/rpc';
import fs from 'node:fs';
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

async function installWasm() {
  const rpc = new Server('https://soroban-testnet.stellar.org');
  const opSecret = process.env.OPERATOR_SECRET!;
  const opKp = Keypair.fromSecret(opSecret);

  const wasm = fs.readFileSync('contract_optimized.wasm');
  const account = await rpc.getAccount(opKp.publicKey());

  const op = Operation.invokeHostFunction({
      func: xdr.HostFunction.hostFunctionTypeUploadContractWasm(wasm),
      auth: [],
  });

  const tx = new TransactionBuilder(account, { fee: "100000", networkPassphrase: Networks.TESTNET })
      .addOperation(op).setTimeout(60).build();

  const sim = await rpc.simulateTransaction(tx);
  if (Api.isSimulationError(sim)) throw new Error(JSON.stringify(sim));

  const prepared = assembleTransaction(tx, sim).build();
  prepared.sign(opKp);
  const sendRes = await rpc.sendTransaction(prepared);

  const res = await waitForTransaction(rpc, sendRes.hash);
  const hash = (res as any).returnValue.value().toString('hex');
  console.log("WASM HASH:");
  console.log(hash);
}
installWasm().catch(console.error);
