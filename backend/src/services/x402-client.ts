import { Keypair, Networks, nativeToScVal, rpc, contract } from '@stellar/stellar-sdk';
import dotenv from 'dotenv';

dotenv.config();

export class X402Client {
    private rpcUrl: string;

    constructor() {
        this.rpcUrl = process.env.SOROBAN_RPC_URL || 'https://soroban-testnet.stellar.org';
    }

    /**
     * Helper to make a preflight request to check what an endpoint charges.
     * Returns the required amount and asset contract ID without paying.
     */
    async getPaymentCost(url: string, method: string = 'GET', body?: any): Promise<{ amount: string, asset: string } | null> {
        const fetchOptions: RequestInit = {
            method,
            headers: {
                'Content-Type': 'application/json'
            }
        };
        if (body && ['POST', 'PUT', 'PATCH'].includes(method.toUpperCase())) {
            fetchOptions.body = JSON.stringify(body);
        }

        const response = await fetch(url, fetchOptions);
        
        if (response.status === 402) {
            const challenge = await response.json();
            if (challenge && challenge.accepts && challenge.accepts.length > 0) {
                 const accept = challenge.accepts[0];
                 return {
                     amount: accept.amount,
                     asset: accept.asset
                 };
            }
            throw new Error('402 Response received, but invalid x402 challenge format.');
        } else if (response.ok) {
            return null; // No payment required
        } else {
            throw new Error(`Failed to fetch cost: Returned status ${response.status}`);
        }
    }

    /**
     * Executes the full x402 payment flow.
     * 1. Fetches the URL.
     * 2. If 402, constructs and signs a Soroban auth entry for a USDC transfer.
     * 3. Retries the URL with the X-PAYMENT header.
     * 4. Returns the successful payload and transaction info.
     */
    async payAndFetch(params: {
        url: string,
        method: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE',
        body?: any,
        payerSecretKey: string
    }): Promise<{ data: any, txHash: string | null, amountPaid: string }> {

        const { url, method, body, payerSecretKey } = params;

        const fetchOptions: RequestInit = {
            method,
            headers: { 'Content-Type': 'application/json' }
        };
        
        if (body && ['POST', 'PUT', 'PATCH'].includes(method.toUpperCase())) {
            fetchOptions.body = JSON.stringify(body);
        }

        // 1. Initial Request
        const initialResponse = await fetch(url, fetchOptions);

        if (initialResponse.ok) {
            // Not paywalled or already authorized
            const data = await initialResponse.json().catch(() => null);
            return {
                data,
                txHash: null,
                amountPaid: "0"
            };
        }

        if (initialResponse.status !== 402) {
            throw new Error(`Endpoint returned non-402 status: ${initialResponse.status}`);
        }

        // 2. Parse 402 Challenge Requirements
        const challenge = await initialResponse.json();
        if (!challenge || !challenge.accepts || challenge.accepts.length === 0) {
             throw new Error('Invalid x402 challenge shape');
        }

        const accept = challenge.accepts[0];
        
        // 3. Build the Soroban USDC Transfer
        const keypair = Keypair.fromSecret(payerSecretKey);
        const publicKey = keypair.publicKey();

        const assembledTx = await contract.AssembledTransaction.build({
            contractId: accept.asset,
            method: "transfer",
            args: [
              nativeToScVal(publicKey, { type: "address" }),
              nativeToScVal(accept.payTo, { type: "address" }),
              nativeToScVal(BigInt(accept.amount), { type: "i128" }),
            ],
            networkPassphrase: Networks.TESTNET, // Assuming testnet for now as per project context
            rpcUrl: this.rpcUrl,
            parseResultXdr: (r: any) => r,
        });

        // 4. Sign Auth Entries
        const signer = contract.basicNodeSigner(keypair, Networks.TESTNET);
        const simData = assembledTx.simulation as any;
        const latestLedger = simData.latestLedger;

        await assembledTx.signAuthEntries({
            signAuthEntry: signer.signAuthEntry,
            expiration: latestLedger + 12, // Expiration bounded slightly in the future
        });

        // 5. Re-simulate in Enforcing Mode
        await assembledTx.simulate();
        
        if (!assembledTx.built) {
            throw new Error("Failed to build assembled transaction after simulation.");
        }
        
        const finalXDR = assembledTx.built.toXDR();

        // 6. Build the X-PAYMENT Payload Header
        const paymentPayload = Buffer.from(JSON.stringify({
            x402Version: 2,
            accepted: accept,
            payload: { transaction: finalXDR },
        })).toString("base64");

        // 7. Retry Original Request with X-PAYMENT
        const retryHeaders = new Headers(fetchOptions.headers);
        retryHeaders.set("X-PAYMENT", paymentPayload);

        const paidResponse = await fetch(url, {
            ...fetchOptions,
            headers: retryHeaders
        });

        if (!paidResponse.ok) {
           const errorBody = await paidResponse.text();
           throw new Error(`Payment failed or rejected by server (Status ${paidResponse.status}): ${errorBody}`);
        }

        const finalData = await paidResponse.json().catch(() => null);

        // Check if the server returned the executed transaction hash to us (standard x402 pattern)
        const returnedTxHash = paidResponse.headers.get('X-TRANSACTION-HASH') || null;

        return {
            data: finalData,
            txHash: returnedTxHash, // In a perfectly tracked system, the facilitator returns this
            amountPaid: accept.amount
        };
    }
}

export const x402Client = new X402Client();
