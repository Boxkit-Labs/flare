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

    /**
     * Generates a new random Stellar keypair.
     */
    generateKeypair(): { publicKey: string, secretKey: string } {
        const keypair = Keypair.random();
        return {
            publicKey: keypair.publicKey(),
            secretKey: keypair.secret()
        };
    }

    /**
     * Funds an account using the Testnet friendbot. Includes retry logic.
     */
    async fundWithFriendbot(publicKey: string, retries: number = 3): Promise<boolean> {
        for (let i = 0; i < retries; i++) {
            try {
                const response = await fetch(`https://friendbot.stellar.org?addr=${encodeURIComponent(publicKey)}`);
                if (response.ok) {
                    return true;
                }
                const errorText = await response.text();
                console.warn(`Friendbot attempt ${i + 1} failed for ${publicKey}. Status: ${response.status}. Error: ${errorText}`);
            } catch (error: any) {
                console.warn(`Friendbot attempt ${i + 1} failed due to network error: ${error.message}`);
            }
            // Wait before retrying (exponential backoff)
            if (i < retries - 1) {
                await new Promise(resolve => setTimeout(resolve, Math.pow(2, i) * 1000));
            }
        }
        return false;
    }

    /**
     * Submits a transaction to add a trustline for USDC.
     */
    async addUsdcTrustline(secretKey: string): Promise<string> {
        const sourceKeypair = Keypair.fromSecret(secretKey);
        const sourcePublicKey = sourceKeypair.publicKey();

        const account = await this.server.loadAccount(sourcePublicKey);
        const fee = await this.server.fetchBaseFee();

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
        const response = await this.server.submitTransaction(transaction);
        return response.hash;
    }

    /**
     * Sends USDC from one account to another.
     */
    async sendUsdc(fromSecret: string, toPublic: string, amount: string): Promise<string> {
        const sourceKeypair = Keypair.fromSecret(fromSecret);
        const sourcePublicKey = sourceKeypair.publicKey();

        const account = await this.server.loadAccount(sourcePublicKey);
        const fee = await this.server.fetchBaseFee();

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
        const response = await this.server.submitTransaction(transaction);
        return response.hash;
    }

    /**
     * Returns the XLM and USDC balances for a public key.
     */
    async getBalances(publicKey: string): Promise<{ xlm: string, usdc: string }> {
        try {
            const account = await this.server.loadAccount(publicKey);
            
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
                 return { xlm: '0', usdc: '0' }; // Account not found/unfunded
             }
             throw error;
        }
    }

    /**
     * Funds a new user account with USDC from the operator wallet.
     */
    async fundNewUserWithUsdc(userPublicKey: string, amount: string): Promise<string> {
        const operatorSecret = process.env.OPERATOR_SECRET;
        if (!operatorSecret) {
            throw new Error("OPERATOR_SECRET environment variable is not defined");
        }
        return this.sendUsdc(operatorSecret, userPublicKey, amount);
    }

    /**
     * Fetches details for a specific transaction hash.
     */
    async getTransaction(txHash: string): Promise<Horizon.ServerApi.TransactionRecord> {
        return this.server.transactions().transaction(txHash).call();
    }
}

// Export a singleton instance
export const stellarService = new StellarService();
