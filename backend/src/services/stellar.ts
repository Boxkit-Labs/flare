import { Horizon, Keypair, TransactionBuilder, Networks, Asset, Operation } from '@stellar/stellar-sdk';
import dotenv from 'dotenv';

dotenv.config();

export class StellarService {
    private server: Horizon.Server;
    private networkPassphrase: string;
    private usdcAsset: Asset;

    constructor() {
        const horizonUrl = process.env.HORIZON_URL || 'https://horizon-testnet.stellar.org';
        this.server = new Horizon.Server(horizonUrl);
        this.networkPassphrase = process.env.STELLAR_NETWORK || Networks.TESTNET;

        const usdcCode = process.env.USDC_ASSET_CODE || 'USDC';
        const usdcIssuer = process.env.USDC_ISSUER || 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5';
        this.usdcAsset = new Asset(usdcCode, usdcIssuer);
    }

    private async withRetry<T>(fn: () => Promise<T>, label: string, retries: number = 10): Promise<T> {
        for (let i = 0; i < retries; i++) {
            try {
                return await fn();
            } catch (error: any) {
                const isTransient =
                    error.message.includes('EAI_AGAIN') ||
                    error.message.includes('getaddrinfo') ||
                    error.message.includes('ENOTFOUND') ||
                    error.message.includes('ETIMEDOUT') ||
                    error.message.includes('ECONNREFUSED') ||
                    error.message.includes('ECONNRESET') ||
                    error.message.includes('fetch failed') ||
                    error.message.includes('timeout') ||
                    error.response?.status === 504 ||
                    error.response?.status === 502;

                if (isTransient && i < retries - 1) {
                    const waitTime = Math.pow(2, i) * 1000 + (Math.random() * 1000);

                    const actualWait = Math.min(waitTime, 30000);
                    console.warn(`[STELLAR] ${label} attempt ${i + 1} failed. Retrying in ${Math.round(actualWait)}ms... (${error.message})`);
                    await new Promise(resolve => setTimeout(resolve, actualWait));
                    continue;
                }

                if (!isTransient) {
                    console.error(`[STELLAR] Non-transient error in ${label}:`, error.message, error.name);
                }
                throw error;
            }
        }
        throw new Error(`[STELLAR] ${label} failed after ${retries} attempts`);
    }

    generateKeypair(): { publicKey: string, secretKey: string } {
        const keypair = Keypair.random();
        return {
            publicKey: keypair.publicKey(),
            secretKey: keypair.secret()
        };
    }

    async fundWithFriendbot(publicKey: string, retries: number = 10): Promise<boolean> {
        try {
            await this.withRetry(async () => {
                const response = await fetch(`https://friendbot.stellar.org?addr=${encodeURIComponent(publicKey)}`);
                if (!response.ok) {
                    const errorText = await response.text();
                    throw new Error(`Friendbot HTTP ${response.status}: ${errorText}`);
                }
                return true;
            }, "fundWithFriendbot", retries);
            return true;
        } catch (error: any) {
            console.error(`[STELLAR] All friendbot attempts failed for ${publicKey}: ${error.message}`);
            return false;
        }
    }

    async addUsdcTrustline(secretKey: string): Promise<string> {
        const sourceKeypair = Keypair.fromSecret(secretKey);
        const sourcePublicKey = sourceKeypair.publicKey();

        const account = await this.withRetry(() => this.server.loadAccount(sourcePublicKey), "loadAccount");

        const hasTrustline = account.balances.some(b =>
            'asset_code' in b && b.asset_code === this.usdcAsset.code && b.asset_issuer === this.usdcAsset.issuer
        );
        if (hasTrustline) {
            console.log(`[STELLAR] Trustline already exists for ${sourcePublicKey}, skipping.`);
            return 'EXISTS';
        }

        const fee = await this.withRetry(() => this.server.fetchBaseFee(), "fetchBaseFee");

        const transaction = new TransactionBuilder(account, {
            fee: fee.toString(),
            networkPassphrase: this.networkPassphrase
        })
        .addOperation(Operation.changeTrust({
            asset: this.usdcAsset
        }))
        .setTimeout(30)
        .build();

        transaction.sign(sourceKeypair);
        try {
            const response = await this.withRetry(() => this.server.submitTransaction(transaction), "submitTransaction");
            return response.hash;
        } catch (error: any) {
            console.error(`[STELLAR] Trustline failed for ${sourcePublicKey}:`, error.response?.data || error.message);

            const resultCodes = error?.response?.data?.extras?.result_codes;
            if (resultCodes?.operations?.includes('op_already_exists') || resultCodes?.transaction === 'tx_bad_seq') {
                 console.log(`[STELLAR] Redundant trustline or sequence error (likely already exists), skipping.`);
                 return 'EXISTS';
            }
            throw error;
        }
    }

    async sendUsdc(fromSecret: string, toPublic: string, amount: string): Promise<string> {
        const sourceKeypair = Keypair.fromSecret(fromSecret);
        const sourcePublicKey = sourceKeypair.publicKey();

        const account = await this.withRetry(() => this.server.loadAccount(sourcePublicKey), "loadAccount");
        const fee = await this.withRetry(() => this.server.fetchBaseFee(), "fetchBaseFee");

        const transaction = new TransactionBuilder(account, {
            fee: fee.toString(),
            networkPassphrase: this.networkPassphrase
        })
        .addOperation(Operation.payment({
            destination: toPublic,
            asset: this.usdcAsset,
            amount: amount,
        }))
        .setTimeout(30)
        .build();

        transaction.sign(sourceKeypair);
        try {
            const response = await this.withRetry(() => this.server.submitTransaction(transaction), "submitTransaction");
            return response.hash;
        } catch (error: any) {
            console.error(`[STELLAR] Transaction failed from ${sourcePublicKey}:`, JSON.stringify(error.response?.data || error.message));
            throw error;
        }
    }

    async getBalances(publicKey: string): Promise<{ xlm: string, usdc: string }> {
        try {
            const account = await this.withRetry(() => this.server.loadAccount(publicKey), "loadAccount");

            let xlmBalance = '0';
            let usdcBalance = '0';

            for (const balance of account.balances) {
                if (balance.asset_type === 'native') {
                    xlmBalance = balance.balance;
                } else if ('asset_code' in balance && balance.asset_code === this.usdcAsset.code && balance.asset_issuer === this.usdcAsset.issuer) {
                    usdcBalance = balance.balance;
                }
            }

            return { xlm: xlmBalance, usdc: usdcBalance };
        } catch (error: any) {
             if (error?.response?.status === 404) {
                 return { xlm: '0', usdc: '0' };
             }
             throw error;
        }
    }

    async fundNewUserWithUsdc(userPublicKey: string, amount: string): Promise<string> {
        const operatorSecret = process.env.OPERATOR_SECRET;
        if (!operatorSecret) {
            throw new Error("OPERATOR_SECRET environment variable is not defined");
        }
        return this.sendUsdc(operatorSecret, userPublicKey, amount);
    }

    async getTransaction(txHash: string): Promise<Horizon.ServerApi.TransactionRecord> {
        return this.withRetry(() => this.server.transactions().transaction(txHash).call(), "getTransaction");
    }
}

export const stellarService = new StellarService();
