import { getWatcherById, getUserById, updateWatcher, createCheck, createTransaction, createFinding, getChecksByWatcherId } from '../db/queries.js';
import { decrypt } from '../utils/crypto.js';
import { payForService } from './stellar-pay-client.js';
import { FindingDetector } from './finding-detector.js';
import { notificationService } from './notification.js';
import { WatcherRow } from '../types.js';
import { v4 as uuidv4 } from 'uuid';
import dotenv from 'dotenv';
dotenv.config();

const ENCRYPTION_KEY = process.env.ENCRYPTION_KEY || '';
const SOROBAN_RPC_URL = process.env.SOROBAN_RPC_URL || 'https://soroban-testnet.stellar.org';

const detector = new FindingDetector();

export class CheckExecutor {
  
  /**
   * Executes a single data check for a localized watcher.
   * Runs the x402 payment, fetches the data, and runs finding detection logic.
   */
  async runCheck(watcherId: string): Promise<void> {
    const checkId = uuidv4();
    let watcher: WatcherRow;

    // 1. Load watcher from database
    try {
        watcher = getWatcherById(watcherId);
        if (!watcher) {
            console.error(`CheckExecutor: Watcher ${watcherId} not found.`);
            return;
        }
    } catch (e) {
        console.error(`CheckExecutor: Failed to load watcher ${watcherId}`, e);
        return;
    }

    try {
      // 2. Verify status
      if (watcher.status !== 'active') {
        console.log(`CheckExecutor: Watcher ${watcherId} is ${watcher.status}. Skipping.`);
        return; 
      }

      // 3. Check budget limits
      if (watcher.spent_this_week_usdc >= watcher.weekly_budget_usdc) {
        console.warn(`CheckExecutor: Watcher ${watcherId} exceeded weekly budget. Pausing.`);
        updateWatcher(watcherId, { status: 'paused_budget' });
        await notificationService.sendBudgetExhausted(watcher.user_id, watcher);
        return;
      }

      // 4 & 5. Load user and decrypt secret
      const user = getUserById(watcher.user_id) as any;
      if (!user) {
         throw new Error(`User ${watcher.user_id} not found for watcher ${watcherId}`);
      }
      const payerSecretKey = decrypt(user.stellar_secret_key_encrypted, ENCRYPTION_KEY);

      // Extract service URL
      let serviceUrl = '';
      let method: 'GET' | 'POST' = 'POST';
      let body: any = watcher.parameters;

      switch (watcher.type.toLowerCase()) {
        case 'flight':
          serviceUrl = process.env.FLIGHT_SERVICE_URL || 'http://localhost:3001/api/flights';
          break;
        case 'crypto':
          serviceUrl = process.env.CRYPTO_SERVICE_URL || 'http://localhost:3001/crypto/api/crypto';
          method = 'GET';
          break;
        case 'news':
          serviceUrl = process.env.NEWS_SERVICE_URL || 'http://localhost:3001/news/api/news';
          method = 'GET';
          break;
        case 'product':
          serviceUrl = process.env.PRODUCT_SERVICE_URL || 'http://localhost:3001/product/api/products';
          break;
        case 'job':
          serviceUrl = process.env.JOB_SERVICE_URL || 'http://localhost:3001/job/api/jobs';
          break;
        default:
          throw new Error(`Unknown watcher type: ${watcher.type}`);
      }

      // 6. Retrieve previous check for comparison logic
      const checks = getChecksByWatcherId(watcherId, 1, 0);
      const previousCheckData = checks.length > 0 ? checks[0].response_data : null;

      // 7. Execute X402 Payment
      let responseData: any;
      let txHash: string;
      let costPaid: number;

      try {
          console.log(`Executing check for ${watcher.type} watcher: ${watcherId} ...`);
          const result = await payForService({
            serviceUrl,
            method,
            body,
            payerSecretKey,
            rpcUrl: SOROBAN_RPC_URL
          });
          responseData = result.data;
          txHash = result.txHash;
          costPaid = result.costPaid;
      } catch (payError: any) {
          // 8. If X402 Payment Fails
          const errorMsg = payError instanceof Error ? payError.message : 'Unknown payment error';
          console.error(`CheckExecutor Payment Error (Watcher ${watcherId}):`, errorMsg);
          
          createCheck({
             checkId: checkId,
             watcherId: watcherId,
             userId: watcher.user_id,
             serviceName: watcher.type,
             requestPayload: body,
             responseData: { error: errorMsg },
             costUsdc: 0,
             stellarTxHash: '',
             findingDetected: false,
             agentReasoning: `Payment failed: ${errorMsg}`
          });
          
          // Check if it's a balance issue based on common Soroban/Stellar errors
          const isBalanceIssue = errorMsg.toLowerCase().includes('insufficient balance') || 
                                 errorMsg.toLowerCase().includes('balanceerror') ||
                                 errorMsg.toLowerCase().includes('op_underfunded') ||
                                 errorMsg.toLowerCase().includes('tx_insufficient_balance');
          
          if (isBalanceIssue) {
              updateWatcher(watcherId, { status: 'paused_wallet', error_message: 'Insufficient USDC Balance' });
              await notificationService.sendLowBalance(watcher.user_id, '0.00');
          } else {
              updateWatcher(watcherId, { status: 'error', error_message: errorMsg });
          }
          return;
      }

      // 9. On Success
      const costUsdc = costPaid / 10000000;

      // 10. Transaction Record
      createTransaction({
        txId: uuidv4(),
        userId: watcher.user_id,
        watcherId: watcherId,
        checkId: checkId,
        amountUsdc: costUsdc,
        serviceName: watcher.type,
        stellarTxHash: txHash
      });

      // 11. Run Finding Detector
      const finding = await detector.detectFinding(watcher, responseData, previousCheckData, costUsdc, txHash);
      if (finding) {
          finding.check_id = checkId;
      }

      // 12. Determine Logging & Check Record State
      let findingDetected = false;
      let findingId = null;
      let agentReasoning = '';

      if (finding) {
          // 13. If Finding Detected
          createFinding(finding);
          findingDetected = true;
          findingId = finding.finding_id;
          agentReasoning = finding.agent_reasoning || 'Finding matched conditions.';
          console.log(`FINDING: ${finding.headline}`);
          
          await notificationService.sendFindingNotification(watcher.user_id, finding, watcher);
      } else {
          // 14. If No Finding
          agentReasoning = "No finding matched the alert criteria.";
          console.log(`No finding: ${agentReasoning}`);
      }

      createCheck({
        checkId: checkId,
        watcherId: watcherId,
        userId: watcher.user_id,
        serviceName: watcher.type,
        requestPayload: body,
        responseData: responseData,
        costUsdc: costUsdc,
        stellarTxHash: txHash,
        findingDetected: findingDetected,
        findingId: findingId,
        agentReasoning: agentReasoning
      });

      // 15. Update Watcher Details
      const newTotalChecks = (watcher as any).total_checks ? (watcher as any).total_checks + 1 : 1;
      const newTotalFindings = findingDetected ? ((watcher as any).total_findings ? (watcher as any).total_findings + 1 : 1) : ((watcher as any).total_findings || 0);
      const newSpentThisWeek = (watcher.spent_this_week_usdc || 0) + costUsdc;
      const newTotalSpent = ((watcher as any).total_spent_usdc || 0) + costUsdc;
      const nowStr = new Date().toISOString();

      // Check for 80% budget warning
      const percentUsed = (newSpentThisWeek / watcher.weekly_budget_usdc) * 100;
      if (percentUsed >= 80 && watcher.spent_this_week_usdc / watcher.weekly_budget_usdc * 100 < 80) {
          await notificationService.sendBudgetWarning(watcher.user_id, watcher, Math.round(percentUsed));
      }

      const updates: any = {
        last_check_at: nowStr,
        updated_at: nowStr,
        total_checks: newTotalChecks,
        total_findings: newTotalFindings,
        spent_this_week_usdc: newSpentThisWeek,
        total_spent_usdc: newTotalSpent
      };

      if (watcher.check_interval_minutes) {
         const nextDate = new Date();
         nextDate.setMinutes(nextDate.getMinutes() + watcher.check_interval_minutes);
         updates.next_check_at = nextDate.toISOString();
      }

      updateWatcher(watcherId, updates);

    } catch (e: any) {
      // Unhandled generic system errors
      const errorMsg = e instanceof Error ? e.message : 'Unknown system error during execution';
      console.error(`CheckExecutor Critical Error (Watcher ${watcherId}):`, errorMsg);
      updateWatcher(watcherId, { status: 'error', error_message: errorMsg });
    }
  }
}
