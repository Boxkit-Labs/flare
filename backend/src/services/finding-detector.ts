import { v4 as uuidv4 } from 'uuid';
import { WatcherRow, Finding } from '../types.js';

export class FindingDetector {
  /**
   * Analyzes the response data from a check and determines if it should trigger an alert.
   * @param watcher The watcher configuration from the database.
   * @param checkData The raw JSON response from the data service.
   * @param previousCheckData The previous raw JSON response (optional).
   * @returns A Finding object if a trigger condition is met, otherwise null.
   */
  async detectFinding(
    watcher: WatcherRow,
    checkData: any,
    previousCheckData: any | null = null,
    costUsdc: number = 0,
    txHash: string = ''
  ): Promise<Finding | null> {
    let finding: Finding | null = null;
    let agentReasoning = '';

    switch (watcher.type.toLowerCase()) {
      case 'flight':
        finding = this.detectFlightFinding(watcher, checkData, previousCheckData);
        break;
      case 'crypto':
        finding = this.detectCryptoFinding(watcher, checkData, previousCheckData);
        break;
      case 'news':
        finding = this.detectNewsFinding(watcher, checkData);
        break;
      case 'product':
        finding = this.detectProductFinding(watcher, checkData, previousCheckData);
        break;
      case 'job':
        finding = this.detectJobFinding(watcher, checkData);
        break;
      default:
        agentReasoning = `Unknown watcher type: ${watcher.type}`;
    }

    if (finding) {
      // Attach common metadata
      finding.finding_id = uuidv4();
      finding.watcher_id = watcher.watcher_id;
      finding.user_id = watcher.user_id;
      finding.cost_usdc = costUsdc;
      finding.stellar_tx_hash = txHash;
      finding.data = checkData;
    }

    return finding;
  }

  private detectFlightFinding(watcher: WatcherRow, data: any, prev: any): Finding | null {
    const conditions = watcher.alert_conditions || {};
    const currentPrice = data.cheapest_price;
    const origin = data.origin || watcher.parameters?.origin;
    const dest = data.destination || watcher.parameters?.destination;

    // 1. Price Below Threshold
    if (conditions.price_below && currentPrice <= conditions.price_below) {
      return {
        finding_id: '',
        watcher_id: '',
        user_id: '',
        check_id: '', // Will be set by the caller
        type: 'threshold_crossed',
        headline: `✈️ ${origin} → ${dest} dropped to $${currentPrice}`,
        detail: `Flight price is now $${currentPrice}, which is below your threshold of $${conditions.price_below}. Airline: ${data.airline}.`,
        data: null,
        cost_usdc: 0,
        agent_reasoning: `Current price $${currentPrice} is less than or equal to threshold $${conditions.price_below}.`
      };
    }

    // 2. Price Drop %
    if (conditions.price_drop_percent && prev && prev.cheapest_price) {
      const prevPrice = prev.cheapest_price;
      const dropAmount = prevPrice - currentPrice;
      const dropPercent = (dropAmount / prevPrice) * 100;

      if (dropPercent >= conditions.price_drop_percent) {
        return {
          finding_id: '',
          watcher_id: '',
          user_id: '',
          check_id: '',
          type: 'price_drop',
          headline: `✈️ ${origin} → ${dest} dropped to $${currentPrice}`,
          detail: `Price dropped $${dropAmount.toFixed(2)} (${dropPercent.toFixed(1)}%) from $${prevPrice}. ${data.airline} on ${data.departure_date}.`,
          data: null,
          cost_usdc: 0,
          agent_reasoning: `Price drop of ${dropPercent.toFixed(1)}% exceeds your ${conditions.price_drop_percent}% alert condition.`
        };
      }
    }

    return null;
  }

  private detectCryptoFinding(watcher: WatcherRow, data: any, prev: any): Finding | null {
    const conditions = watcher.alert_conditions || {};
    const prices = data.prices || {};
    const changes24h = data.changes_24h || {};

    for (const [symbol, currentPrice] of Object.entries(prices) as [string, number][]) {
      // 1. Price Above
      if (conditions.price_above?.[symbol] && currentPrice > conditions.price_above[symbol]) {
        return {
          finding_id: '',
          watcher_id: '',
          user_id: '',
          check_id: '',
          type: 'price_spike',
          headline: `💰 ${symbol} surged to $${currentPrice}`,
          detail: `${symbol} has crossed your upper threshold of $${conditions.price_above[symbol]}. Current price: $${currentPrice}.`,
          data: null,
          cost_usdc: 0,
          agent_reasoning: `Price ${currentPrice} is above threshold ${conditions.price_above[symbol]} for ${symbol}.`
        };
      }

      // 2. Price Below
      if (conditions.price_below?.[symbol] && currentPrice < conditions.price_below[symbol]) {
        return {
          finding_id: '',
          watcher_id: '',
          user_id: '',
          check_id: '',
          type: 'threshold_crossed',
          headline: `💰 ${symbol} dropped to $${currentPrice}`,
          detail: `${symbol} has fell below your threshold of $${conditions.price_below[symbol]}. Current price: $${currentPrice}.`,
          data: null,
          cost_usdc: 0,
          agent_reasoning: `Price ${currentPrice} is below threshold ${conditions.price_below[symbol]} for ${symbol}.`
        };
      }
    }

    // 3. 24h Change %
    if (conditions.change_24h_percent) {
      for (const [symbol, change] of Object.entries(changes24h) as [string, number][]) {
        if (Math.abs(change) >= conditions.change_24h_percent) {
          const direction = change > 0 ? 'surged' : 'dropped';
          return {
            finding_id: '',
            watcher_id: '',
            user_id: '',
            check_id: '',
            type: change > 0 ? 'price_spike' : 'price_drop',
            headline: `💰 ${symbol} ${direction} ${Math.abs(change).toFixed(1)}%`,
            detail: `${symbol} recorded a 24h change of ${change.toFixed(2)}%, exceeding your alert threshold of ${conditions.change_24h_percent}%.`,
            data: null,
            cost_usdc: 0,
            agent_reasoning: `24h change for ${symbol} (${change.toFixed(2)}%) met alert condition (${conditions.change_24h_percent}%).`
          };
        }
      }
    }

    return null;
  }

