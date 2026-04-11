import { Router, Request, Response } from 'express';
import * as queries from '../db/queries.js';
import { encrypt, decrypt } from '../utils/crypto.js';
import { stellarService } from '../services/stellar.js';
import { notificationService } from '../services/notification.js';

const router = Router();

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


/**
 * POST /api/users/register
 * Registers a new device and creates a Stellar keypair.
 */
router.post('/register', async (req: Request, res: Response) => {
    try {
        const { device_id } = req.body;
        if (!device_id) return res.status(400).json({ error: 'device_id is required' });

        // Check for existing user
        const existingUser = await queries.getUserByDeviceId(device_id) as User | undefined;
        if (existingUser) {
            const { stellar_secret_key_encrypted, ...userProfile } = existingUser;
            return res.json(userProfile);
        }

        // Generate Stellar Keypair
        const kp = stellarService.generateKeypair();
        const publicKey = kp.publicKey;
        const secretKey = kp.secretKey;

        // Encrypt Secret Key
        const encryptionKey = process.env.ENCRYPTION_KEY;
        if (!encryptionKey) throw new Error('ENCRYPTION_KEY not configured');
        const encryptedSecret = encrypt(secretKey, encryptionKey);

        // Save to DB
        const userId = crypto.randomUUID();
        await queries.createUser({
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
        const user = await queries.getUserById(userId) as User | undefined;
        if (!user) return res.status(404).json({ error: 'User not found' });

        const publicKey = user.stellar_public_key;
        const encryptionKey = process.env.ENCRYPTION_KEY!;
        const decryptedSecret = decrypt(user.stellar_secret_key_encrypted, encryptionKey);

        // Fetch current balances to see what's already done
        console.log(`[FUND] Checking current balances for ${publicKey}...`);
        const currentBalances = await stellarService.getBalances(publicKey);
        const hasXlm = parseFloat(currentBalances.xlm) > 0;
        const hasUsdc = parseFloat(currentBalances.usdc) > 0;

        // 1. Friendbot Funding (XLM)
        if (!hasXlm) {
            console.log(`[FUND] Step 1: Calling friendbot for ${publicKey}...`);
            const success = await stellarService.fundWithFriendbot(publicKey);
            if (!success) {
                throw new Error("Friendbot funding failed after all retries");
            }
            console.log('[FUND] Step 1: Success');
        } else {
            console.log('[FUND] Step 1: Already has XLM, skipping.');
        }

        // 2. Add USDC Trustline
        console.log('[FUND] Step 2: Ensuring USDC trustline exists...');
        await stellarService.addUsdcTrustline(decryptedSecret);
        console.log('[FUND] Step 2: Success. Waiting for ledger...');
        await new Promise(resolve => setTimeout(resolve, 2000));
        console.log('[FUND] Finalizing Step 3...');

        // 3. Transfer 1.0 USDC from Operator
        if (process.env.OPERATOR_SECRET) {
            console.log('[FUND] Step 3: Sending 1.0 USDC...');
            let attempts = 0;
            let success = false;
            while (attempts < 3 && !success) {
                try {
                    await stellarService.fundNewUserWithUsdc(publicKey, '1.0');
                    success = true;
                    console.log(`[FUND] Step 3: Success (Attempt ${attempts + 1})`);
                } catch (e: any) {
                    attempts++;
                    console.warn(`[FUND] Step 3: Attempt ${attempts} failed: ${e.message}. Retrying in 3s...`);
                    await new Promise(resolve => setTimeout(resolve, 3000));
                    if (attempts >= 3) throw e;
                }
            }
        } else {
            console.warn('[FUND] Step 3: Skipped (OPERATOR_SECRET missing)');
        }

        // Fetch final balances
        console.log('[FUND] Fetching final balances...');
        const balances = await stellarService.getBalances(publicKey);
        console.log(`[FUND] Done. Balances: XLM=${balances.xlm}, USDC=${balances.usdc}`);

        res.json({
            funded: true,
            xlm_balance: balances.xlm,
            usdc_balance: balances.usdc
        });
    } catch (error: any) {
        console.error('[FUND] Error during funding process:', error);
        res.status(500).json({ 
            error: error.message,
            stack: error.stack,
            detail: error.response?.data || null,
            full_error: JSON.stringify(error, Object.getOwnPropertyNames(error)),
            step_failed: error.message.includes('friendbot') ? 1 : 
                        error.message.includes('trustline') ? 2 : 3
        });
    }
});

/**
 * GET /api/users/:id
 * Fetches user profile and live wallet balances.
 */
router.get('/:id', async (req: Request, res: Response) => {
    try {
        const userId = req.params.id as string;
        const user = await queries.getUserById(userId) as User | undefined;
        if (!user) return res.status(404).json({ error: 'User not found' });

        const { stellar_secret_key_encrypted, ...profile } = user;

        const balancesResponse = await stellarService.getBalances(user.stellar_public_key);
        // Map to match the previous response format if frontend expects array, but mapping to object is better.
        // I will return the object directly as the frontend hasn't been built yet.
        res.json({ ...profile, balances: balancesResponse });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * POST /api/users/:id/fcm-token
 */
router.post('/:id/fcm-token', async (req: Request, res: Response) => {
    try {
        const { fcm_token } = req.body;
        const userId = req.params.id as string;
        await queries.updateUserFcmToken(userId, fcm_token);
        res.json({ success: true });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * POST /api/users/:id/test-notification
 */
router.post('/:id/test-notification', async (req: Request, res: Response) => {
    try {
        const userId = req.params.id as string;
        await notificationService.sendLowBalance(userId, '5.00');
        res.json({ success: true, message: 'Test notification sent.' });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * PUT /api/users/:id/settings
 */
router.put('/:id/settings', async (req: Request, res: Response) => {
    try {
        const userId = req.params.id as string;
        await queries.updateUser(userId, req.body); 
        const updated = await queries.getUserById(userId) as User | undefined;
        if (!updated) return res.status(404).json({ error: 'User not found' });
        const { stellar_secret_key_encrypted, ...profile } = updated;
        res.json(profile);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

export default router;
