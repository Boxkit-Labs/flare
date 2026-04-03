import { Keypair, Networks, nativeToScVal, rpc, Contract, Asset } from '@stellar/stellar-sdk';

const RPC_URL = 'https://soroban-testnet.stellar.org';
const rpcServer = new rpc.Server(RPC_URL);

const BUYER_SECRET = "SAFIYIKN2LHEASCATRDY2BSZOB43C6BYHBX5OTZLZ5S3NITOS2C3HWWW";
const OPERATOR_PUBLIC = "GAAA5FUU6WCF3DYL7NBGOFM4VOZUXO5SDKCDOXA5EBQJTYAS7RD63235";
const CUSTOM_USDC_CONTRACT = "CCWNOXVY5MBZCYHTOAE4PBZ6YQ44X2SFH2VOC3VDHNV2J55KV3EHZ6PS";

async function debugSimulation() {
    const keypair = Keypair.fromSecret(BUYER_SECRET);
    const publicKey = keypair.publicKey();
    const passphrase = Networks.TESTNET;

    console.log(`[DEBUG] Simulating transfer...`);
    console.log(`  From: ${publicKey}`);
    console.log(`  To: ${OPERATOR_PUBLIC}`);
    console.log(`  Contract: ${CUSTOM_USDC_CONTRACT}`);

    const contract = new Contract(CUSTOM_USDC_CONTRACT);
    const tx = new TransactionBuilder(await rpcServer.getAccount(publicKey), {
        fee: "100",
        networkPassphrase: passphrase
    })
    .addOperation(contract.call("transfer", 
        nativeToScVal(publicKey, { type: "address" }),
        nativeToScVal(OPERATOR_PUBLIC, { type: "address" }),
        nativeToScVal(BigInt(10000000), { type: "i128" }) // 10 USDC-6 decimals? No, let's try 1 USDC.
    ))
    .setTimeout(30)
    .build();

    const sim = await rpcServer.simulateTransaction(tx);
    console.log("[DEBUG] Simulation Raw Result:", JSON.stringify(sim, (key, value) =>
        typeof value === 'bigint' ? value.toString() : value, 2));

    if (sim.error) {
        console.error("[DEBUG] Simulation Error:", sim.error);
    }
}

// Simple TransactionBuilder helper for debug
import { TransactionBuilder } from '@stellar/stellar-sdk';

debugSimulation().catch(console.error);
