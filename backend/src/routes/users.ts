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

router.post('/register', async (req: Request, res: Response) => {
    try {
        const { device_id } = req.body;
        if (!device_id) return res.status(400).json({ error: 'device_id is required' });

        const existingUser = await queries.getUserByDeviceId(device_id) as User | undefined;
        if (existingUser) {
            const { stellar_secret_key_encrypted, ...userProfile } = existingUser;
            return res.json(userProfile);
        }

        const kp = stellarService.generateKeypair();
        const publicKey = kp.publicKey;
        const secretKey = kp.secretKey;

        const encryptionKey = process.env.ENCRYPTION_KEY;
        if (!encryptionKey) throw new Error('ENCRYPTION_KEY not configured');
        const encryptedSecret = encrypt(secretKey, encryptionKey);

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

router.post('/:id/fund', async (req: Request, res: Response) => {
    try {
        const userId = req.params.id as string;
        const user = await queries.getUserById(userId) as User | undefined;
        if (!user) return res.status(404).json({ error: 'User not found' });

        const publicKey = user.stellar_public_key;
        const encryptionKey = process.env.ENCRYPTION_KEY!;
        const decryptedSecret = decrypt(user.stellar_secret_key_encrypted, encryptionKey);

        console.log(`[FUND] Checking current balances for ${publicKey}...`);
        const currentBalances = await stellarService.getBalances(publicKey);
        const hasXlm = parseFloat(currentBalances.xlm) > 0;
        const hasUsdc = parseFloat(currentBalances.usdc) > 0;

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

        console.log('[FUND] Step 2: Ensuring USDC trustline exists...');
        await stellarService.addUsdcTrustline(decryptedSecret);
        console.log('[FUND] Step 2: Success. Waiting for ledger...');
        await new Promise(resolve => setTimeout(resolve, 2000));
        console.log('[FUND] Finalizing Step 3...');

        const FUNDING_AMOUNT = '100.0';

        if (process.env.OPERATOR_SECRET) {
            console.log(`[FUND] Step 3: Sending ${FUNDING_AMOUNT} USDC...`);
            let attempts = 0;
            let success = false;
            while (attempts < 3 && !success) {
                try {
                    await stellarService.fundNewUserWithUsdc(publicKey, FUNDING_AMOUNT);
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

         console.log('[FUND] Fetching final balances for verification...');
         const balances = await stellarService.getBalances(publicKey);
         console.log(`[FUND] Done. Final Balances: XLM=${balances.xlm}, USDC=${balances.usdc}`);

         const usdcBalance = parseFloat(balances.usdc || '0');
         if (usdcBalance < 100.0) {
             console.error(`[FUND] CRITICAL: USDC balance mismatch. Expected 100.0, got ${usdcBalance}`);

             if (usdcBalance === 0.1) {
                throw new Error('[FUND] Detected suspicious 0.1 USDC balance. Possible code version mismatch.');
             }
         }

         res.json({
             status: 'success',
             user_id: userId,
             stellar_public_key: publicKey,
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

router.get('/:id', async (req: Request, res: Response) => {
    try {
        const userId = req.params.id as string;
        const user = await queries.getUserById(userId) as User | undefined;
        if (!user) return res.status(404).json({ error: 'User not found' });

        const { stellar_secret_key_encrypted, ...profile } = user;

        const balancesResponse = await stellarService.getBalances(user.stellar_public_key);

        res.json({ ...profile, balances: balancesResponse });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

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

router.post('/:id/test-notification', async (req: Request, res: Response) => {
    try {
        const userId = req.params.id as string;
        await notificationService.sendLowBalance(userId, '5.00');
        res.json({ success: true, message: 'Test notification sent.' });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

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
