import {
  Keypair,
  Asset,
  Operation,
  TransactionBuilder,
  Networks,
  Address,
  xdr,
  nativeToScVal,
  Account,
  Transaction,
} from "@stellar/stellar-sdk";
import { Server, Api, assembleTransaction } from "@stellar/stellar-sdk/rpc";
import nacl from "tweetnacl";
import crypto from "node:crypto";
import fs from "node:fs";
import "dotenv/config";

// Constants
const RPC_URL = "https://soroban-testnet.stellar.org";
const HORIZON_URL = "https://horizon-testnet.stellar.org";
const NETWORK_PASSPHRASE = Networks.TESTNET;
const WASM_PATH =
  "C:\\projetcs\\codezeus\\flare\\one-way-channel\\target\\wasm32-unknown-unknown\\release\\channel.wasm";
const USDC_ISSUER = "GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5";
const USDC_ASSET = new Asset("USDC", USDC_ISSUER);
const USDC_CONTRACT =
  "CBIELTK6YBZJU5UP2WWQEUCYKLPU6AUNZ2BQ4WWFEIE3USCIHMXQDAMA";

const rpc = new Server(RPC_URL);

async function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// ─────────────────────────────────────────────────────────────────────────────
// RPC Helpers
// ─────────────────────────────────────────────────────────────────────────────

async function waitForTx(hash: string): Promise<any> {
  console.log(`  -> Polling for status of TX ${hash}...`);
  for (let i = 0; i < 40; i++) {
    const result = await rpc.getTransaction(hash);
    if (result.status === "SUCCESS") return result;
    if (result.status === "FAILED") {
      throw new Error(
        `Transaction failed: ${hash}\n${JSON.stringify(result.resultXdr || "No result XDR")}`,
      );
    }
    await sleep(3000);
  }
  throw new Error(`Timeout waiting for TX ${hash}`);
}

async function getAccount(pk: string) {
  const response = await fetch(`${HORIZON_URL}/accounts/${pk}`);
  if (!response.ok) {
    throw new Error(`Horizon Error (getAccount): ${await response.text()}`);
  }
  const json = (await response.json()) as any;
  return json;
}

