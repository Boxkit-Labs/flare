import {
  Keypair,
  Networks,
  TransactionBuilder,
  Address,
  Contract,
  nativeToScVal,
  BASE_FEE,
  xdr,
  Operation,
} from "@stellar/stellar-sdk";
import { Server, Api, assembleTransaction } from "@stellar/stellar-sdk/rpc";
import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import pool from "../db/database.js";
import { encrypt, decrypt } from "../utils/crypto.js";
import dotenv from "dotenv";

dotenv.config();

const RPC_URL =
  process.env.SOROBAN_RPC_URL || "https://soroban-testnet.stellar.org";
const NETWORK_PASSPHRASE = Networks.TESTNET;
const USDC_CONTRACT = process.env.USDC_ISSUER
  ? "" // We'll use contract address from env
  : "CBIELTK6YBZJU5UP2WWQEUCYKLPU6AUNZ2BQ4WWFEIE3USCIHMXQDAMA";

const CHANNEL_WASM_HASH = process.env.MPP_CHANNEL_WASM_HASH || "";
const MPP_CHANNEL_CONTRACT_ID = "CCF6KCSVWEWOVTFNA24Y2JLFPVZJ6TIF5UDDVGUINBZIW6BAZG4KYE5R";

export interface ChannelState {
  channelId: string;
  contractAddress: string;
  senderAddress: string;
  receiverAddress: string;
  commitmentPublicKey: string;
  commitmentSecretKey: string; // ed25519 raw hex seed
  deposit: number; // in USDC
  spent: number; // cumulative USDC spent via off-chain proofs
  latestProof: string | null;
  openedAt: Date;
  expiresAt: Date;
  txHashOpen: string;
  status: string;
}

async function waitForTransaction(
  rpc: Server,
  hash: string,
  timeoutMs = 45000,
): Promise<Api.GetTransactionResponse> {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    const res = await rpc.getTransaction(hash);
    if (res.status === "SUCCESS") return res;
    if (res.status === "FAILED")
      throw new Error(`Transaction ${hash} failed on-chain.`);
    await new Promise((r) => setTimeout(r, 3000));
  }
  throw new Error(`Transaction ${hash} timed out.`);
}

export class MPPChannelManager {
  private activeChannels: Map<string, ChannelState> = new Map();

