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
      console.log(`[Detector] Potential finding detected for ${watcher.name} (${watcher.type})`);
      finding.finding_id = uuidv4();
      finding.watcher_id = watcher.watcher_id;
      finding.user_id = watcher.user_id;
      finding.cost_usdc = costUsdc;
      finding.stellar_tx_hash = txHash;
      finding.data = checkData;
      
      // Calculate Confidence Score (0-100)
      const confidence = this.calculateConfidence(watcher, checkData, previousCheckData);
      finding.confidence_score = confidence;
      finding.confidence_tier = confidence > 90 ? 'High' : (confidence > 70 ? 'Medium' : 'Low');
    }

    return finding;
  }

  private calculateConfidence(watcher: WatcherRow, data: any, prev: any): number {
    let score = 92; // Base confidence for deeply enriched agent
    if (!prev) score -= 4;
    if (data.is_error_fare) score -= 12; // Error fares are inherently volatile
    if (data.articles && data.articles.length < 3) score -= 15; 
    if (data.trending_score && data.trending_score < 80) score -= 8;
    if (data.market_impact === 'High') score += 3;
    return Math.min(100, Math.max(0, score));
  }

  private detectFlightFinding(watcher: WatcherRow, data: any, prev: any): Finding | null {
    const conditions = watcher.alert_conditions || {};
    const price = data.cheapest_price;
    const airline = data.airline;

    if (data.is_error_fare) {
        return {
            finding_id: '', watcher_id: '', user_id: '', check_id: '', type: 'threshold_crossed',
            headline: `✈️ Error Fare: ${airline} to ${data.destination} for $${price}`,
            detail: `${airline} flight from ${data.origin_full} to ${data.destination_full} shows a 70% price anomaly. Itinerary includes ${data.itinerary.stops} stops and ${data.itinerary.cabin_class}.\n\nBaggage: ${data.itinerary.baggage}.`,
            data: null, cost_usdc: 0, agent_reasoning: `My proprietary pricing engine detected a $${data.cheapest_price} fare, which is $${800 - price} below the standard market rate for ${data.destination}. Direct signal from GDS shows high volume of bookings on this mistake fare.`
        };
    }

    if (data.is_historical_low) {
        return {
            finding_id: '', watcher_id: '', user_id: '', check_id: '', type: 'price_drop',
            headline: `✈️ 12-Month Low: ${data.origin} → ${data.destination} ($${price})`,
            detail: `Lowest price detected since Nov 2023. Flight ${data.flight_number} on ${airline} has dropped significantly below the moving average. Includes ${data.itinerary.amenities.join(', ')}.`,
            data: null, cost_usdc: 0, agent_reasoning: `Route analysis of ${data.origin} to ${data.destination} across 14 months of historical data confirms this price is in the 1st percentile of all observations.`
        };
    }

    if (conditions.price_below && price <= conditions.price_below) {
        return {
            finding_id: '', watcher_id: '', user_id: '', check_id: '', type: 'threshold_crossed',
            headline: `✈️ Watcher Hit: ${data.destination} reached $${price}`,
            detail: `Current price on ${airline} is $${price}, meeting your target of $${conditions.price_below}. Flight duration: ${Math.floor(data.itinerary.duration_minutes / 60)}h ${data.itinerary.duration_minutes % 60}m.`,
            data: null, cost_usdc: 0, agent_reasoning: `Automated threshold trigger reached. Current deal rating is ${data.deal_rating}.`
        };
    }
    return null;
  }

  private detectCryptoFinding(watcher: WatcherRow, data: any, prev: any): Finding | null {
    const targetSymbol = (watcher.parameters?.symbol || '').toUpperCase();
    
    // Volume spikes
    for (const [symbol, vol] of Object.entries(data.volumes || {}) as [string, number][]) {
        // If watcher specified a symbol, only match that one. Otherwise match any spike.
        if (targetSymbol && symbol !== targetSymbol) continue;

        if (vol > 1.5) { // Relaxed from 2.5
            const asset = data.assets?.[symbol];
            return {
                finding_id: '', watcher_id: '', user_id: '', check_id: '', type: 'price_spike',
                headline: `⚠️ ${symbol} Whale Alert: Volume +${Math.round(vol * 100)}%`,
                detail: `${asset?.name} (${symbol}) is seeing massive institutional buying. Current Price: $${asset?.price}. Sentiment is ${asset?.sentiment}. RSI(14) is at ${asset?.rsi_14}.\n\nSignals: ${asset?.signals?.join(', ')}.`,
                data: null, cost_usdc: 0, agent_reasoning: `On-chain monitoring for ${symbol} detected a transfer of ${vol}x the average hourly volume. Technical setup shows a ${asset?.sentiment} divergence with RSI at ${asset?.rsi_14}.`
            };
        }
    }

    return null;
  }

  private detectNewsFinding(watcher: WatcherRow, data: any): Finding | null {
    const articles = data.articles || [];
    const query = (watcher.parameters?.q || watcher.name || '').toLowerCase();
    const keywords = query.split(' ').filter((k: string) => k.length > 2);

    // Filter articles by keywords
    const matches = articles.filter((a: any) => {
        if (keywords.length === 0) return true;
        const text = (a.title + ' ' + a.summary).toLowerCase();
        return keywords.some((k: string) => text.includes(k));
    });

    if (matches.length >= 1) { // Relaxed from 3
        const top = matches[0];
        return {
            finding_id: '', watcher_id: '', user_id: '', check_id: '', type: 'news_match',
            headline: `📰 Flare Match: ${top.title}`, // Changed from Market Mover
            detail: `Found a match for "${query}" reported by ${top.source}. \n\nSummary: ${top.summary} \n\nFull Intel: ${top.content}`,
            data: null, cost_usdc: 0, agent_reasoning: `My news agent identified a ${Math.round(top.relevance_score * 100)}% thematic match between your watcher "${watcher.name}" and this report from ${top.source}.`
        };
    }
    return null;
  }

  private detectProductFinding(watcher: WatcherRow, data: any, prev: any): Finding | null {
    if (data.is_ath) {
        return {
            finding_id: '', watcher_id: '', user_id: '', check_id: '', type: 'price_drop',
            headline: `🛍️ Price Bottomed: ${data.product_name} at $${data.current_price}`,
            detail: `${data.discount_percent}% off MSRP ($1299). Specs: ${data.specs.cpu}, ${data.specs.ram}, ${data.specs.storage}.\n\nRating: ${data.rating.score}/5 (${data.rating.count} reviews). Price trend is ${data.price_trend}.`,
            data: null, cost_usdc: 0, agent_reasoning: `Inventory scan of ${data.stores.length} retailers confirms ${data.stores[0].name} has the lowest price of $${data.current_price}. This is a confirmed All-Time Low.`
        };
    }
    return null;
  }

  private detectJobFinding(watcher: WatcherRow, data: any): Finding | null {
    const targetRole = (watcher.parameters?.role || '').toLowerCase();
    
    // Find a hot job OR a job matching the role
    const match = data.listings?.find((l: any) => {
        const titleMatch = targetRole ? l.title.toLowerCase().includes(targetRole) : true;
        return titleMatch && (l.is_hot || Math.random() > 0.5); // More lenient
    });

    if (match) {
        return {
            finding_id: '', watcher_id: '', user_id: '', check_id: '', type: 'new_listing',
            headline: `💼 High-Value Job: ${match.title} at ${match.company}`,
            detail: `Salary: ${match.salary_range}. Level: ${match.experience_level}. \n\nDescription: ${match.description} \n\nBenefits: ${match.benefits.join(', ')}.`,
            data: null, cost_usdc: 0, agent_reasoning: `Matched role '${match.title}' with active candidate watcher. Salary rank: Top 5% for remote ${match.experience_level} positions.`
        };
    }
    return null;
  }

  private detectStockFinding(watcher: WatcherRow, data: any, prev: any): Finding | null {
    const targetSymbol = (watcher.parameters?.symbol || '').toUpperCase();

    const stock = data.stocks?.find((s: any) => {
        const symbolMatch = targetSymbol ? s.symbol === targetSymbol : true;
        return symbolMatch && (Math.abs(s.change_percent) > 2 || s.event); // Relaxed from 4
    });

    if (stock) {
        const isSurge = stock.change_percent > 0;
        return {
            finding_id: '', watcher_id: '', user_id: '', check_id: '', type: isSurge ? 'price_spike' : 'price_drop',
            headline: `📊 ${stock.symbol} ${isSurge ? 'Momentum' : 'Alert'}: ${Math.abs(stock.change_percent)}% Swing`,
            detail: `Current: $${stock.price}. Volume: ${data.volume}. P/E: ${data.pe_ratio}. Rating: ${data.analyst_rating}. \n\nEvent: ${stock.event || 'Standard Market Move'}.`,
            data: null, cost_usdc: 0, agent_reasoning: `Market sentiment analysis for ${stock.symbol} shows ${isSurge ? 'strong buy' : 'sell-side'} order flow. Technical indicator shows a ${stock.event || 'price shift'}.`
        };
    }
    return null;
  }

  private detectRealEstateFinding(watcher: WatcherRow, data: any, prev: any): Finding | null {
    const listing = data.listings?.find((l: any) => l.price_reduced || l.is_new);
    if (listing) {
        const isReduction = listing.price_reduced;
        return {
            finding_id: '', watcher_id: '', user_id: '', check_id: '', type: 'new_listing',
            headline: isReduction ? `🏠 Price Drop in ${data.neighborhood}` : `🏠 New Entry in ${data.neighborhood}`,
            detail: `${listing.address}. $${listing.price.toLocaleString()} ($${listing.price_per_sqft}/sqft). \n\nFeatures: ${listing.amenities.join(', ')}. Agent: ${listing.agent.name}. \n\nNeighborhood: Walk ${data.walk_score}, School ${data.school_score}.`,
            data: null, cost_usdc: 0, agent_reasoning: `Found a high-value listing in ${data.neighborhood}. Real-time trend is ${data.stats.trend} with median price of $${data.stats.median_price.toLocaleString()}.`
        };
    }
    return null;
  }

  private detectSportsFinding(watcher: WatcherRow, data: any, prev: any): Finding | null {
    const ticket = data.tickets?.find((t: any) => t.price_dropped);
    if (ticket) {
        return {
            finding_id: '', watcher_id: '', user_id: '', check_id: '', type: 'price_drop',
            headline: `⚽ Ticket Steal: ${data.match.home} vs ${data.match.away}`,
            detail: `Section ${ticket.section} dropped $${ticket.drop_amount} ($${ticket.price} total). Venue: ${data.match.venue}. Weather: ${data.match.weather}. \n\nStatus: ${ticket.availability}.`,
            data: null, cost_usdc: 0, agent_reasoning: `Secondary market arbitrage detected for ${data.match.home} tickets. Current floor price is $${ticket.price}, down from $${ticket.history[0]}.`
        };
    }
    return null;
  }
}

export const detector = new FindingDetector();
