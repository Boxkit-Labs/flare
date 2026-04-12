import { Keypair, Networks, nativeToScVal, rpc, contract, Asset, Contract } from '@stellar/stellar-sdk';
import dotenv from 'dotenv';

dotenv.config();

export interface X402Challenge {
  amount: string;
  payTo: string;
  asset: string;
  network: string;
  route?: string;
}

export class X402Client {
    private rpcUrl: string;

    constructor() {
        this.rpcUrl = process.env.SOROBAN_RPC_URL || 'https://soroban-testnet.stellar.org';
    }

    private getContractId(assetId: string, network: string): string {

        if (assetId.startsWith('C') && assetId.length === 56) {
            return assetId;
        }

        if (assetId.toUpperCase().startsWith('USDC')) {
            const usdcCode = process.env.USDC_ASSET_CODE || 'USDC';
            const usdcIssuer = process.env.USDC_ISSUER || 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5';

            let asset: Asset;
            if (assetId.includes(':')) {
                const [, issuer] = assetId.split(':');
                asset = new Asset('USDC', issuer);
            } else {
                asset = new Asset(usdcCode, usdcIssuer);
            }

            const passphrase = network.includes('testnet') ? Networks.TESTNET : Networks.PUBLIC;
            return asset.contractId(passphrase);
        }

        if (assetId.includes(':')) {
            const [code, issuer] = assetId.split(':');
            const asset = new Asset(code, issuer);
            const passphrase = network.includes('testnet') ? Networks.TESTNET : Networks.PUBLIC;
            return asset.contractId(passphrase);
        }

        throw new Error(`Cannot resolve contract ID for asset: ${assetId}`);
    }

    private parseChallenge(challenge: any): X402Challenge {

        if (challenge.accepts && challenge.accepts.length > 0) {
            const accept = challenge.accepts[0];
            return {
                amount: accept.amount,
                payTo: accept.payTo,
                asset: accept.asset,
                network: accept.network || 'stellar:testnet',
                route: challenge.route
            };
        }

        if (challenge.assets && challenge.pay_to) {

            const assetInfo = challenge.assets.find((a: any) => a.asset === 'USDC') || challenge.assets[0];

            let atomicAmount = assetInfo.price;
            if (atomicAmount.includes('.')) {
                atomicAmount = (parseFloat(atomicAmount) * 10000000).toFixed(0);
            }

            return {
                amount: atomicAmount,
                payTo: challenge.pay_to,
                asset: assetInfo.asset,
                network: challenge.network === 'testnet' ? 'stellar:testnet' : 'stellar:pubnet',
                route: challenge.route
            };
        }

        throw new Error('Invalid x402 challenge shape');
    }

    async getPaymentCost(url: string, method: string = 'GET', body?: any): Promise<X402Challenge | null> {
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
            const challengeBody = await response.json();
            return this.parseChallenge(challengeBody);
        } else if (response.ok) {
            return null;
        } else {
            throw new Error(`Failed to fetch cost: Returned status ${response.status}`);
        }
    }

    private isContractId(asset: string): boolean {
        return /^C[A-Z2-7]{55}$/.test(asset);
    }

    async payAndFetch(params: {
        url: string,
        method: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE',
        body?: any,
        payerSecretKey: string
    }): Promise<{ data: any, txHash: string | null, amountPaid: string }> {

        const { url, method, body, payerSecretKey } = params;

        const keypair = Keypair.fromSecret(payerSecretKey);
        console.log('[X402] Keypair type:', typeof keypair);
        console.log('[X402] publicKey():', keypair.publicKey());
        try {
           console.log('[X402] x402-stellar package version: v1 compatibility mode');
        } catch(e) {}

        const fetchOptions: RequestInit = {
            method,
            headers: { 'Content-Type': 'application/json' }
        };

        if (body && ['POST', 'PUT', 'PATCH'].includes(method.toUpperCase())) {
            fetchOptions.body = JSON.stringify(body);
        }

        let response = await fetch(url, fetchOptions);

        if (response.status !== 402) {
            return {
                data: await response.json(),
                txHash: null,
                amountPaid: "0"
            };
        }

        const challenge = await response.json();
        const parsed = this.parseChallenge(challenge);

        const contractId = this.isContractId(parsed.asset)
            ? parsed.asset
            : this.getContractId(parsed.asset, parsed.network);

        const passphrase = parsed.network === 'stellar-testnet' || parsed.network === 'testnet' || parsed.network === 'stellar:testnet'
            ? Networks.TESTNET
            : Networks.PUBLIC;

        const publicKey = keypair.publicKey();
        const contractInstance = new Contract(contractId);

        console.log(`[X402] Building v1 transfer: from=${publicKey} to=${parsed.payTo} amount=${parsed.amount} contract=${contractId}`);

        const rpcServer = new rpc.Server(this.rpcUrl);
        const assembledTx = await contract.AssembledTransaction.build({
            contractId: contractId,
            method: "transfer",
            args: [
              nativeToScVal(publicKey, { type: "address" }),
              nativeToScVal(parsed.payTo, { type: "address" }),
              nativeToScVal(BigInt(parsed.amount)),
            ],
            networkPassphrase: passphrase,
            rpcUrl: this.rpcUrl,
            parseResultXdr: (r: any) => r,
        });

        const simData = assembledTx.simulation as any;

        if (!simData.auth && simData.result && simData.result.auth) {
            console.log('[X402] Promoting auth entries from result object');
            simData.auth = simData.result.auth;
        }

        if (!simData.auth || simData.auth.length === 0) {
            throw new Error("No auth entries returned for Soroban transfer simulation. check if account has enough balance/trustline.");
        }

        const signer = contract.basicNodeSigner(keypair, passphrase);
        const latestLedger = simData.latestLedger;

        await assembledTx.signAuthEntries({
            address: publicKey,
            signAuthEntry: signer.signAuthEntry,
            expiration: simData.latestLedger + 20,
        });

        const finalAssembled = await assembledTx.simulate();
        if (!finalAssembled.built) {
            throw new Error("Failed to build final transaction after signing auth entries");
        }

        const finalXDR = finalAssembled.built.toEnvelope().toXDR('base64');

        let nonce = "0";
        try {
            const auth0 = simData.auth[0] as any;

            nonce = auth0._attributes?.credentials?._value?._attributes?.nonce?._value?.toString()
                    || auth0.credentials?.address?.nonce?.toString()
                    || "0";
            console.log(`[X402] Extracted nonce: ${nonce}`);
        } catch (e) {
            console.warn(`[X402] Nonce extraction failed, defaulting to "0":`, e);
        }

        const paymentPayloadJSON = JSON.stringify({
            x402Version: 2,
            payload: {
                transaction: finalXDR
            }
        });

        const paymentPayload = Buffer.from(paymentPayloadJSON).toString("base64");

        console.log(`[X402] Retrying with defensive payload... hash=${finalAssembled.built.hash().toString('hex')} nonce=${nonce}`);

        const paidResponse = await fetch(url, {
            method,
            headers: {
                'X-PAYMENT': paymentPayload,
            },
        });

        if (!paidResponse.ok) {
           const errorBody = await paidResponse.text();
           throw new Error(`Payment failed or rejected by server (Status ${paidResponse.status}): ${errorBody}`);
        }

        const data = await paidResponse.json();
        const txHash = paidResponse.headers.get('X-STELLAR-TX-HASH');

        return {
            data,
            txHash,
            amountPaid: parsed.amount
        };
    }
}

export const x402Client = new X402Client();
