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
import { MppService } from './mpp-service.js';

const USDC_CONTRACT = 'CBIELTK6YBZJU5UP2WWQEUCYKLPU6AUNZ2BQ4WWFEIE3USCIHMXQDAMA';

export interface PayParams {
    serviceUrl: string;
    method: 'GET' | 'POST';
    body?: any;
    payerSecretKey: string;
    rpcUrl: string;
}

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

/**
 * Direct Stellar Payment client extracted from working test-x402.ts.
 */
export async function payForService(params: PayParams): Promise<{ data: any, txHash: string, costPaid: number }> {
    const { serviceUrl, method, body, payerSecretKey, rpcUrl } = params;
    
    // 1. Initial request to get challenge
    const fetchOptions: RequestInit = {
        method,
        headers: { 'Content-Type': 'application/json' }
    };
    if (body && method === 'POST') {
        fetchOptions.body = JSON.stringify(body);
    }

    const initialRes = await fetch(serviceUrl, fetchOptions);
    if (initialRes.status !== 402) {
        if (initialRes.ok) {
            return { data: await initialRes.json(), txHash: '', costPaid: 0 };
        }
        throw new Error(`Expected 402, got ${initialRes.status}: ${await initialRes.text()}`);
    }

    const challenge = await initialRes.json() as any;
    const recipient = challenge.recipient || challenge.payTo; // Support both naming schemes
    const amountStroops = challenge.amount;

    if (!recipient || !amountStroops) {
        throw new Error("Invalid x402 challenge: missing recipient or amount");
    }

    // --- MPP OFF-CHAIN SESSION PAYMENT ---
    if (MppService.isActive()) {
        const signature = await MppService.makePayment(Number(amountStroops));
        if (signature) {
            console.log(`[MPP] Making fast off-chain payment of ${amountStroops} stroops via channel`);
            const paidRes = await fetch(serviceUrl, {
                method,
                headers: {
                    'Content-Type': 'application/json',
                    'x-mpp-signature': signature
                },
                body: (body && method === 'POST') ? JSON.stringify(body) : undefined
            });

            if (!paidRes.ok) {
                const errBody = await paidRes.text();
                throw new Error(`MPP Paid request failed (${paidRes.status}): ${errBody}`);
            }

            return { data: await paidRes.json(), txHash: 'mpp-' + Date.now(), costPaid: Number(amountStroops) };
        } else {
             console.warn('[MPP] makePayment failed. Falling back to on-chain X402.');
        }
    }

    // --- STANDARD X402 ON-CHAIN PAYMENT ---
    const keypair = Keypair.fromSecret(payerSecretKey);
    const rpc = new SorobanRpc.Server(rpcUrl);
    const account = await rpc.getAccount(keypair.publicKey());
    const contract = new Contract(USDC_CONTRACT);

    const transferOp = contract.call(
        'transfer',
        new Address(keypair.publicKey()).toScVal(),
        new Address(recipient).toScVal(),
        nativeToScVal(BigInt(amountStroops), { type: 'i128' })
    );

    let tx = new TransactionBuilder(account, {
        fee: BASE_FEE,
        networkPassphrase: Networks.TESTNET,
    })
        .addOperation(transferOp)
        .setTimeout(60)
        .build();

    const simResult = await rpc.simulateTransaction(tx);
    if (SorobanRpc.Api.isSimulationError(simResult)) {
        throw new Error(`Simulation failed: ${JSON.stringify(simResult)}`);
    }

    const assembledTx = SorobanRpc.assembleTransaction(tx, simResult).build();
    assembledTx.sign(keypair);

    let txXdr: string;
    try {
        txXdr = assembledTx.toXDR();
    } catch (e: any) {
        txXdr = (assembledTx as any).toEnvelope().toXDR('base64');
    }
    
    // Submit via raw fetch (matching test-x402.ts)
    const rpcResponse = await fetch(rpcUrl, {
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

    // 3. Poll for confirmation via raw fetch
    let confirmed = false;
    const startTime = Date.now();
    while (Date.now() - startTime < 45000) {
        try {
            const getResult = await getTransactionStatus(rpcUrl, txHash);
            if (getResult.status === 'SUCCESS') {
                confirmed = true;
                break;
            } else if (getResult.status === 'FAILED') {
                throw new Error(`Transaction execution failed: ${JSON.stringify(getResult)}`);
            }
        } catch (e: any) {
            // Wait and retry
        }
        await new Promise(resolve => setTimeout(resolve, 3000));
    }

    if (!confirmed) {
        throw new Error('Transaction confirmation timed out');
    }

    // 4. Final request with x-stellar-tx header
    const paidRes = await fetch(serviceUrl, {
        method,
        headers: {
            'Content-Type': 'application/json',
            'x-stellar-tx': txHash
        },
        body: (body && method === 'POST') ? JSON.stringify(body) : undefined
    });

    if (!paidRes.ok) {
        const errBody = await paidRes.text();
        throw new Error(`Paid request failed (${paidRes.status}): ${errBody}`);
    }

    return { data: await paidRes.json(), txHash, costPaid: amountStroops };
}
