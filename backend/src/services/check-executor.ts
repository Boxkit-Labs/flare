import { getWatcherById, getUserById, updateWatcher, createCheck, createTransaction, createFinding, getChecksByWatcherId } from '../db/queries.js';
import { decrypt } from '../utils/crypto.js';
import { payForService } from './stellar-pay-client.js';
import { FindingDetector } from './finding-detector.js';
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
    try {
      // 1. Load watcher from database
      const watcher: WatcherRow = getWatcherById(watcherId);
      if (!watcher) {
        console.error(`CheckExecutor: Watcher ${watcherId} not found.`);
        return;
      }

      // 2. Verify status
      if (watcher.status !== 'active') {
        return; // Silently abort, as scheduler shouldn't have launched this anyway
      }

      // 3. Check budget limits
      if (watcher.spent_this_week_usdc >= watcher.weekly_budget_usdc) {
        console.warn(`CheckExecutor: Watcher ${watcherId} exceeded weekly budget. Pausing.`);
        updateWatcher(watcherId, { status: 'paused_budget' });
        return;
      }

      // 4. Load user and decrypt secret
      const user = getUserById(watcher.user_id) as any;
      if (!user) {
         throw new Error(`User ${watcher.user_id} not found for watcher ${watcherId}`);
      }
      
      const payerSecretKey = decrypt(user.stellar_secret_key_encrypted, ENCRYPTION_KEY);

      // 5. Build service URL based on type
      let serviceUrl = '';
      let method: 'GET' | 'POST' = 'POST';
      let body: any = watcher.parameters;

      switch (watcher.type.toLowerCase()) {
        case 'flight':
          serviceUrl = 'http://localhost:3001/api/flights';
          break;
        case 'crypto':
          serviceUrl = 'http://localhost:3002/api/crypto';
          break;
        case 'news':
          serviceUrl = 'http://localhost:3003/api/news';
          break;
        case 'product':
          serviceUrl = 'http://localhost:3004/api/products';
          break;
        case 'job':
          serviceUrl = 'http://localhost:3005/api/jobs';
          break;
        default:
          throw new Error(`Unknown watcher type: ${watcher.type}`);
      }

      // 6 & 7. Call payForService
      console.log(`Executing check for ${watcher.type} watcher: ${watcherId} ...`);
      const { data: responseData, txHash, costPaid } = await payForService({
        serviceUrl,
        method,
        body,
        payerSecretKey,
        rpcUrl: SOROBAN_RPC_URL
      });

      // Normalize cost format (paid amount is in stroops, divide by 10M for USDC)
      const costUsdc = costPaid / 10000000;
      const checkId = uuidv4();

      // Retrieve previous check to do comparison logic
      const checks = getChecksByWatcherId(watcherId, 1, 0);
      const previousCheckData = checks.length > 0 ? checks[0].response_data : null;

      // Run Detector
      const finding = await detector.detectFinding(watcher, responseData, previousCheckData, costUsdc, txHash);
      if (finding) {
          finding.check_id = checkId; // Link it
      }

      // 8. On Success: Commit to DB
      
      // Transaction Record
      createTransaction({
        txId: uuidv4(),
        userId: watcher.user_id,
        watcherId: watcherId,
        checkId: checkId,
        amountUsdc: costUsdc,
        serviceName: watcher.type,
        stellarTxHash: txHash
      });

      // Check Record
      createCheck({
        checkId: checkId,
        watcherId: watcherId,
        userId: watcher.user_id,
        serviceName: watcher.type,
        requestPayload: body,
        responseData: responseData,
        costUsdc: costUsdc,
        stellarTxHash: txHash,
        findingDetected: !!finding,
        findingId: finding ? finding.finding_id : null,
        agentReasoning: finding ? finding.agent_reasoning : null
      });

      // Finding Record (if any)
      if (finding) {
        createFinding(finding);
      }

      // Update Watcher details
      const newTotalChecks = (watcher as any).total_checks ? (watcher as any).total_checks + 1 : 1;
      const newTotalFindings = finding ? ((watcher as any).total_findings ? (watcher as any).total_findings + 1 : 1) : (watcher as any).total_findings;
      const newSpentThisWeek = (watcher.spent_this_week_usdc || 0) + costUsdc;
      const newTotalSpent = ((watcher as any).total_spent_usdc || 0) + costUsdc;

      const updates: any = {
        last_check_at: new Date().toISOString(),
        total_checks: newTotalChecks,
        total_findings: newTotalFindings,
        spent_this_week_usdc: newSpentThisWeek,
        total_spent_usdc: newTotalSpent
      };

      // Recalculate next interval exactly based on current time + interval
      if (watcher.check_interval_minutes) {
         const nextDate = new Date();
         nextDate.setMinutes(nextDate.getMinutes() + watcher.check_interval_minutes);
         updates.next_check_at = nextDate.toISOString();
      }

      updateWatcher(watcherId, updates);
      console.log(`Check completed for ${watcherId}. Cost: ${costUsdc} USDC. Result: ${finding ? 'Finding Generated' : 'No findings.'}`);

    } catch (e: any) {
      // 9. On Failure
      const errorMsg = e instanceof Error ? e.message : 'Unknown check execution error';
      console.error(`CheckExecutor Error (Watcher ${watcherId}):`, errorMsg);
      updateWatcher(watcherId, { status: 'error', error_message: errorMsg });
    }
  }
}
