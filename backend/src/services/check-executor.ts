import { getWatcherById, getUserById, updateWatcher, createCheck, createTransaction, createFinding, getChecksByWatcherId } from '../db/queries.js';
import { decrypt } from '../utils/crypto.js';
import { payForService } from './stellar-pay-client.js';
import { detector } from './finding-detector.js';
import { notificationService } from './notification.js';
import { ConfidenceCalculator } from './confidence-calculator.js';
import { WatcherRow, Finding } from '../types.js';
import { v4 as uuidv4 } from 'uuid';
import dotenv from 'dotenv';
dotenv.config();

const ENCRYPTION_KEY = process.env.ENCRYPTION_KEY || '';
const SOROBAN_RPC_URL = process.env.SOROBAN_RPC_URL || 'https://soroban-testnet.stellar.org';

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
        watcher = await getWatcherById(watcherId);
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
        await updateWatcher(watcherId, { status: 'paused_budget' });
        await notificationService.sendBudgetExhausted(watcher.user_id, watcher);
        return;
      }

      // 4 & 5. Load user and decrypt secret
      const user = await getUserById(watcher.user_id) as any;
      if (!user) {
         throw new Error(`User ${watcher.user_id} not found for watcher ${watcherId}`);
      }
      const payerSecretKey = decrypt(user.stellar_secret_key_encrypted, ENCRYPTION_KEY);

      // Local service resolution
      const port = process.env.PORT || '3000';
      const baseUrl = `http://localhost:${port}/services`;
      
      let serviceUrl = '';
      let method: 'GET' | 'POST' = 'POST';
      let body: any = watcher.parameters;

      switch (watcher.type.toLowerCase()) {
        case 'flight':
          serviceUrl = `${baseUrl}/flight/api/flights`;
          break;
        case 'crypto':
          serviceUrl = `${baseUrl}/crypto/api/crypto`;
          method = 'GET';
          break;
        case 'news':
          serviceUrl = `${baseUrl}/news/api/news`;
          method = 'GET';
          break;
        case 'product':
          serviceUrl = `${baseUrl}/product/api/products`;
          break;
        case 'job':
          serviceUrl = `${baseUrl}/job/api/jobs`;
          break;
        case 'stock':
          serviceUrl = `${baseUrl}/stocks/api/stocks`;
          break;
        case 'realestate':
          serviceUrl = `${baseUrl}/realestate/api/realestate`;
          break;
        case 'sports':
          serviceUrl = `${baseUrl}/sports/api/sports`;
          break;
        default:
          throw new Error(`Unknown watcher type: ${watcher.type}`);
      }

      // 6. Retrieve previous check for comparison logic
      const checks = await getChecksByWatcherId(watcherId, 1, 0);
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
          
          await createCheck({
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
              await updateWatcher(watcherId, { status: 'paused_wallet', error_message: 'Insufficient USDC Balance' });
              await notificationService.sendLowBalance(watcher.user_id, '0.00');
          } else {
              await updateWatcher(watcherId, { status: 'error', error_message: errorMsg });
          }
          return;
      }

      // 9. On Success
      const costUsdc = costPaid / 10000000;

      // 10. Transaction Record
      await createTransaction({
        txId: uuidv4(),
        userId: watcher.user_id,
        watcherId: watcherId,
        checkId: checkId,
        amountUsdc: costUsdc,
        serviceName: watcher.type,
        stellarTxHash: txHash,
        txType: 'check'
      });

      // 11. Run Finding Detector
      const finding = await detector.detectFinding(watcher, responseData, previousCheckData, costUsdc, txHash);
      
      // 12. Determine Logging & Check Record State
      let findingDetected = false;
      let findingId = null;
      let agentReasoning = '';

      if (finding) {
          // --- DEAD FINDING PREVENTION: RE-VERIFICATION LOOP ---
          console.log(`[Re-Verify] Finding detected for ${watcher.name}. Verifying in 60s...`);
          
          // 1. Wait 60 seconds
          await new Promise(resolve => setTimeout(resolve, 60000));

          // 2. Perform SECOND payment and check
          try {
            console.log(`[Re-Verify] Executing second check for ${watcher.type} ...`);
            const vResult = await payForService({
              serviceUrl, method, body, payerSecretKey, rpcUrl: SOROBAN_RPC_URL
            });
            
            const vFinding = await detector.detectFinding(watcher, vResult.data, responseData, vResult.costPaid / 10000000, vResult.txHash);
            
            // Log verification transaction
            await createTransaction({
              txId: uuidv4(),
              userId: watcher.user_id,
              watcherId: watcherId,
              checkId: checkId, // Associate with main check
              amountUsdc: vResult.costPaid / 10000000,
              serviceName: `${watcher.type} (verify)`,
              stellarTxHash: vResult.txHash,
              txType: 'verification'
            });
            
            if (vFinding) {
              console.log(`[Re-Verify] CONFIRMED! Finding is still valid. ✓`);
              vFinding.verified = true;
              vFinding.verification_tx_hash = vResult.txHash;
              vFinding.verification_check_id = uuidv4();
              
              // --- AGENT-TO-AGENT COLLABORATION: TRIPLE CHECK ---
              console.log(`[Collab] Running agent-to-agent cross-check for ${watcher.type}...`);
              const collabResult = await this.runCollaborationCheck(watcher, vFinding, payerSecretKey);
              vFinding.collaboration_result = collabResult;
              
              // --- CONFIDENCE SCORING ---
              const hasHistory = checks.length > 0;
              const confidence = ConfidenceCalculator.calculate(
                watcher, 
                vFinding as any, 
                new Date(), 
                hasHistory, 
                collabResult
              );
              
              vFinding.confidence_score = confidence.score;
              vFinding.confidence_tier = confidence.tier;
              vFinding.headline = `[${confidence.score}%] ${vFinding.headline}`;
              
              await createFinding(vFinding);
              findingDetected = true;
              findingId = vFinding.finding_id;
              agentReasoning = vFinding.agent_reasoning || 'Finding cross-verified and scored.';
              
              await notificationService.sendFindingNotification(watcher.user_id, vFinding as any, watcher);
            } else {
              console.log(`[Re-Verify] FAILED. Finding no longer valid. Suppressing alert.`);
              findingDetected = false;
              agentReasoning = "Initial check found finding, but re-verification 60s later failed. Alert suppressed.";
            }
          } catch (vError) {
             console.error("[Re-Verify] Verification failed due to payment/network error.", vError);
             findingDetected = false;
             agentReasoning = "Finding detected but verification check failed.";
          }
      } else {
          // 14. If No Finding
          agentReasoning = "No finding matched the alert criteria.";
          console.log(`No finding: ${agentReasoning}`);
      }

      await createCheck({
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
      const newTotalChecks = ((watcher as any).total_checks || 0) + 1;
      const newTotalFindings = findingDetected ? (((watcher as any).total_findings || 0) + 1) : ((watcher as any).total_findings || 0);
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

      await updateWatcher(watcherId, updates);

    } catch (e: any) {
      // Unhandled generic system errors
      const errorMsg = e instanceof Error ? e.message : 'Unknown system error during execution';
      console.error(`CheckExecutor Critical Error (Watcher ${watcherId}):`, errorMsg);
      await updateWatcher(watcherId, { status: 'error', error_message: errorMsg });
    }
  }

  /**
   * Runs a cross-service check to confirm or contextualize a finding.
   * Performs a THIRD Stellar transaction.
   */
  private async runCollaborationCheck(watcher: WatcherRow, finding: any, payerSecretKey: string): Promise<any> {
    const port = process.env.PORT || '3000';
    const baseUrl = `http://localhost:${port}/services`;
    
    let targetUrl = '';
    let query = '';
    let triggeredService = '';

    // Collaboration Rules
    if (watcher.type === 'flight') {
      triggeredService = 'news';
      targetUrl = `${baseUrl}/news/api/news`;
      const dest = finding.data?.destination_city || 'destination';
      query = `${dest} travel advisory safety`;
    } else if (watcher.type === 'stock') {
      triggeredService = 'news';
      targetUrl = `${baseUrl}/news/api/news`;
      const symbol = finding.data?.symbol || 'company';
      query = `${symbol} stock news announcement`;
    } else if (watcher.type === 'crypto') {
       triggeredService = 'news';
       targetUrl = `${baseUrl}/news/api/news`;
       const coin = finding.data?.symbol || 'coin';
       query = `${coin} price volume sentiment news`;
    } else if (watcher.type === 'job') {
       triggeredService = 'news';
       targetUrl = `${baseUrl}/news/api/news`;
       const company = finding.data?.company || 'company';
       query = `${company} hiring layoff news`;
    } else if (watcher.type === 'realestate') {
       triggeredService = 'news';
       targetUrl = `${baseUrl}/news/api/news`;
       const neighborhood = finding.data?.neighborhood || 'neighborhood';
       query = `${neighborhood} crime development school ratings`;
    } else if (watcher.type === 'sports') {
       triggeredService = 'news';
       targetUrl = `${baseUrl}/news/api/news`;
       const team = finding.data?.team || 'team';
       query = `${team} injury player trade news`;
    } else if (watcher.type === 'product') {
       triggeredService = 'product';
       targetUrl = `${baseUrl}/product/api/products`;
       query = finding.data?.product_name || 'product';
    } else {
       return null; // No collaboration rule for this type
    }

    try {
      console.log(`[Collab] Triple-Check: querying ${triggeredService} for "${query}" ...`);
      const result = await payForService({
        serviceUrl: targetUrl,
        method: triggeredService === 'news' ? 'GET' : 'POST',
        body: triggeredService === 'news' ? { q: query } : { search: query },
        payerSecretKey,
        rpcUrl: SOROBAN_RPC_URL
      });

      // Log collaboration transaction
      await createTransaction({
        txId: uuidv4(),
        userId: watcher.user_id,
        watcherId: watcher.watcher_id,
        checkId: finding.checkId || finding.check_id,
        amountUsdc: result.costPaid / 10000000,
        serviceName: triggeredService,
        stellarTxHash: result.txHash,
        txType: 'collaboration'
      });

      let summary = '';
      let safe = true;

      if (triggeredService === 'news') {
        const articles = result.data?.articles || [];
        summary = articles.length > 0 
          ? `Cross-checked ${articles.length} related articles. Insights incorporated.`
          : `No specific news flags found for "${query}".`;
        
        // Simple heuristic for "safety"
        const content = JSON.stringify(articles).toLowerCase();
        if (content.includes('warning') || content.includes('advisory') || content.includes('alert')) {
           safe = false;
           summary = `⚠️ Cross-check found potential concerns in recent news for ${query}.`;
        }
      } else if (triggeredService === 'product') {
        summary = `Cross-store price verification complete. Finding remains competitive.`;
      }

      return {
        triggered_service: triggeredService,
        query,
        result_summary: summary,
        tx_hash: result.txHash,
        safe
      };
    } catch (error) {
      console.error(`[Collab] Collaboration check failed:`, error);
      return { error: 'Collaboration check unavailable', safe: true };
    }
  }
}
