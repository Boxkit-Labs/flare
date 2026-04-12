import dotenv from 'dotenv';
import {
  Keypair,
  Networks,
  TransactionBuilder,
  Operation,
  xdr,
  Address
} from '@stellar/stellar-sdk';
import { Server } from '@stellar/stellar-sdk/rpc';
import crypto from 'node:crypto';

dotenv.config();

const SOROBAN_RPC_URL = 'https://soroban-testnet.stellar.org/';
const NETWORK_PASSPHRASE = Networks.TESTNET;

async function deployChannel() {
  const secretKey = process.env.OPERATOR_SECRET;
  const wasmHashHex = process.env.CHANNEL_WASM_HASH;

  if (!secretKey) {
    console.error('OPERATOR_SECRET is missing in .env');
    process.exit(1);
  }
  if (!wasmHashHex) {
    console.error('CHANNEL_WASM_HASH is missing in .env.');
    console.error('Upload the one-way-channel.wasm first with your Stellar CLI and then set CHANNEL_WASM_HASH.');
    process.exit(1);
  }

  const funderKeypair = Keypair.fromSecret(secretKey);
  const server = new Server(SOROBAN_RPC_URL);

  console.log(`Funder account: ${funderKeypair.publicKey()}`);

  try {
    const account = await server.getAccount(funderKeypair.publicKey());

    const commitmentKeypair = Keypair.random();
    console.log(`Commitment Public Key: ${commitmentKeypair.publicKey()}`);
    console.log(`Commitment Secret Key: ${commitmentKeypair.secret()} (SAVE THIS!)`);

    const wasmHashBuffer = Buffer.from(wasmHashHex, 'hex');
    const salt = crypto.randomBytes(32);

    const createContractArgs = new xdr.CreateContractArgs({
      contractIdPreimage: xdr.ContractIdPreimage.contractIdPreimageFromAddress(
        new xdr.ContractIdPreimageFromAddress({
          address: Address.fromString(funderKeypair.publicKey()).toScAddress(),
          salt,
        })
      ),
      executable: xdr.ContractExecutable.contractExecutableWasm(wasmHashBuffer),
    });

    const hostFunction = xdr.HostFunction.hostFunctionTypeCreateContract(createContractArgs);

    const operation = Operation.invokeHostFunction({
      func: hostFunction,
      auth: [],
    });

    const tx = new TransactionBuilder(account, {
      fee: '10000',
      networkPassphrase: NETWORK_PASSPHRASE,
    })
      .addOperation(operation)
      .setTimeout(30)
      .build();

    console.log('Simulating CreateContract transaction...');
    const simResult = await server.simulateTransaction(tx);
    const { assembleTransaction } = await import('@stellar/stellar-sdk/rpc');
    const preparedTx = assembleTransaction(tx, simResult).build();
    preparedTx.sign(funderKeypair);

    console.log('Submitting CreateContract transaction to Testnet...');
    const sendResponse = await server.sendTransaction(preparedTx);

    if (sendResponse.status !== 'PENDING') {
      console.error('Transaction failed to submit:', sendResponse);
      return;
    }

    console.log(`Transaction Hash: ${sendResponse.hash}`);
    console.log('Waiting for completion...');
    let res = await server.getTransaction(sendResponse.hash);

    while (res.status === 'NOT_FOUND') {
      await new Promise(r => setTimeout(r, 2000));
      res = await server.getTransaction(sendResponse.hash);
    }

    if (res.status === 'SUCCESS') {
      console.log('Channel contract deployed successfully!');
      if (res.returnValue) {
        const contractId = Address.fromScVal(res.returnValue).toString();
        console.log(`\nNew Channel Contract ID: ${contractId}`);
        console.log(`\nPlease save your Commitment Secret Key and Contract ID in your environment!`);
      }
    } else {
      console.error('Transaction failed on-chain:', res);
    }

  } catch (err) {
    console.error('Failed to deploy channel:', err);
  }
}

deployChannel();
