import dotenv from 'dotenv';
import path from 'path';
// Adjust dotenv path when running from inside the backend folder
dotenv.config({ path: path.join(process.cwd(), '.env') });

import { StellarService } from '../src/services/stellar.js';
import {
    Keypair,
    SorobanRpc,
    Networks,
    TransactionBuilder,
    Address,
    Contract,
    nativeToScVal,
    BASE_FEE
} from '@stellar/stellar-sdk';

const USDC_CONTRACT = 'CBIELTK6YBZJU5UP2WWQEUCYKLPU6AUNZ2BQ4WWFEIE3USCIHMXQDAMA';
const SOROBAN_RPC_URL = process.env.SOROBAN_RPC_URL || 'https://soroban-testnet.stellar.org';
const TARGET_URL = 'http://localhost:3001/test';

async function runTest() {
    console.log('\n--- [Direct Stellar Paywall Verification] ---');
    console.log(`Target: ${TARGET_URL}`);

    try {
        const stellar = new StellarService();

        // 1. Create test wallet
        console.log('\n[1/4] Creating test wallet...');
        const keypair = Keypair.random();
        console.log(`Public Key: ${keypair.publicKey()}`);

        // 2. Fund with Friendbot
        console.log('[2/4] Funding with Friendbot (XLM)...');
        await stellar.fundWithFriendbot(keypair.publicKey());

        // 3. Add USDC Trustline
        console.log('[3/4] Adding USDC trustline...');
        await stellar.addUsdcTrustline(keypair.secret());

        // 4. Fund with 5 USDC from operator
        console.log('[4/4] Funding with 5 USDC from operator...');
        await stellar.fundNewUserWithUsdc(keypair.publicKey(), '5');

        await new Promise(resolve => setTimeout(resolve, 2000));
        const initialBalances = await stellar.getBalances(keypair.publicKey());
        console.log(`Initial Balances: XLM: ${initialBalances.xlm}, USDC: ${initialBalances.usdc}`);

        // 5. Make initial request — expect 402
        console.log('\n[Phase 1] Making initial request (expecting 402)...');
        const challengeResponse = await fetch(TARGET_URL);
        
        if (challengeResponse.status !== 402) {
            throw new Error(`Expected 402, got ${challengeResponse.status}`);
        }

        const challenge = await challengeResponse.json() as any;
        console.log(`[Phase 1] Got 402. Payment required to: ${challenge.recipient}`);
        console.log(`[Phase 1] Amount: ${challenge.amount} stroops (${challenge.amountUsdc} USDC)`);

        // 6. Build and Submit Stellar Payment
        console.log('\n[Phase 2] Building and submitting payment to Stellar...');
        const rpc = new SorobanRpc.Server(SOROBAN_RPC_URL);
        const account = await rpc.getAccount(keypair.publicKey());
        const contract = new Contract(USDC_CONTRACT);

        const transferOp = contract.call(
            'transfer',
            new Address(keypair.publicKey()).toScVal(),
            new Address(challenge.recipient).toScVal(),
            nativeToScVal(BigInt(challenge.amount), { type: 'i128' })
        );

        let tx = new TransactionBuilder(account, {
            fee: BASE_FEE,
            networkPassphrase: Networks.TESTNET,
        })
            .addOperation(transferOp)
            .setTimeout(60)
            .build();

        console.log('[Phase 2] Simulating transaction...');
        const simResult = await rpc.simulateTransaction(tx);
        if (SorobanRpc.Api.isSimulationError(simResult)) {
            throw new Error(`Simulation failed: ${(simResult as any).error}`);
        }

        const assembledTx = SorobanRpc.assembleTransaction(tx, simResult).build();
        assembledTx.sign(keypair);

        const txXdr = assembledTx.toXDR();
        console.log('[Phase 2] Submitting transaction to Stellar...');
        const rpcResponse = await fetch(SOROBAN_RPC_URL, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                jsonrpc: '2.0',
                id: 1,
                method: 'sendTransaction',
                params: { transaction: txXdr }
            })
        });
        
        const rpcResult = await rpcResponse.json() as any;
        if (rpcResult.error) {
            throw new Error(`Transaction submission failed: ${JSON.stringify(rpcResult.error)}`);
        }

        const submitResult = rpcResult.result;
        if (submitResult.status === 'ERROR') {
            throw new Error(`Transaction failed: ${JSON.stringify(submitResult)}`);
        }

        const txHash = submitResult.hash;
        console.log(`[Phase 2] Payment submitted! Hash: ${txHash}`);

/**
 * Helper to fetch transaction status directly from JSON-RPC to avoid SDK deserialization bugs.
 */
async function getTransactionStatus(rpcUrl: string, hash: string): Promise<any> {
    const response = await fetch(rpcUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            jsonrpc: '2.0',
            id: 1,
            method: 'getTransaction',
            params: { hash }
        })
    });
    const json = await response.json() as any;
    if (json.error) throw new Error(json.error.message);
    return json.result;
}

        // Wait for confirmation
        console.log('[Phase 2] Waiting for confirmation...');
        let confirmed = false;
        const startTime = Date.now();
        while (Date.now() - startTime < 45000) { // 45s timeout
            try {
                const getResult = await getTransactionStatus(SOROBAN_RPC_URL, txHash);
                if (getResult.status === 'SUCCESS') {
                    confirmed = true;
                    break;
                } else if (getResult.status === 'FAILED') {
                    throw new Error(`Transaction failed: ${JSON.stringify(getResult)}`);
                }
            } catch (e: any) {
                console.log(`[Phase 2] Poll failed: ${e.message}`);
            }
            await new Promise(resolve => setTimeout(resolve, 3000));
        }

        if (!confirmed) {
            throw new Error('Transaction confirmation timed out');
        }
        console.log('✅ Payment confirmed on-chain!');

        // 7. Retry request with x-stellar-tx header
        console.log('\n[Phase 3] Retrying with x-stellar-tx header...');
        const paidResponse = await fetch(TARGET_URL, {
            headers: {
                'x-stellar-tx': txHash
            }
        });

        if (!paidResponse.ok) {
            const errBody = await paidResponse.text();
            throw new Error(`Request failed (status ${paidResponse.status}): ${errBody}`);
        }

        const data = await paidResponse.json() as any;
        console.log('\n✅ ACCESS GRANTED!');
        console.log('Response Data:', JSON.stringify(data, null, 2));

        // 8. Replay check
        console.log('\n[Phase 4] Verifying replay protection (expecting 402)...');
        const replayResponse = await fetch(TARGET_URL, {
            headers: {
                'x-stellar-tx': txHash
            }
        });
        
        if (replayResponse.status === 402) {
            const err = await replayResponse.json() as any;
            if (err.error === 'tx_already_used') {
                console.log('✅ Replay protection confirmed!');
            } else {
                console.log('✅ Replay check success (error: ' + err.error + ')');
            }
        } else {
            console.log('❌ Replay check failed: request unexpectedly succeeded');
        }

        console.log('\n--- ALL TESTS PASSED ---');
    } catch (error: any) {
        console.log('\n--- FAIL ---');
        console.error(`Error: ${error.message}`);
        process.exit(1);
    }
}

runTest();
