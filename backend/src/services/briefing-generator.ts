import { v4 as uuidv4 } from 'uuid';
import { getUserById, getChecksSince, getWatchersByUserId, createBriefing, getFindingById, getSpendingStats } from '../db/queries.js';
import { notificationService, NotificationService } from './notification.js';
import { CheckExecutor } from './check-executor.js';

export class BriefingGenerator {
  private notificationSvc: NotificationService;
  private checkExecutor: CheckExecutor | null = null;

  constructor() {
    this.notificationSvc = notificationService;
  }

  setCheckExecutor(executor: CheckExecutor) {
    this.checkExecutor = executor;
  }

  async generateBriefing(userId: string): Promise<any> {

    await this.triggerInitialChecks(userId);

    const user = await getUserById(userId) as any;
    if (!user) throw new Error(`User ${userId} not found`);

    const now = new Date();
    const periodEnd = now.toISOString();

    let periodStart: string;

    if (user.dnd_start) {
      const [h, m] = user.dnd_start.split(':').map(Number);
      const startDt = new Date(now);

      startDt.setUTCHours(h, m, 0, 0);

      if (startDt > now) {
          startDt.setUTCDate(startDt.getUTCDate() - 1);
      }
      periodStart = startDt.toISOString();
    } else {

      const twelveHoursAgo = new Date(now.getTime() - (12 * 60 * 60 * 1000));
      periodStart = twelveHoursAgo.toISOString();
    }

    const checks = await getChecksSince(userId, periodStart) as any[];

    const checkIds = checks.map(c => c.check_id);
    const findingsIds = checks.filter(c => c.finding_detected === 1).map(c => c.finding_id).filter(id => id);

    const watchers = await getWatchersByUserId(userId) as any[];

    const summaryMap = new Map<string, any>();

    for (const w of watchers) {
      summaryMap.set(w.watcher_id, {
        watcher_id: w.watcher_id,
        watcher_name: w.name,
        type: w.type,
        checks_run: 0,
        findings_count: 0,
        spent: 0,
        latest_data_summary: "No checks run overnight."
      });
    }

    checks.sort((a, b) => new Date(a.checked_at).getTime() - new Date(b.checked_at).getTime());

    for (const check of checks) {
       const wId = check.watcher_id;
       if (!summaryMap.has(wId)) continue;

       const target = summaryMap.get(wId);
       target.checks_run += 1;
       if (check.finding_detected === 1) target.findings_count += 1;
       target.spent += (check.cost_usdc || 0);

       if (check.response_data && !check.response_data.error) {
           target.latest_data_summary = this.buildLatestDataSummary(target.type, check.response_data);
       } else if (check.response_data && check.response_data.error) {
           target.latest_data_summary = "Service error occurred.";
       }
    }

    const watcherSummaries = Array.from(summaryMap.values()).map(summary => {

       return summary;
    });

    const totalChecks = checks.length;
    const totalFindings = findingsIds.length;
    let totalCost = 0;
    for (const summary of watcherSummaries) {
       totalCost += summary.spent;
    }

    let findingsSection = "FINDINGS\n";
    if (totalFindings === 0) {
      findingsSection += "No new findings overnight.\n";
    } else {
      for (const fId of findingsIds) {
        const f = await getFindingById(fId);
        if (!f) continue;
        const vStatus = f.verified ? "Verified" : "Single Check";
        const cStatus = f.collaboration_result ? " | Cross-checked" : "";

        let cost = f.cost_usdc || 0.008;
        let checkCount = 1;
        if (f.verified) { cost += 0.008; checkCount++; }
        if (f.collaboration_result) { cost += 0.008; checkCount++; }

        findingsSection += `• ${f.watcher_name || 'Watcher'}: ${f.headline} (Confidence: ${f.confidence_score}%)\n`;
        findingsSection += `  ${vStatus}${cStatus} | Cost: $${cost.toFixed(3)} (${checkCount} checks)\n`;
      }
    }

    let noChangeSection = "\nNO CHANGE\n";
    const noChangeWatchers = watcherSummaries.filter(s => s.findings_count === 0 && s.checks_run > 0);
    for (const s of noChangeWatchers) {
      noChangeSection += `• ${s.type.toUpperCase()}: ${s.watcher_name} - ${s.latest_data_summary}\n`;
    }

    const totalSpent = totalCost;
    const estSavings = totalFindings * 45.0;
    const flareScore = Math.min(100, Math.round((totalFindings * 15) + (totalChecks * 0.5) + 50));

    const walletRes = await getSpendingStats(userId);
    const balance = (user as any).balance_usdc || 5.0;
    const dailyRate = Math.max(0.01, walletRes.spent_today || (totalSpent / 1));
    const daysLeft = Math.round(balance / dailyRate);

    const generatedSummary = `${findingsSection}${noChangeSection}\nOVERNIGHT SUMMARY\nCost: $${totalSpent.toFixed(3)} across ${totalChecks} checks\nEstimated savings: $${estSavings}\nFlare Score: ${flareScore}/100\n\nWallet lasts ~${daysLeft} more days at current rate.`;

    const today = now.toISOString().split('T')[0];
    const briefingId = uuidv4();

    const briefingData = {
        briefingId: briefingId,
        userId: userId,
        date: today,
        periodStart: periodStart,
        periodEnd: periodEnd,
        totalChecks: totalChecks,
        totalFindings: totalFindings,
        totalCostUsdc: totalCost,
        findingsJson: findingsIds,
        watcherSummariesJson: watcherSummaries,
        generatedSummary: generatedSummary
    };

    await createBriefing(briefingData);

    const notifyPayload = {
       briefing_id: briefingData.briefingId,
       total_findings: briefingData.totalFindings,
       total_cost_usdc: briefingData.totalCostUsdc
    };

    try {
        await this.notificationSvc.sendBriefingNotification(userId, notifyPayload);
    } catch (e) {
        console.warn(`Failed to send briefing push notification to user ${userId}`, e);
    }

    return briefingData;
  }

