import { v4 as uuidv4 } from 'uuid';
import { getUserById, getChecksSince, getWatchersByUserId, createBriefing, getFindingById, getSpendingStats } from '../db/queries.js';
import { notificationService, NotificationService } from './notification.js';
import { CheckExecutor } from './check-executor.js';
import { getPriceTrend, getEventFromCache } from './events/price-tracker.js';

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
      const base: any = {
        watcher_id: w.watcher_id,
        watcher_name: w.name,
        type: w.type,
        checks_run: 0,
        findings_count: 0,
        spent: 0,
        latest_data_summary: "No checks run overnight."
      };

      // Enrich event watchers with extra context
      if (w.type === 'event') {
        const params = typeof w.parameters === 'string' ? JSON.parse(w.parameters) : (w.parameters || {});
        base.event_mode = params.mode || 'specific_event';
        base.event_name = params.eventName || w.name;
        base.event_date = params.eventDate || null;
        base.is_free = params.isFree || false;
        base.platform = params.platform || '';
        base.external_id = params.externalId || '';

        if (params.eventDate) {
          const eventDt = new Date(params.eventDate);
          const daysAway = Math.ceil((eventDt.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
          base.days_until_event = daysAway;
          base.event_passed = daysAway < 0;
        }
      }

      summaryMap.set(w.watcher_id, base);
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

    // Enrich event watcher summaries with price trend data
    for (const summary of summaryMap.values()) {
      if (summary.type === 'event' && summary.event_mode === 'specific_event' && summary.external_id) {
        try {
          const cached = await getEventFromCache(summary.external_id, summary.platform);
          if (cached) {
            summary.event_name = cached.name;
            summary.venue = cached.venue;
            summary.city = cached.city;
          }

          // Build tier trend summaries
          if (!summary.is_free) {
            const trendSummaries: string[] = [];
            const tierNames = summary.watched_tiers || ['GA', 'VIP', 'VVIP', 'Regular', 'Standard'];
            for (const tierName of tierNames) {
              const trend = await getPriceTrend(summary.watcher_id, tierName);
              if (trend) {
                const arrow = trend.trend === 'rising' ? '↑' : trend.trend === 'falling' ? '↓' : '→';
                trendSummaries.push(`${tierName}: ${trend.currency} ${trend.currentMin} ${arrow}`);
              }
            }
            if (trendSummaries.length > 0) {
              summary.tier_trends = trendSummaries;
            }
          }
        } catch (e) {
          // Non-fatal: trend data may not be available
        }
      }
    }

    // Sort: findings first, then soonest events, then alphabetically
    const watcherSummaries = Array.from(summaryMap.values()).sort((a, b) => {
      // Findings first
      if (a.findings_count > 0 && b.findings_count === 0) return -1;
      if (a.findings_count === 0 && b.findings_count > 0) return 1;

      // Soonest events next (only for event type)
      const aDays = a.days_until_event ?? Infinity;
      const bDays = b.days_until_event ?? Infinity;
      if (aDays !== bDays) return aDays - bDays;

      // Alphabetical
      return (a.watcher_name || '').localeCompare(b.watcher_name || '');
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
      if (s.type === 'event') {
        noChangeSection += this.buildEventBriefingLine(s);
      } else {
        noChangeSection += `• ${s.type.toUpperCase()}: ${s.watcher_name} - ${s.latest_data_summary}\n`;
      }
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

            case 'event':
                return this.buildEventDataSummary(data);

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

  private buildEventDataSummary(data: any): string {
    try {
      if (!data) return "No event data.";

      // Search mode
      if (data.newCount !== undefined) {
        return data.newCount > 0
          ? `${data.newCount} new event(s) found. ${data.totalCount || '?'} total.`
          : `${data.totalCount || 0} events tracked. No new listings.`;
      }

      // Specific event
      const name = data.name || 'Event';
      const status = data.status || 'active';

      if (status === 'cancelled') return `${name}: CANCELLED`;
      if (status === 'postponed') return `${name}: POSTPONED`;

      if (data.isFree) {
        const tiers = data.ticketTiers || [];
        const availableTiers = tiers.filter((t: any) => t.available);
        const spotsInfo = tiers
          .filter((t: any) => t.quantityRemaining != null)
          .map((t: any) => `${t.name}: ${t.quantityRemaining} spots`)
          .join(', ');
        return spotsInfo
          ? `${name}: FREE — ${spotsInfo}`
          : `${name}: FREE — ${availableTiers.length}/${tiers.length} tiers available`;
      }

      const tiers = data.ticketTiers || [];
      if (tiers.length > 0) {
        const currency = data.currency || '';
        const tierInfo = tiers.slice(0, 3).map((t: any) =>
          `${t.name}: ${currency} ${t.minPrice}${t.available ? '' : ' (sold out)'}`
        ).join(' | ');
        return `${name}: ${tierInfo}`;
      }

      return `${name}: prices stable`;
    } catch {
      return "Event data parsing failed.";
    }
  }

  private buildEventBriefingLine(summary: any): string {
    const name = summary.event_name || summary.watcher_name;
    const daysAway = summary.days_until_event;

    // Past event
    if (summary.event_passed) {
      return `• EVENT: ${name} — Event has passed. Watcher auto-paused.\n`;
    }

    // Search mode
    if (summary.event_mode === 'search') {
      const newCount = summary.latest_new_count || 0;
      return newCount > 0
        ? `• EVENT SEARCH: ${name} — ${newCount} new event(s) found\n`
        : `• EVENT SEARCH: ${name} — No new listings\n`;
    }

    // Free event
    if (summary.is_free) {
      const daysText = daysAway != null ? ` (${daysAway}d away)` : '';
      return `• EVENT: ${name}${daysText} — FREE, availability tracked\n`;
    }

    // Paid event with tier trends
    const daysText = daysAway != null ? ` (${daysAway}d away)` : '';
    if (summary.tier_trends && summary.tier_trends.length > 0) {
      return `• EVENT: ${name}${daysText} — ${summary.tier_trends.join(' | ')}\n`;
    }

    return `• EVENT: ${name}${daysText} — prices stable\n`;
  }
}

export const briefingGenerator = new BriefingGenerator();
