import { Router, Request, Response } from 'express';
import { Horizon } from '@stellar/stellar-sdk';
import * as queries from '../db/queries.js';

const router = Router();
const server = new Horizon.Server('https://horizon-testnet.stellar.org');

/**
 * GET /api/wallet/:user_id
 * Fetches Stellar balances and basic spending stats.
 */
router.get('/:user_id', async (req: Request, res: Response) => {
    try {
        const userId = req.params.user_id as string;
        const user = await queries.getUserById(userId) as any;
        if (!user) return res.status(404).json({ error: 'User not found' });

        const publicKey = user.stellar_public_key;
        let usdcBalance = '0.0';
        let xlmBalance = '0.0';

        try {
            const account = await server.loadAccount(publicKey);
            xlmBalance = account.balances.find(b => b.asset_type === 'native')?.balance || '0.0';
            usdcBalance = account.balances.find(b => (b as any).asset_code === 'USDC')?.balance || '0.0';
        } catch (e) {
            // Account might not be funded yet
        }

        const stats = await queries.getSpendingStats(userId);

        res.json({
            public_key: publicKey,
            balance_usdc: usdcBalance,
            balance_xlm: xlmBalance,
            spent_today: (stats as any).spent_today || 0,
            spent_this_week: (stats as any).spent_this_week || 0
        });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * GET /api/wallet/:user_id/stats
 * Full analytics dashboard data.
 */
router.get('/:user_id/stats', async (req: Request, res: Response) => {
    try {
        const userId = req.params.user_id as string;
        const user = await queries.getUserById(userId) as any;
        if (!user) return res.status(404).json({ error: 'User not found' });

        const analytics = await queries.getWalletAnalytics(userId);
        
        // Subscription Savings Comparison
        const traditionalEstimate = 58.00; // Hardcoded per requirements
        const flareMonthlyEstimate = (user.global_daily_cap || 1.0) * 30;
        const savings = traditionalEstimate - flareMonthlyEstimate;

        const averageCostPerFinding = analytics.total_findings_all_time > 0 
            ? analytics.total_spent_all_time / analytics.total_findings_all_time
            : 0;

        res.json({
            daily_spending: analytics.daily_spending,
            per_watcher_spending: analytics.per_watcher_spending,
            total_checks_today: analytics.total_checks_today,
            total_findings_today: analytics.total_findings_today,
            average_cost_per_finding: averageCostPerFinding,
            subscription_comparison: {
                flare_monthly_estimate: flareMonthlyEstimate,
                traditional_estimate: traditionalEstimate,
                savings: savings > 0 ? savings : 0
            }
        });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

export default router;