  private buildLatestDataSummary(type: string, data: any): string {
     try {
         switch (type.toLowerCase()) {
            case 'flight':
               if (data && data.price) {
                  return `${data.origin || 'Unknown'}->${data.destination || 'Unknown'}: $${data.price}`;
               }
               return "No flight data returned.";

            case 'crypto':
               if (data && data.priceUsd) {
                   const change = data.changePercent24Hr ? ` (${Number(data.changePercent24Hr) > 0 ? '+' : ''}${Number(data.changePercent24Hr).toFixed(2)}%)` : '';
                   return `${data.id || 'Crypto'}: $${Number(data.priceUsd).toFixed(2)}${change}`;
               }
               return "No valid crypto pricing.";

            case 'news':
               const newsCount = Array.isArray(data.articles) ? data.articles.length : 0;
               return newsCount === 0 ? "No new matches" : `${newsCount} articles found`;

            case 'product':
               if (data && data.price) {
                   return `${data.title ? data.title.substring(0, 20) : 'Product'}: $${data.price}`;
               }
               return "No pricing returned.";

            case 'job':
               const jobCount = Array.isArray(data.jobs) ? data.jobs.length : 0;
               return jobCount === 0 ? "0 new listings" : `${jobCount} new matches`;

            case 'stock':
                if (data && data.price) {
                   return `${data.symbol || 'Stock'}: $${data.price} (${data.change > 0 ? '+' : ''}${data.change}%)`;
                }
                return "Latest price stable.";

            case 'realestate':
                return data.address ? `Active listing: ${data.address.substring(0, 15)}...` : "Market monitored.";

            case 'sports':
                return data.event ? `${data.event}: $${data.price}` : "Event seats monitored.";

            default:
               return "Data collected successfully.";
         }
     } catch (e) {
         return "Summary parsing failed.";
     }
  }

  private async triggerInitialChecks(userId: string): Promise<void> {
    if (!this.checkExecutor) return;

    try {
      const watchers = await getWatchersByUserId(userId) as any[];

      const newWatchers = watchers.filter(w => w.status === 'active' && (w.total_checks || 0) === 0);

      if (newWatchers.length === 0) return;

      console.log(`[BRIEFING] Triggering initial checks for ${newWatchers.length} new watchers in parallel...`);

      const checksToRun = newWatchers.slice(0, 5);
      await Promise.all(checksToRun.map(async (watcher) => {
        try {
          await this.checkExecutor!.runCheck(watcher.watcher_id);
        } catch (err) {
          console.error(`[BRIEFING] Initial check failed for watcher ${watcher.watcher_id}`, err);
        }
      }));
    } catch (e) {
      console.error(`[BRIEFING] Failed to trigger initial checks for user ${userId}`, e);
    }
  }
}

export const briefingGenerator = new BriefingGenerator();
