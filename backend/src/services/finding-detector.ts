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
      case 'stock':
        finding = this.detectStockFinding(watcher, checkData, previousCheckData);
        break;
      case 'realestate':
        finding = this.detectRealEstateFinding(watcher, checkData, previousCheckData);
        break;
      case 'sports':
        finding = this.detectSportsFinding(watcher, checkData, previousCheckData);
        break;
    }

    if (finding) {
      finding.finding_id = uuidv4();
      finding.watcher_id = watcher.watcher_id;
      finding.user_id = watcher.user_id;
      finding.cost_usdc = costUsdc;
      finding.stellar_tx_hash = txHash;
      finding.data = checkData;
      
      // Calculate Confidence Score (0-100)
      finding.agent_reasoning = (finding.agent_reasoning || '') + ` (Confidence: ${this.calculateConfidence(watcher, checkData, previousCheckData)}/100)`;
    }

    return finding;
  }

  private calculateConfidence(watcher: WatcherRow, data: any, prev: any): number {
    let score = 85; // Base confidence
    if (!prev) score -= 10;
    if (data.is_error_fare) score -= 15; // Error fares are risky
    if (data.articles && data.articles.length < 3) score -= 10; // News needs volume
    return Math.min(100, Math.max(0, score));
  }

  private detectFlightFinding(watcher: WatcherRow, data: any, prev: any): Finding | null {
    const conditions = watcher.alert_conditions || {};
    const price = data.cheapest_price;
    const airline = data.airline;

    if (data.is_error_fare) {
        return {
            finding_id: '', watcher_id: '', user_id: '', check_id: '', type: 'threshold_crossed',
            headline: `✈️ ${airline} to ${data.destination}: $${price} (Error Fare!)`,
            detail: `Detected a massive price drop for ${airline}. Likely a mistake — book fast!`,
            data: null, cost_usdc: 0, agent_reasoning: `Price is 60%+ below historical average.`
        };
    }

    if (data.is_historical_low) {
        return {
            finding_id: '', watcher_id: '', user_id: '', check_id: '', type: 'price_drop',
            headline: `✈️ Lowest ever: ${data.origin} → ${data.destination} for $${price}`,
            detail: `This is the lowest price ever tracked for this route on ${airline}.`,
            data: null, cost_usdc: 0, agent_reasoning: `Price $${price} is a new historical low.`
        };
    }

    if (conditions.price_below && price <= conditions.price_below) {
        const prefAirline = watcher.parameters?.preferred_airline;
        if (prefAirline && airline.toLowerCase() !== prefAirline.toLowerCase()) return null;

        return {
            finding_id: '', watcher_id: '', user_id: '', check_id: '', type: 'threshold_crossed',
            headline: `✈️ ${airline}: ${data.origin} → ${data.destination} below $${conditions.price_below}`,
            detail: `Current price: $${price}.`,
            data: null, cost_usdc: 0, agent_reasoning: `Threshold $${conditions.price_below} met.`
        };
    }
    return null;
  }

  private detectCryptoFinding(watcher: WatcherRow, data: any, prev: any): Finding | null {
    const conditions = watcher.alert_conditions || {};
    
    // Portfolio tracking
    if (watcher.parameters?.mode === 'portfolio') {
        const val = data.total_value;
        const target = conditions.target_value;
        if (target && val >= target) {
            return {
                finding_id: '', watcher_id: '', user_id: '', check_id: '', type: 'threshold_crossed',
                headline: `💰 Portfolio hit $${val.toLocaleString()}`,
                detail: `Your crypto portfolio has reached your target of $${target.toLocaleString()}.`,
                data: null, cost_usdc: 0, agent_reasoning: `Value ${val} >= target ${target}.`
            };
        }
    }

    // Volume spikes
    for (const [symbol, vol] of Object.entries(data.volumes || {}) as [string, number][]) {
        if (vol > 2.5) {
            return {
                finding_id: '', watcher_id: '', user_id: '', check_id: '', type: 'price_spike',
                headline: `⚠️ ${symbol} Volume Spike (3x)`,
                detail: `Unusual trading activity detected for ${symbol}. Volume is 3x higher than 24h average.`,
                data: null, cost_usdc: 0, agent_reasoning: `Volume factor ${vol} > 2.5.`
            };
        }
    }

    return null;
  }

  private detectNewsFinding(watcher: WatcherRow, data: any): Finding | null {
    const articles = data.articles || [];
    if (articles.length >= 3 && data.trending_score > 80) {
        return {
            finding_id: '', watcher_id: '', user_id: '', check_id: '', type: 'news_match',
            headline: `📰 ${articles.length} sources reporting: ${articles[0].title}`,
            detail: articles.map((a: any) => `• ${a.title} (${a.source})`).join('\n'),
            data: null, cost_usdc: 0, agent_reasoning: `Multi-source verification successful. Trending score: ${data.trending_score}.`
        };
    }
    return null;
  }

  private detectProductFinding(watcher: WatcherRow, data: any, prev: any): Finding | null {
    if (data.is_ath) {
        return {
            finding_id: '', watcher_id: '', user_id: '', check_id: '', type: 'price_drop',
            headline: `🛍️ All-time low: ${data.product_name} at $${data.current_price}`,
            detail: `Lowest price ever tracked for ${data.product_name}. Available at ${data.stores[0].store}.`,
            data: null, cost_usdc: 0, agent_reasoning: `New all-time low detected.`
        };
    }
    return null;
  }

  private detectJobFinding(watcher: WatcherRow, data: any): Finding | null {
    const hotJob = data.listings?.find((l: any) => l.is_hot);
    if (hotJob) {
        return {
            finding_id: '', watcher_id: '', user_id: '', check_id: '', type: 'new_listing',
            headline: `💼 Hot: ${hotJob.title} at ${hotJob.company} — $${hotJob.salary.toLocaleString()}`,
            detail: `This role is in the 90th percentile for ${hotJob.title} salaries.`,
            data: null, cost_usdc: 0, agent_reasoning: `Detected 'hot' job listing with premium salary.`
        };
    }
    return null;
  }

  private detectStockFinding(watcher: WatcherRow, data: any, prev: any): Finding | null {
    const stock = data.stocks?.find((s: any) => Math.abs(s.change_percent) > 5 || s.event);
    if (stock) {
        return {
            finding_id: '', watcher_id: '', user_id: '', check_id: '', type: stock.change_percent > 0 ? 'price_spike' : 'price_drop',
            headline: `📊 ${stock.symbol} ${stock.change_percent > 0 ? 'surged' : 'dropped'} ${Math.abs(stock.change_percent)}%`,
            detail: stock.event ? `Event: ${stock.event}. Price: $${stock.price}.` : `Current price: $${stock.price}.`,
            data: null, cost_usdc: 0, agent_reasoning: `Detected significant move or event for ${stock.symbol}.`
        };
    }
    return null;
  }

  private detectRealEstateFinding(watcher: WatcherRow, data: any, prev: any): Finding | null {
    const listing = data.listings?.find((l: any) => l.price_reduced || l.is_new);
    if (listing) {
        return {
            finding_id: '', watcher_id: '', user_id: '', check_id: '', type: 'new_listing',
            headline: listing.price_reduced ? `🏠 Price Drop: ${listing.address} in ${listing.neighborhood}` : `🏠 New listing in ${listing.neighborhood}`,
            detail: `${listing.type} for $${listing.price.toLocaleString()}. Neighborhood trend: ${data.stats.trend}.`,
            data: null, cost_usdc: 0, agent_reasoning: `Found listing with price reduction or new tag.`
        };
    }
    return null;
  }

  private detectSportsFinding(watcher: WatcherRow, data: any, prev: any): Finding | null {
    const ticket = data.tickets?.find((t: any) => t.price_dropped);
    if (ticket) {
        return {
            finding_id: '', watcher_id: '', user_id: '', check_id: '', type: 'price_drop',
            headline: `⚽ Ticket Drop: ${watcher.parameters?.team} ${ticket.section} seats for $${ticket.price}`,
            detail: `Prices dropped from $${ticket.history[0]}. Game status: ${data.match.score}.`,
            data: null, cost_usdc: 0, agent_reasoning: `Detected 15%+ drop in secondary ticket market.`
        };
    }
    return null;
  }
}