async function quickTx(keypair: Keypair, ops: any[]) {
  await sleep(2000); // Resiliency for ledger propagation
  const acc = await getAccount(keypair.publicKey());
  const tx = new TransactionBuilder(
    new Account(keypair.publicKey(), acc.sequence),
    { fee: "500000", networkPassphrase: NETWORK_PASSPHRASE },
  );
  ops.forEach((op) => tx.addOperation(op));
  const builtTx = tx.setTimeout(60).build();

  const isSoroban = ops.some((op) => {
    const name = op.type
      ? String(op.type)
      : op.body
        ? op.body().switch().name
        : "";
    return name.includes("invokeHostFunction") || name === "24";
  });

  if (isSoroban) {
    const simRes = await rpc.simulateTransaction(builtTx);
    if (Api.isSimulationError(simRes)) {
      console.error(
        "\n[DIAGNOSTIC] Simulation Failed Events (Hex View):",
        JSON.stringify((simRes as any).events, null, 2),
      );
      throw new Error(`Simulation failed: ${JSON.stringify(simRes.error)}`);
    }
    const rawAssembled = assembleTransaction(builtTx, simRes).build();
    const assembled = new Transaction(rawAssembled.toXDR(), NETWORK_PASSPHRASE);

    if (typeof (assembled as any).signAuthEntries === "function") {
      (assembled as any).signAuthEntries(keypair, NETWORK_PASSPHRASE);
    }

    assembled.sign(keypair);
    const sendRes = await rpc.sendTransaction(assembled);
    if (sendRes.status === "ERROR") {
      throw new Error(`Send error (Soroban): ${JSON.stringify(sendRes)}`);
    }
    return waitForTx(sendRes.hash);
  } else {
    builtTx.sign(keypair);
    const sendRes = await rpc.sendTransaction(builtTx);
    if (sendRes.status === "ERROR") {
      throw new Error(`Send error (Standard): ${JSON.stringify(sendRes)}`);
    }
    return waitForTx(sendRes.hash);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stellar Helpers
// ─────────────────────────────────────────────────────────────────────────────

async function fundWithFriendbot(publicKey: string) {
  console.log(`  -> Funding ${publicKey} via Friendbot...`);
  const response = await fetch(
    `https://friendbot.stellar.org?addr=${publicKey}`,
  );
  if (!response.ok) {
    console.warn(
      `     Friendbot warning (might be already funded): ${await response.text()}`,
    );
  }
  await sleep(5000);
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Flow
// ─────────────────────────────────────────────────────────────────────────────

async function main() {
  console.log("=================================================");
  console.log("   MPP STANDALONE CLOSE PROOF (DEFINITIVE-FIX)   ");
  console.log("=================================================");

  // 1. Setup Accounts
  const commitmentSeed = nacl.randomBytes(32);
  const commitmentKeypair = nacl.sign.keyPair.fromSeed(commitmentSeed);
  const commitmentPublicKey = Buffer.from(commitmentKeypair.publicKey);
  const commitmentSecretKey = commitmentKeypair.secretKey;

  const sender = Keypair.random();
  const receiver = Keypair.random();
  console.log(
    `[1] Accounts Created.\n    SENDER: ${sender.publicKey()}\n    RECEIVER: ${receiver.publicKey()}`,
  );

  await fundWithFriendbot(sender.publicKey());
  await fundWithFriendbot(receiver.publicKey());

  console.log(`[2] Setting up USDC trustlines & Swapping XLM for USDC...`);
  await quickTx(sender, [Operation.changeTrust({ asset: USDC_ASSET })]);
  await quickTx(receiver, [Operation.changeTrust({ asset: USDC_ASSET })]);

  await quickTx(sender, [
    Operation.pathPaymentStrictSend({
      sendAsset: Asset.native(),
      sendAmount: "200",
      destination: sender.publicKey(),
      destAsset: USDC_ASSET,
      destMin: "5.0",
      path: [],
    }),
  ]);
  console.log(`    SENDER swapped for 5 USDC.`);

  // 3. Upload Fixed WASM
  console.log(`[3] Uploading FIXED Channel WASM...`);
  const wasmBuffer = fs.readFileSync(WASM_PATH);
  const uploadRes = await quickTx(sender, [
    Operation.invokeHostFunction({
      func: xdr.HostFunction.hostFunctionTypeUploadContractWasm(wasmBuffer),
      auth: [],
    }),
  ]);
  const wasmHash = uploadRes.returnValue.bytes();
  console.log(`    WASM Uploaded: ${wasmHash.toString("hex")}`);

  // 4. Deploy Fresh Contract Instance
  console.log(`[4] Deploying Contract Instance...`);
  const salt = crypto.randomBytes(32);
  const deployRes = await quickTx(sender, [
    Operation.invokeHostFunction({
      func: xdr.HostFunction.hostFunctionTypeCreateContract(
        new xdr.CreateContractArgs({
          contractIdPreimage:
            xdr.ContractIdPreimage.contractIdPreimageFromAddress(
              new xdr.ContractIdPreimageFromAddress({
                address: Address.fromString(sender.publicKey()).toScAddress(),
                salt,
              }),
            ),
          executable: xdr.ContractExecutable.contractExecutableWasm(wasmHash),
        }),
      ),
      auth: [],
    }),
  ]);
  const contractId = Address.fromScVal(deployRes.returnValue).toString();
  console.log(`    Contract Deployed: ${contractId}`);
  const channelContractSc = Address.fromString(contractId).toScAddress();

  // 5. Initialize (Fixed Signature: [key, from, to, token])
  console.log(`[5] Initializing Channel (with FIXED signature)...`);
  const initOp = Operation.invokeHostFunction({
    func: xdr.HostFunction.hostFunctionTypeInvokeContract(
      new xdr.InvokeContractArgs({
        contractAddress: channelContractSc,
        functionName: "init",
        args: [
          xdr.ScVal.scvBytes(commitmentPublicKey),
          new Address(sender.publicKey()).toScVal(),
          new Address(receiver.publicKey()).toScVal(),
          new Address(USDC_CONTRACT).toScVal(),
        ],
      }),
    ),
    auth: [],
  });
  await quickTx(sender, [initOp]);
  console.log(`    Channel Initialized.`);

  // 6. Top-up
  console.log(`[6] Depositing 2 USDC...`);
  const topUpOp = Operation.invokeHostFunction({
    func: xdr.HostFunction.hostFunctionTypeInvokeContract(
      new xdr.InvokeContractArgs({
        contractAddress: channelContractSc,
        functionName: "top_up",
        args: [nativeToScVal(BigInt(20000000))],
      }),
    ),
    auth: [],
  });
  await quickTx(sender, [topUpOp]);
  console.log(`    Deposit complete.`);

  // 7. Off-chain Payments
  console.log(`[7] Exchanging off-chain payments...`);
  const cumulativeAmounts = [100000, 250000, 500000];
  let lastSig = "";
  for (const amountStroops of cumulativeAmounts) {
    const prepTx = new TransactionBuilder(
      new Account(sender.publicKey(), "0"),
      { fee: "100", networkPassphrase: NETWORK_PASSPHRASE },
    )
      .addOperation(
        Operation.invokeHostFunction({
          func: xdr.HostFunction.hostFunctionTypeInvokeContract(
            new xdr.InvokeContractArgs({
              contractAddress: channelContractSc,
              functionName: "prepare_commitment",
              args: [nativeToScVal(BigInt(amountStroops))],
            }),
          ),
          auth: [],
        }),
      )
      .build();
    const sim = await rpc.simulateTransaction(prepTx);
    const bytesToSign = (sim as any).results[0].retval.bytes();
    const signature = nacl.sign.detached(bytesToSign, commitmentSecretKey);
    lastSig = Buffer.from(signature).toString("hex");
    console.log(`    Signed cumulative ${amountStroops} stroops.`);
  }

  // 8. Close
  console.log(`[8] Closing channel (Settlement)...`);
  const closeOp = Operation.invokeHostFunction({
    func: xdr.HostFunction.hostFunctionTypeInvokeContract(
      new xdr.InvokeContractArgs({
        contractAddress: channelContractSc,
        functionName: "close",
        args: [
          nativeToScVal(BigInt(500000)),
          xdr.ScVal.scvBytes(Buffer.from(lastSig, "hex")),
        ],
      }),
    ),
    auth: [],
  });
  await quickTx(receiver, [closeOp]);
  console.log(`    Channel Closed.`);

  // 9. Verification
  const rFinal = await fetch(
    `${HORIZON_URL}/accounts/${receiver.publicKey()}`,
  ).then((r) => r.json());
  const rUSDC = rFinal.balances.find(
    (b: any) => b.asset_code === "USDC",
  )?.balance;
  console.log(`\n[9] SUCCESS: Receiver Final USDC: ${rUSDC}`);
  console.log(`=================================================`);
}

main().catch((e) => {
  console.error("\n[CRITICAL ERROR]", e);
  process.exit(1);
});