  private detectNewsFinding(watcher: WatcherRow, data: any): Finding | null {
    const conditions = watcher.alert_conditions || {};
    const articles = data.articles || [];
    const minRelevance = conditions.min_relevance || 0.7;
    const minArticles = conditions.min_articles || 1;

    const matchingArticles = articles.filter((a: any) => a.relevance_score >= minRelevance);

    if (matchingArticles.length >= minArticles) {
      const keywords = watcher.parameters?.keywords || 'your topics';
      return {
        finding_id: '',
        watcher_id: '',
        user_id: '',
        check_id: '',
        type: 'news_match',
        headline: `📰 ${matchingArticles.length} articles about ${keywords}`,
        detail: matchingArticles.map((a: any) => `• ${a.title} (${a.source})`).join('\n'),
        data: null,
        cost_usdc: 0,
        agent_reasoning: `Found ${matchingArticles.length} articles with relevance >= ${minRelevance}, meeting your minimum of ${minArticles}.`
      };
    }

    return null;
  }

  private detectProductFinding(watcher: WatcherRow, data: any, prev: any): Finding | null {
    const conditions = watcher.alert_conditions || {};
    const currentPrice = data.current_price;
    const productName = data.product_name || watcher.parameters?.product_name;

    // 1. Price Below
    if (conditions.price_below && currentPrice <= conditions.price_below) {
      return {
        finding_id: '',
        watcher_id: '',
        user_id: '',
        check_id: '',
        type: 'threshold_crossed',
        headline: `🛍️ ${productName} dropped to $${currentPrice}`,
        detail: `${productName} is now $${currentPrice} at ${data.store}. This is below your $${conditions.price_below} threshold.${data.on_sale ? ' Marked as ON SALE.' : ''}`,
        data: null,
        cost_usdc: 0,
        agent_reasoning: `Current price $${currentPrice} met threshold of $${conditions.price_below}.`
      };
    }

    // 2. Price Drop %
    if (conditions.price_drop_percent && prev && prev.current_price) {
      const prevPrice = prev.current_price;
      const dropPercent = ((prevPrice - currentPrice) / prevPrice) * 100;

      if (dropPercent >= conditions.price_drop_percent) {
        return {
          finding_id: '',
          watcher_id: '',
          user_id: '',
          check_id: '',
          type: 'price_drop',
          headline: `🛍️ ${productName} dropped to $${currentPrice}`,
          detail: `Price dropped ${dropPercent.toFixed(1)}% from $${prevPrice}. Currently $${currentPrice} at ${data.store}.`,
          data: null,
          cost_usdc: 0,
          agent_reasoning: `Detected price drop of ${dropPercent.toFixed(1)}%, meeting your ${conditions.price_drop_percent}% threshold.`
        };
      }
    }

    return null;
  }

  private detectJobFinding(watcher: WatcherRow, data: any): Finding | null {
    const conditions = watcher.alert_conditions || {};
    const listings = data.listings || [];
    const minSalary = conditions.min_salary || 0;

    const filtered = listings.filter((l: any) => {
      const salaryVal = typeof l.salary === 'number' ? l.salary : parseInt(l.salary?.toString().replace(/[^0-9]/g, '') || '0');
      return salaryVal >= minSalary;
    });

    if (filtered.length > 0 && conditions.alert_on_new !== false) {
      return {
        finding_id: '',
        watcher_id: '',
        user_id: '',
        check_id: '',
        type: 'new_listing',
        headline: `💼 ${filtered.length} new job matches`,
        detail: filtered.map((l: any) => `• ${l.title} at ${l.company} (${l.location})`).join('\n'),
        data: null,
        cost_usdc: 0,
        agent_reasoning: `Found ${filtered.length} listings meeting your criteria.`
      };
    }

    return null;
  }
}