  // ----------------------------------------------------
  // Open Channel
  // ----------------------------------------------------
  async openChannel(params: {
    userId: string;
    serviceId: string;
    userSecretKey: string;
    receiverAddress: string;
    depositAmount: string;
    durationSeconds: number;
  }): Promise<{ channelId: string; txHash: string }> {
    const {
      userId,
      serviceId,
      userSecretKey,
      receiverAddress,
      depositAmount,
      durationSeconds,
    } = params;
    const channelKey = `${userId}:${serviceId}`;

    if (!CHANNEL_WASM_HASH) {
      throw new Error(
        "MPP_CHANNEL_WASM_HASH not set in environment. Deploy the contract first.",
      );
    }

    const senderKeypair = Keypair.fromSecret(userSecretKey);
    const rpc = new Server(RPC_URL);

    // Generate an ed25519 commitment keypair for signing off-chain proofs
    const commitmentKeypair = Keypair.random();
    const commitmentPubKeyHex = commitmentKeypair
      .rawPublicKey()
      .toString("hex");
    const commitmentSecretHex = commitmentKeypair
      .rawSecretKey()
      .toString("hex");

    // Deposit amount in stroops (7 decimal places for USDC-style)
    const depositStroops = Math.round(parseFloat(depositAmount) * 10_000_000);

    const salt = crypto.randomBytes(32);
    const wasmHashBuffer = Buffer.from(CHANNEL_WASM_HASH, "hex");
    const expiresAt = new Date(Date.now() + durationSeconds * 1000);

    const account = await rpc.getAccount(senderKeypair.publicKey());

    // USDC contract address to use as token
    const usdcAddress =
      "CBIELTK6YBZJU5UP2WWQEUCYKLPU6AUNZ2BQ4WWFEIE3USCIHMXQDAMA";

    // 1. Deploy contract with empty constructor args (new WASM requires separate init)
    const createContractArgs = new xdr.CreateContractArgsV2({
      contractIdPreimage: xdr.ContractIdPreimage.contractIdPreimageFromAddress(
        new xdr.ContractIdPreimageFromAddress({
          address: Address.fromString(senderKeypair.publicKey()).toScAddress(),
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

    const createTx = new TransactionBuilder(account, {
      fee: "100000",
      networkPassphrase: NETWORK_PASSPHRASE,
    })
      .addOperation(createOp)
      .setTimeout(60)
      .build();

    console.log(`[MPP] Deploying channel contract (empty ctor)...`);
    const simResult = await rpc.simulateTransaction(createTx);
    if (Api.isSimulationError(simResult)) {
      throw new Error(
        `Contract creation simulation failed: ${JSON.stringify(simResult.error)}`,
      );
    }

    const preparedTx = assembleTransaction(createTx, simResult).build();
    preparedTx.sign(senderKeypair);

    const sendResult = await rpc.sendTransaction(preparedTx);
    if (sendResult.status !== "PENDING") {
      throw new Error(
        `Contract creation submission failed: ${JSON.stringify(sendResult)}`,
      );
    }

    console.log(`[MPP] Contract creation TX submitted: ${sendResult.hash}`);
    const createTxRes = await waitForTransaction(rpc, sendResult.hash);
    console.log(`[MPP] Contract creation TX successful: ${sendResult.hash}`);

    // Extract the contract address from the transaction result (it's the return value of CreateContract)
    const successRes = createTxRes as Api.GetSuccessfulTransactionResponse;
    const contractAddress = successRes.returnValue ? Address.fromScVal(successRes.returnValue).toString() : null;
    if (!contractAddress || typeof contractAddress !== 'string') {
      throw new Error(`Failed to extract contract address string from deployment result. Got: ${JSON.stringify(contractAddress)}`);
    }
    console.log(`[MPP] Deployed contract address: ${contractAddress}`);



    // 2. Initialize the channel contract
    const updatedAccount = await rpc.getAccount(senderKeypair.publicKey());
    const channelContract = new Contract(contractAddress);

    const initTx = new TransactionBuilder(updatedAccount, {
      fee: "100000",
      networkPassphrase: NETWORK_PASSPHRASE,
    })
      .addOperation(
        channelContract.call(
          "init",
          xdr.ScVal.scvBytes(Buffer.from(commitmentPubKeyHex, "hex")),
          new Address(senderKeypair.publicKey()).toScVal(),
          new Address(receiverAddress).toScVal(),
          new Address(usdcAddress).toScVal(),
        ),
      )
      .setTimeout(60)
      .build();

    console.log(`[MPP] Initializing channel ${contractAddress}...`);
    const simInit = await rpc.simulateTransaction(initTx);
    if (Api.isSimulationError(simInit)) {
      throw new Error(`Init simulation failed: ${JSON.stringify(simInit.error)}`);
    }
    const preparedInit = assembleTransaction(initTx, simInit).build();
    preparedInit.sign(senderKeypair);
    const initRes = await rpc.sendTransaction(preparedInit);
    await waitForTransaction(rpc, initRes.hash);

    // 3. Top up (Fund) the channel
    const accountForTopup = await rpc.getAccount(senderKeypair.publicKey());
    const topupTx = new TransactionBuilder(accountForTopup, {
      fee: "100000",
      networkPassphrase: NETWORK_PASSPHRASE,
    })
      .addOperation(
        channelContract.call(
          "top_up",
          nativeToScVal(BigInt(depositStroops), { type: 'i128' }),
        ),
      )
      .setTimeout(60)
      .build();

    console.log(`[MPP] Funding channel with ${depositStroops} stroops...`);
    const simTopup = await rpc.simulateTransaction(topupTx);
    if (Api.isSimulationError(simTopup)) {
      throw new Error(`Top-up simulation failed: ${JSON.stringify(simTopup.error)}`);
    }
    const preparedTopup = assembleTransaction(topupTx, simTopup).build();
    preparedTopup.sign(senderKeypair);
    const topupRes = await rpc.sendTransaction(preparedTopup);
    await waitForTransaction(rpc, topupRes.hash);

    const channelId = contractAddress;
    const finalTxHash = topupRes.hash;

    const state: ChannelState = {
      channelId,
      contractAddress,
      senderAddress: senderKeypair.publicKey(),
      receiverAddress,
      commitmentPublicKey: commitmentPubKeyHex,
      commitmentSecretKey: commitmentSecretHex,
      deposit: parseFloat(depositAmount),
      spent: 0,
      latestProof: null,
      openedAt: new Date(),
      expiresAt,
      txHashOpen: finalTxHash,
      status: "open",
    };

    this.activeChannels.set(channelKey, state);

    // Persist to DB with encrypted commitment keys
    const encryptionKey = process.env.ENCRYPTION_KEY || "";
    const encryptedSecretKey = encrypt(commitmentSecretHex, encryptionKey);

    await pool.query(
      `INSERT INTO mpp_channels
       (channel_id, user_id, service_id, sender_address, receiver_address,
        commitment_public_key, commitment_secret_key_encrypted,
        deposit_usdc, spent_usdc, latest_proof, open_tx_hash, expires_at, status)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,0,NULL,$9,$10,'open')`,
      [
        channelId,
        userId,
        serviceId,
        senderKeypair.publicKey(),
        receiverAddress,
        commitmentPubKeyHex,
        encryptedSecretKey,
        parseFloat(depositAmount),
        finalTxHash,
        expiresAt.toISOString(),
      ],
    );

    console.log(
      `[MPP] OK: Channel opened: ${channelId} | TX: ${finalTxHash}`,
    );
    return { channelId, txHash: finalTxHash };
  }

  // ----------------------------------------------------
  // Verify Off-Chain Payment Proof
  // ----------------------------------------------------
  async verifyPaymentProof(
    channelId: string,
    proofJson: string,
    requiredAmountStroops: number,
  ): Promise<boolean> {
    try {
      const StateQuery = await pool.query(
        `SELECT * FROM mpp_channels WHERE channel_id=$1 AND status='open'`,
        [channelId],
      );
      if (StateQuery.rows.length === 0) {
        console.error(
          `[MPP Verify] Channel ${channelId} not found or not open.`,
        );
        return false;
      }

      const row = StateQuery.rows[0];
      const contractAddress = row.channel_id;
      const commitmentPublicKeyHex = row.commitment_public_key;

      const proof = JSON.parse(proofJson);
      if (!proof.amount || !proof.signature) {
        console.error(`[MPP Verify] Invalid proof format.`);
        return false;
      }

      if (proof.amount < requiredAmountStroops) {
        console.error(
          `[MPP Verify] Proof amount ${proof.amount} is less than required ${requiredAmountStroops}.`,
        );
        return false;
      }

      // Reconstruct the commitment XDR
      const networkId = crypto
        .createHash("sha256")
        .update(NETWORK_PASSPHRASE)
        .digest();
      const channelAddress = new Address(contractAddress);

      const commitment = xdr.ScVal.scvMap([
        new xdr.ScMapEntry({
          key: xdr.ScVal.scvSymbol("amount"),
          val: nativeToScVal(BigInt(proof.amount), { type: 'i128' }),
        }),
        new xdr.ScMapEntry({
          key: xdr.ScVal.scvSymbol("channel"),
          val: channelAddress.toScVal(),
        }),
        new xdr.ScMapEntry({
          key: xdr.ScVal.scvSymbol("domain"),
          val: xdr.ScVal.scvSymbol("chancmmt"),
        }),
        new xdr.ScMapEntry({
          key: xdr.ScVal.scvSymbol("network"),
          val: xdr.ScVal.scvBytes(networkId),
        }),
      ]);

      const commitmentBytes = commitment.toXDR();

      // Verify ed25519 signature via node:crypto
      const publicKey = crypto.createPublicKey({
        key: Buffer.concat([
          Buffer.from("302a300506032b6570032100", "hex"), // ed25519 SubjectPublicKeyInfo prefix
          Buffer.from(commitmentPublicKeyHex, "hex"),
        ]),
        format: "der",
        type: "spki",
      });

      const isVerified = crypto.verify(
        null,
        commitmentBytes,
        publicKey,
        Buffer.from(proof.signature, "hex"),
      );

      if (isVerified) {
        // Update state with the new proof
        const spentUsdc = proof.amount / 10_000_000;
        await pool.query(
          `UPDATE mpp_channels SET spent_usdc=$1, latest_proof=$2 WHERE channel_id=$3`,
          [spentUsdc, proofJson, channelId],
        );

        // In-memory update if it exists
        const activeKeys = [...this.activeChannels.keys()];
        for (const key of activeKeys) {
          if (this.activeChannels.get(key)?.channelId === channelId) {
            const s = this.activeChannels.get(key)!;
            s.spent = spentUsdc;
            s.latestProof = proofJson;
            break;
          }
        }
        return true;
      }
      return false;
    } catch (e: any) {
      console.error(`[MPP Verify] Error verifying proof:`, e.message);
      return false;
    }
  }

  // ----------------------------------------------------
  // Make Off-Chain Payment
  // ----------------------------------------------------
  async makePayment(params: {
    userId: string;
    serviceId: string;
    amount: string;
  }): Promise<{ proof: string; totalSpent: string }> {
    const { userId, serviceId, amount } = params;
    const channelKey = `${userId}:${serviceId}`;

    let state: ChannelState | null | undefined =
      this.activeChannels.get(channelKey);
    if (!state) {
      // Try to restore from DB
      state = await this.loadChannelFromDb(userId, serviceId);
      if (!state) throw new Error(`No active channel for ${channelKey}`);
      this.activeChannels.set(channelKey, state);
    }

    const newSpent = state.spent + parseFloat(amount);
    const newSpentStroops = Math.round(newSpent * 10_000_000);

    // Produce XDR-encoded commitment exactly as the contract expects:
    // ScVal::Map { amount: i128, channel: Address, domain: Symbol("chancmmt"), network: BytesN<32> }
    // Sign with ed25519 raw key
    const networkId = crypto
      .createHash("sha256")
      .update(NETWORK_PASSPHRASE)
      .digest();
    const channelAddress = new Address(state.contractAddress);

    const commitment = xdr.ScVal.scvMap([
      new xdr.ScMapEntry({
        key: xdr.ScVal.scvSymbol("amount"),
        val: nativeToScVal(BigInt(newSpentStroops), { type: 'i128' }),
      }),
      new xdr.ScMapEntry({
        key: xdr.ScVal.scvSymbol("channel"),
        val: channelAddress.toScVal(),
      }),
      new xdr.ScMapEntry({
        key: xdr.ScVal.scvSymbol("domain"),
        val: xdr.ScVal.scvSymbol("chancmmt"),
      }),
      new xdr.ScMapEntry({
        key: xdr.ScVal.scvSymbol("network"),
        val: xdr.ScVal.scvBytes(networkId),
      }),
    ]);

    const commitmentBytes = commitment.toXDR();
    const secretKey = Buffer.from(state.commitmentSecretKey, "hex");

    // Sign with ed25519 using the raw 32-byte seed via node crypto
    const privateKey = crypto.createPrivateKey({
      key: Buffer.concat([
        Buffer.from("302e020100300506032b657004220420", "hex"),
        secretKey,
      ]),
      format: "der",
      type: "pkcs8",
    });

    const signature = crypto
      .sign(null, commitmentBytes, privateKey)
      .toString("hex");

    // Update state
    state.spent = newSpent;
    state.latestProof = JSON.stringify({ amount: newSpentStroops, signature });

    // Persist
    await pool.query(
      `UPDATE mpp_channels SET spent_usdc=$1, latest_proof=$2 WHERE channel_id=$3`,
      [newSpent, state.latestProof, state.channelId],
    );

    console.log(
      `[MPP] Off-chain proof signed. Cumulative: ${newSpent} USDC (+${amount})`,
    );
    return { proof: state.latestProof, totalSpent: newSpent.toFixed(7) };
  }

  // ----------------------------------------------------
  // Close Channel
  // ----------------------------------------------------
  async closeChannel(params: {
    userId: string;
    serviceId: string;
  }): Promise<{ txHash: string; settled: string; returned: string }> {
    const { userId, serviceId } = params;
    const channelKey = `${userId}:${serviceId}`;

    let state: ChannelState | null | undefined =
      this.activeChannels.get(channelKey);
    if (!state) {
      state = await this.loadChannelFromDb(userId, serviceId);
      if (!state) throw new Error(`No active channel for ${channelKey}`);
    }

    if (!state.latestProof) {
      throw new Error("No proof available to close channel with");
    }

    const proof = JSON.parse(state.latestProof) as {
      amount: number;
      signature: string;
    };
    const rpc = new Server(RPC_URL);

    // We need the receiver's secret key to call close — in production this
    // would be on the receiver's side. For Flare, receiver is the operator.
    const receiverSecret = process.env.OPERATOR_SECRET;
    if (!receiverSecret)
      throw new Error("OPERATOR_SECRET required to close channel");
    const receiverKeypair = Keypair.fromSecret(receiverSecret);

    const account = await rpc.getAccount(receiverKeypair.publicKey());
    const channelContract = new Contract(state.contractAddress);

    const closeTx = new TransactionBuilder(account, {
      fee: "100000",
      networkPassphrase: NETWORK_PASSPHRASE,
    })
      .addOperation(
        channelContract.call(
          "close",
          nativeToScVal(BigInt(proof.amount), { type: 'i128' }),
          xdr.ScVal.scvBytes(Buffer.from(proof.signature, "hex")),
        ),
      )
      .setTimeout(60)
      .build();

    const simResult = await rpc.simulateTransaction(closeTx);
    if (Api.isSimulationError(simResult)) {
      throw new Error(
        `Close simulation failed: ${JSON.stringify(simResult.error)}`,
      );
    }

    const preparedTx = assembleTransaction(closeTx, simResult).build();
    preparedTx.sign(receiverKeypair);

    const sendResult = await rpc.sendTransaction(preparedTx);
    if (sendResult.status !== "PENDING") {
      throw new Error(
        `Close TX submission failed: ${JSON.stringify(sendResult)}`,
      );
    }

    console.log(`[MPP] Close TX submitted: ${sendResult.hash}`);
    await waitForTransaction(rpc, sendResult.hash);

    const settled = state.spent.toFixed(7);
    const returned = (state.deposit - state.spent).toFixed(7);

    // Update DB
    await pool.query(
      `UPDATE mpp_channels SET status='closed', close_tx_hash=$1 WHERE channel_id=$2`,
      [sendResult.hash, state.channelId],
    );

    this.activeChannels.delete(channelKey);

    console.log(
      `[MPP] OK: Channel closed: ${state.channelId} | Settled: ${settled} USDC | Returned: ${returned} USDC`,
    );
    return { txHash: sendResult.hash, settled, returned };
  }

  // ----------------------------------------------------
  // Get Channel Status
  // ----------------------------------------------------
  async getChannelStatus(
    userId: string,
    serviceId: string,
  ): Promise<ChannelState | null> {
    const channelKey = `${userId}:${serviceId}`;
    if (this.activeChannels.has(channelKey)) {
      return this.activeChannels.get(channelKey)!;
    }
    return await this.loadChannelFromDb(userId, serviceId);
  }

  // ----------------------------------------------------
  // Auto-close Expired Channels
  // ----------------------------------------------------
  async autoCloseExpiredChannels(): Promise<void> {
    const tenMinsFromNow = new Date(Date.now() + 10 * 60 * 1000);
    const { rows } = await pool.query(
      `SELECT * FROM mpp_channels WHERE status='open' AND expires_at <= $1`,
      [tenMinsFromNow.toISOString()],
    );

    for (const row of rows) {
      console.log(
        `[MPP] Auto-closing expiring channel: ${row.channel_id} for user: ${row.user_id}`,
      );
      try {
        await this.closeChannel({
          userId: row.user_id,
          serviceId: row.service_id,
        });
      } catch (err) {
        console.error(
          `[MPP] Failed to auto-close channel ${row.channel_id}:`,
          err,
        );
        // Mark as expired in DB anyway
        await pool.query(
          `UPDATE mpp_channels SET status='expired' WHERE channel_id=$1`,
          [row.channel_id],
        );
      }
    }
  }

  // ----------------------------------------------------
  // Internal: Load from DB
  // ----------------------------------------------------
  private async loadChannelFromDb(
    userId: string,
    serviceId: string,
  ): Promise<ChannelState | null> {
    const { rows } = await pool.query(
      `SELECT * FROM mpp_channels WHERE user_id=$1 AND service_id=$2 AND status='open' LIMIT 1`,
      [userId, serviceId],
    );
    if (!rows.length) return null;

    const row = rows[0];

    // Decrypt commitment secret key
    const encryptionKey = process.env.ENCRYPTION_KEY || "";
    let commitmentSecretKey = "";
    if (row.commitment_secret_key_encrypted) {
      try {
        commitmentSecretKey = decrypt(
          row.commitment_secret_key_encrypted,
          encryptionKey,
        );
      } catch (err) {
        console.error(
          `[MPP] Failed to decrypt commitment secret key for channel ${row.channel_id}:`,
          err,
        );
      }
    }

    return {
      channelId: row.channel_id,
      contractAddress: row.channel_id,
      senderAddress: row.sender_address,
      receiverAddress: row.receiver_address,
      commitmentPublicKey: row.commitment_public_key || "",
      commitmentSecretKey: commitmentSecretKey,
      deposit: parseFloat(row.deposit_usdc),
      spent: parseFloat(row.spent_usdc),
      latestProof: row.latest_proof,
      openedAt: new Date(row.opened_at),
      expiresAt: new Date(row.expires_at),
      txHashOpen: row.open_tx_hash,
      status: row.status,
    };
  }
}

export const mppChannelManager = new MPPChannelManager();
