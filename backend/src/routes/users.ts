import { Router, Request, Response } from 'express';
import { Keypair, Asset, TransactionBuilder, Networks, Operation, Horizon } from '@stellar/stellar-sdk';
import * as queries from '../db/queries';
import { encrypt, decrypt } from '../utils/crypto';

const router = Router();
const server = new Horizon.Server('https://horizon-testnet.stellar.org');

interface User {
    user_id: string;
    device_id: string;
    stellar_public_key: string;
    stellar_secret_key_encrypted: string;
    fcm_token?: string;
    briefing_time: string;
    timezone: string;
    dnd_start: string;
    dnd_end: string;
    global_daily_cap: number;
    created_at: string;
}

// USDC Testnet Configuration
const USDC_ASSET = new Asset(
    'USDC',
    'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5'
);

/**
 * POST /api/users/register
 * Registers a new device and creates a Stellar keypair.
 */
router.post('/register', async (req: Request, res: Response) => {
    try {
        const { device_id } = req.body;
        if (!device_id) return res.status(400).json({ error: 'device_id is required' });

        // Check for existing user
        const existingUser = queries.getUserByDeviceId(device_id) as User | undefined;
        if (existingUser) {
            const { stellar_secret_key_encrypted, ...userProfile } = existingUser;
            return res.json(userProfile);
        }

        // Generate Stellar Keypair
        const kp = Keypair.random();
        const publicKey = kp.publicKey();
        const secretKey = kp.secret();

        // Encrypt Secret Key
        const encryptionKey = process.env.ENCRYPTION_KEY;
        if (!encryptionKey) throw new Error('ENCRYPTION_KEY not configured');
        const encryptedSecret = encrypt(secretKey, encryptionKey);

        // Save to DB
        const userId = crypto.randomUUID();
        queries.createUser({
            userId,
            deviceId: device_id,
            stellarPublicKey: publicKey,
            stellarSecretKeyEncrypted: encryptedSecret,
            briefingTime: '07:00',
            timezone: 'UTC',
            dndStart: '23:00',
            dndEnd: '07:00',
            globalDailyCap: 1.0
        });

        res.json({
            user_id: userId,
            device_id,
            stellar_public_key: publicKey,
            created_at: new Date().toISOString()
        });
    } catch (error: any) {
        console.error('Registration error:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * POST /api/users/:id/fund
 * Automated Testnet funding (XLM Friendbot + USDC Trustline + 10 USDC Transfer)
 */
router.post('/:id/fund', async (req: Request, res: Response) => {
    try {
        const userId = req.params.id as string;
        const user = queries.getUserById(userId) as User | undefined;
        if (!user) return res.status(404).json({ error: 'User not found' });

        const publicKey = user.stellar_public_key;
        const encryptionKey = process.env.ENCRYPTION_KEY!;
        const decryptedSecret = decrypt(user.stellar_secret_key_encrypted, encryptionKey);
        const userKp = Keypair.fromSecret(decryptedSecret);

        // 1. Friendbot Funding (XLM)
        await fetch(`https://friendbot.stellar.org?addr=${publicKey}`);

        // 2. Add USDC Trustline
        const account = await server.loadAccount(publicKey);
        const txTrust = new TransactionBuilder(account, { fee: '100', networkPassphrase: Networks.TESTNET })
            .addOperation(Operation.changeTrust({ asset: USDC_ASSET }))
            .setTimeout(30)
            .build();
        txTrust.sign(userKp);
        await server.submitTransaction(txTrust);

        // 3. Transfer 10 USDC from Operator
        const operatorSecret = process.env.OPERATOR_SECRET;
        if (operatorSecret) {
            const operatorKp = Keypair.fromSecret(operatorSecret);
            const operatorAccount = await server.loadAccount(operatorKp.publicKey());
            const txPay = new TransactionBuilder(operatorAccount, { fee: '100', networkPassphrase: Networks.TESTNET })
                .addOperation(Operation.payment({
                    destination: publicKey,
                    asset: USDC_ASSET,
                    amount: '10.0'
                }))
                .setTimeout(30)
                .build();
            txPay.sign(operatorKp);
            await server.submitTransaction(txPay);
        }

        // Fetch final balances
        const finalAccount = await server.loadAccount(publicKey);
        const xlmBalance = finalAccount.balances.find(b => b.asset_type === 'native')?.balance;
        const usdcBalance = finalAccount.balances.find(b => (b as any).asset_code === 'USDC')?.balance;

        res.json({
            funded: true,
            xlm_balance: xlmBalance,
            usdc_balance: usdcBalance || '0.0'
        });
    } catch (error: any) {
        console.error('Funding error:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * GET /api/users/:id
 * Fetches user profile and live wallet balances.
 */
router.get('/:id', async (req: Request, res: Response) => {
    try {
        const userId = req.params.id as string;
        const user = queries.getUserById(userId) as User | undefined;
        if (!user) return res.status(404).json({ error: 'User not found' });

        const { stellar_secret_key_encrypted, ...profile } = user;

        let balances: any[] = [];
        try {
            const account = await server.loadAccount(user.stellar_public_key);
            balances = account.balances;
        } catch (e) {
            // Account might not be funded/created on ledger yet
        }

        res.json({ ...profile, balances });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * POST /api/users/:id/fcm-token
 */
router.post('/:id/fcm-token', (req: Request, res: Response) => {
    try {
        const { fcm_token } = req.body;
        const userId = req.params.id as string;
        queries.updateUserFcmToken(userId, fcm_token);
        res.json({ success: true });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * PUT /api/users/:id/settings
 */
router.put('/:id/settings', (req: Request, res: Response) => {
    try {
        const userId = req.params.id as string;
        queries.updateWatcher(userId, req.body); // Reusing logic for dynamic field update
        const updated = queries.getUserById(userId) as User | undefined;
        if (!updated) return res.status(404).json({ error: 'User not found' });
        const { stellar_secret_key_encrypted, ...profile } = updated;
        res.json(profile);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

export default router;
