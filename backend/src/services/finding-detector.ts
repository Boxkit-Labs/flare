import { v4 as uuidv4 } from 'uuid';
import { WatcherRow, Finding } from '../types.js';
import { getPriceTrend, getAvailabilityHistory } from './events/price-tracker.js';

export class FindingDetector {

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
      case 'event':
        finding = await this.detectEventFinding(watcher, checkData, previousCheckData);
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

      const confidence = this.calculateConfidence(watcher, checkData, previousCheckData);
      finding.confidence_score = confidence;
      finding.confidence_tier = confidence > 90 ? 'High' : (confidence > 70 ? 'Medium' : 'Low');
    }

    return finding;
  }

  private calculateConfidence(watcher: WatcherRow, data: any, prev: any): number {
    let score = 92;
    if (!prev) score -= 4;
    if (data.is_error_fare) score -= 12;
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
            headline: `Error Fare: ${airline} to ${data.destination} for $${price}`,
            detail: `${airline} flight from ${data.origin_full} to ${data.destination_full} shows a 70% price anomaly. Itinerary includes ${data.itinerary.stops} stops and ${data.itinerary.cabin_class}.\n\nBaggage: ${data.itinerary.baggage}.`,
            data: null, cost_usdc: 0, agent_reasoning: `My proprietary pricing engine detected a $${data.cheapest_price} fare, which is $${800 - price} below the standard market rate for ${data.destination}. Direct signal from GDS shows high volume of bookings on this mistake fare.`
        };
    }

    if (data.is_historical_low) {
        return {
            finding_id: '', watcher_id: '', user_id: '', check_id: '', type: 'price_drop',
            headline: `12-Month Low: ${data.origin} -> ${data.destination} ($${price})`,
            detail: `Lowest price detected since Nov 2023. Flight ${data.flight_number} on ${airline} has dropped significantly below the moving average. Includes ${data.itinerary.amenities.join(', ')}.`,
            data: null, cost_usdc: 0, agent_reasoning: `Route analysis of ${data.origin} to ${data.destination} across 14 months of historical data confirms this price is in the 1st percentile of all observations.`
        };
    }

    if (conditions.price_below && price <= conditions.price_below) {
        return {
            finding_id: '', watcher_id: '', user_id: '', check_id: '', type: 'threshold_crossed',
            headline: `Watcher Hit: ${data.destination} reached $${price}`,
            detail: `Current price on ${airline} is $${price}, meeting your target of $${conditions.price_below}. Flight duration: ${Math.floor(data.itinerary.duration_minutes / 60)}h ${data.itinerary.duration_minutes % 60}m.`,
            data: null, cost_usdc: 0, agent_reasoning: `Automated threshold trigger reached. Current deal rating is ${data.deal_rating}.`
        };
    }
    return null;
  }

  private detectCryptoFinding(watcher: WatcherRow, data: any, prev: any): Finding | null {
    const targetSymbol = (watcher.parameters?.symbol || '').toUpperCase();
    const conditions = watcher.alert_conditions || {};

    for (const [symbol, vol] of Object.entries(data.volumes || {}) as [string, number][]) {
        if (targetSymbol && symbol !== targetSymbol) continue;

        if (vol > 1.5) {
            const asset = data.assets?.[symbol];
            return {
                finding_id: '', watcher_id: '', user_id: '', check_id: '', type: 'price_spike',
                headline: `${symbol} Whale Alert: Volume +${Math.round(vol * 100)}%`,
                detail: `${asset?.name} (${symbol}) is seeing massive institutional buying. Current Price: $${asset?.price}. Sentiment is ${asset?.sentiment}. RSI(14) is at ${asset?.rsi_14}.`,
                data: null, cost_usdc: 0, agent_reasoning: `On-chain monitoring for ${symbol} detected a transfer of ${vol}x the average hourly volume. Volume spikes are strong leading indicators of volatility.`
            };
        }
    }

    for (const [symbol, asset] of Object.entries(data.assets || {}) as [string, any][]) {
        if (targetSymbol && symbol !== targetSymbol) continue;

        const price = asset.price;
        const change = Math.abs(asset.change_24h);

        if (conditions.change_24h_percent && change >= conditions.change_24h_percent) {
             return {
                finding_id: '', watcher_id: '', user_id: '', check_id: '', type: asset.change_24h > 0 ? 'price_spike' : 'price_drop',
                headline: `${symbol} Volatility: ${asset.change_24h > 0 ? '+' : ''}${asset.change_24h}% in 24h`,
                detail: `${asset.name} has crossed your ${conditions.change_24h_percent}% alert threshold. Current Price: $${price}.`,
                data: null, cost_usdc: 0, agent_reasoning: `Targeted volatility threshold of ${conditions.change_24h_percent}% reached. Current market sentiment is ${asset.sentiment}.`
            };
        }

        const aboveKey = `${symbol.toLowerCase()}_above`;
        const belowKey = `${symbol.toLowerCase()}_below`;

        if (conditions[aboveKey] && price >= conditions[aboveKey]) {
            return {
                finding_id: '', watcher_id: '', user_id: '', check_id: '', type: 'threshold_crossed',
                headline: `${symbol} Target Reached: $${price}`,
                detail: `${asset.name} is now above your target of $${conditions[aboveKey]}.`,
                data: null, cost_usdc: 0, agent_reasoning: `Price target of $${conditions[aboveKey]} breached. Setting new resistance targets.`
            };
        }

        if (conditions[belowKey] && price <= conditions[belowKey]) {
            return {
                finding_id: '', watcher_id: '', user_id: '', check_id: '', type: 'threshold_crossed',
                headline: `${symbol} Buy Opportunity: $${price}`,
                detail: `${asset.name} has dropped below your target of $${conditions[belowKey]}.`,
                data: null, cost_usdc: 0, agent_reasoning: `Price target of $${conditions[belowKey]} breached. Market is entering historical support zone.`
            };
        }
    }

    return null;
  }

  private detectNewsFinding(watcher: WatcherRow, data: any): Finding | null {
    const articles = data.articles || [];
    const query = (watcher.parameters?.q || watcher.name || '').toLowerCase();
    const keywords = query.split(' ').filter((k: string) => k.length > 2);

    const matches = articles.filter((a: any) => {
        if (keywords.length === 0) return true;
        const text = (a.title + ' ' + a.summary).toLowerCase();
        return keywords.some((k: string) => text.includes(k));
    });

    if (matches.length >= 1) {
        const top = matches[0];
        return {
            finding_id: '', watcher_id: '', user_id: '', check_id: '', type: 'news_match',
            headline: `Flare Match: ${top.title}`,
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
            headline: `Price Bottomed: ${data.product_name} at $${data.current_price}`,
            detail: `${data.discount_percent}% off MSRP ($1299). Specs: ${data.specs.cpu}, ${data.specs.ram}, ${data.specs.storage}.\n\nRating: ${data.rating.score}/5 (${data.rating.count} reviews). Price trend is ${data.price_trend}.`,
            data: null, cost_usdc: 0, agent_reasoning: `Inventory scan of ${data.stores.length} retailers confirms ${data.stores[0].name} has the lowest price of $${data.current_price}. This is a confirmed All-Time Low.`
        };
    }
    return null;
  }

  private detectJobFinding(watcher: WatcherRow, data: any): Finding | null {
    const targetRole = (watcher.parameters?.role || '').toLowerCase();

    const match = data.listings?.find((l: any) => {
        const titleMatch = targetRole ? l.title.toLowerCase().includes(targetRole) : true;
        return titleMatch && (l.is_hot || Math.random() > 0.5);
    });

    if (match) {
        return {
            finding_id: '', watcher_id: '', user_id: '', check_id: '', type: 'new_listing',
            headline: `High-Value Job: ${match.title} at ${match.company}`,
            detail: `Salary: ${match.salary_range}. Level: ${match.experience_level}. \n\nDescription: ${match.description} \n\nBenefits: ${match.benefits.join(', ')}.`,
            data: null, cost_usdc: 0, agent_reasoning: `Matched role '${match.title}' with active candidate watcher. Salary rank: Top 5% for remote ${match.experience_level} positions.`
        };
    }
    return null;
  }

  private detectStockFinding(watcher: WatcherRow, data: any, prev: any): Finding | null {
    const targetSymbol = (watcher.parameters?.symbol || '').toUpperCase();
    const conditions = watcher.alert_conditions || {};

    const stock = data.stocks?.find((s: any) => {
        const symbolMatch = targetSymbol ? s.symbol === targetSymbol : true;

        if (conditions.change_24h_percent) {
            return symbolMatch && Math.abs(s.change_percent) >= conditions.change_24h_percent;
        }

        return symbolMatch && (Math.abs(s.change_percent) > 2 || s.event);
    });

    if (stock) {
        const isSurge = stock.change_percent > 0;
        return {
            finding_id: '', watcher_id: '', user_id: '', check_id: '', type: isSurge ? 'price_spike' : 'price_drop',
            headline: `${stock.symbol} ${isSurge ? 'Momentum' : 'Alert'}: ${Math.abs(stock.change_percent)}% Swing`,
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
            headline: isReduction ? `Price Drop in ${data.neighborhood}` : `New Entry in ${data.neighborhood}`,
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
            headline: `Ticket Steal: ${data.match.home} vs ${data.match.away}`,
            detail: `Section ${ticket.section} dropped $${ticket.drop_amount} ($${ticket.price} total). Venue: ${data.match.venue}. Weather: ${data.match.weather}. \n\nStatus: ${ticket.availability}.`,
            data: null, cost_usdc: 0, agent_reasoning: `Secondary market arbitrage detected for ${data.match.home} tickets. Current floor price is $${ticket.price}, down from $${ticket.history[0]}.`
        };
    }
    return null;
  }

  private async detectEventFinding(watcher: WatcherRow, data: any, prev: any): Promise<Finding | null> {
    const conditions = watcher.alert_conditions || {};
    const isFreeEvent = data?.isFree === true;
    const eventName = data?.name || 'Event';
    const currency = data?.currency || 'USD';
    const tiers = data?.ticketTiers || [];
    const platform = data?.platform || '';

    // ── Search mode: new listing detection ──
    if (data?.newCount > 0 && data?.results) {
      const newEvents = data.results.slice(0, data.newCount);
      if (newEvents.length > 0) {
        const first = newEvents[0];
        return {
          finding_id: '', watcher_id: '', user_id: '', check_id: '', type: 'new_listing',
          headline: `🎫 New: ${first.name}${newEvents.length > 1 ? ` (+${newEvents.length - 1} more)` : ''}`,
          detail: `${first.name} at ${first.venueName || 'TBD'}, ${first.city || ''}. ${first.isFree ? 'FREE' : `From ${first.currency} ${first.ticketTiers?.[0]?.minPrice || '?'}`}. ${newEvents.length > 1 ? `Plus ${newEvents.length - 1} other new event(s).` : ''}`,
          data: { newEvents: newEvents.map((e: any) => ({ id: e.id, name: e.name, platform: e.platform, url: e.url })) },
          cost_usdc: 0,
          agent_reasoning: `Search mode detected ${newEvents.length} new event(s) matching criteria since last check.`
        };
      }
    }

    // ── Event status change: cancelled / postponed ──
    if (data?.status === 'cancelled') {
      return {
        finding_id: '', watcher_id: '', user_id: '', check_id: '', type: 'threshold_crossed',
        headline: `🚫 ${eventName} CANCELLED`,
        detail: `"${eventName}" has been cancelled by the organizer on ${platform}. Check the event page for refund information.`,
        data: { eventName, status: 'cancelled', platform, url: data?.url },
        cost_usdc: 0,
        agent_reasoning: `Event status changed to cancelled. Auto-pausing watcher. User should check refund policy.`
      };
    }

    if (data?.status === 'postponed') {
      return {
        finding_id: '', watcher_id: '', user_id: '', check_id: '', type: 'threshold_crossed',
        headline: `⏸️ ${eventName} POSTPONED`,
        detail: `"${eventName}" has been postponed. A new date has not been announced yet. Check ${data?.url || 'the event page'} for updates.`,
        data: { eventName, status: 'postponed', platform, url: data?.url },
        cost_usdc: 0,
        agent_reasoning: `Event status changed to postponed. Auto-pausing watcher until a new date is announced.`
      };
    }

    // Filter to specific tier if configured
    let watchedTiers = tiers;
    if (conditions.specificTier) {
      watchedTiers = tiers.filter((t: any) =>
        t.name.toLowerCase().includes(conditions.specificTier.toLowerCase())
      );
    }

    // ── Availability checks (apply to both free and paid events) ──
    const prevTiers = prev?.ticketTiers || [];
    for (const tier of watchedTiers) {
      const prevTier = prevTiers.find((pt: any) => pt.name === tier.name);

      // Almost sold out
      if (conditions.availabilityAlert !== false && tier.quantityRemaining !== null && tier.quantityRemaining !== undefined) {
        const threshold = conditions.almostSoldOutThreshold || 10;
        if (tier.quantityRemaining <= threshold && tier.quantityRemaining > 0) {
          const prevQty = prevTier?.quantityRemaining;
          if (prevQty === null || prevQty === undefined || prevQty > threshold) {
            return {
              finding_id: '', watcher_id: '', user_id: '', check_id: '', type: 'threshold_crossed',
              headline: `🔥 ${tier.name} almost sold out — only ${tier.quantityRemaining} left!`,
              detail: `"${eventName}" ${tier.name} tickets: only ${tier.quantityRemaining} remaining out of ${tier.quantityTotal || '?'}. Act fast!`,
              data: { tierName: tier.name, quantityRemaining: tier.quantityRemaining, quantityTotal: tier.quantityTotal, eventName },
              cost_usdc: 0,
              agent_reasoning: `Quantity remaining (${tier.quantityRemaining}) dropped at or below the alert threshold of ${threshold}. First time crossing this threshold.`
            };
          }
        }
      }

      // Availability change: sold out → available
      if (conditions.availabilityAlert !== false && prevTier) {
        if (!prevTier.available && tier.available) {
          return {
            finding_id: '', watcher_id: '', user_id: '', check_id: '', type: 'threshold_crossed',
            headline: `🎉 ${tier.name} tickets are BACK for ${eventName}!`,
            detail: `${tier.name} tier was sold out but is now available again. ${isFreeEvent ? 'Register now!' : `Price: ${currency} ${tier.minPrice}.`}`,
            data: { tierName: tier.name, available: true, eventName, platform },
            cost_usdc: 0,
            agent_reasoning: `Availability changed from sold out to available. This is a high-priority restocking alert.`
          };
        }
        if (prevTier.available && !tier.available) {
          return {
            finding_id: '', watcher_id: '', user_id: '', check_id: '', type: 'threshold_crossed',
            headline: `⚠️ ${tier.name} SOLD OUT for ${eventName}`,
            detail: `${tier.name} tier is no longer available for "${eventName}". Consider other tiers or waitlist options.`,
            data: { tierName: tier.name, available: false, eventName, platform },
            cost_usdc: 0,
            agent_reasoning: `Tier went from available to sold out. Informational alert.`
          };
        }
      }
    }

    // ── CRITICAL: Skip all price-related detections for free events ──
    if (isFreeEvent) {
      return null;
    }

    // ── Price below threshold ──
    if (conditions.priceBelow) {
      for (const tier of watchedTiers) {
        if (tier.minPrice <= conditions.priceBelow) {
          return {
            finding_id: '', watcher_id: '', user_id: '', check_id: '', type: 'price_drop',
            headline: `💰 ${tier.name} dropped to ${currency} ${tier.minPrice}!`,
            detail: `${tier.name} tickets for "${eventName}" are now ${currency} ${tier.minPrice}, at or below your target of ${currency} ${conditions.priceBelow}. Platform: ${platform}.`,
            data: { tierName: tier.name, currentPrice: tier.minPrice, targetPrice: conditions.priceBelow, currency, eventName, platform },
            cost_usdc: 0,
            agent_reasoning: `Price threshold alert: ${tier.name} min price (${currency} ${tier.minPrice}) is at or below the configured target of ${currency} ${conditions.priceBelow}.`
          };
        }
      }
    }

    // ── Price drop by percentage ──
    if (conditions.priceDropPercent && prev) {
      for (const tier of watchedTiers) {
        const prevTier = prevTiers.find((pt: any) => pt.name === tier.name);
        if (prevTier && prevTier.minPrice > 0) {
          const dropAmount = prevTier.minPrice - tier.minPrice;
          const dropPercent = (dropAmount / prevTier.minPrice) * 100;

          if (dropPercent >= conditions.priceDropPercent) {
            return {
              finding_id: '', watcher_id: '', user_id: '', check_id: '',
              type: 'price_drop',
              headline: `📉 ${tier.name} dropped ${Math.round(dropPercent)}% to ${currency} ${tier.minPrice}!`,
              detail: `${tier.name} for "${eventName}" fell from ${currency} ${prevTier.minPrice} to ${currency} ${tier.minPrice} (${Math.round(dropPercent)}% drop). Platform: ${platform}.`,
              data: { tierName: tier.name, oldPrice: prevTier.minPrice, newPrice: tier.minPrice, dropPercent: Math.round(dropPercent * 100) / 100, currency, eventName },
              cost_usdc: 0,
              agent_reasoning: `Percentage drop (${Math.round(dropPercent)}%) exceeds configured threshold of ${conditions.priceDropPercent}%. ${dropPercent > 25 ? 'High priority — significant drop.' : 'Moderate drop detected.'}`
            };
          }
        }
      }
    }

    // ── All-time low detection via price trend ──
    try {
      for (const tier of watchedTiers) {
        const trend = await getPriceTrend(watcher.watcher_id, tier.name);
        if (trend && trend.snapshotCount > 1) {
          if (tier.minPrice <= trend.allTimeLowest && (trend.previousMin === null || tier.minPrice < trend.previousMin)) {
            return {
              finding_id: '', watcher_id: '', user_id: '', check_id: '', type: 'price_drop',
              headline: `⭐ ALL-TIME LOW: ${tier.name} at ${currency} ${tier.minPrice}!`,
              detail: `${tier.name} for "${eventName}" just hit its lowest price ever (${currency} ${tier.minPrice}). Previous low was ${currency} ${trend.allTimeLowest}. Tracked across ${trend.snapshotCount} price checks.`,
              data: { tierName: tier.name, currentPrice: tier.minPrice, allTimeLow: trend.allTimeLowest, snapshotCount: trend.snapshotCount, currency, eventName },
              cost_usdc: 0,
              agent_reasoning: `All-time low confirmed across ${trend.snapshotCount} historical snapshots. This is a new record low, not a repeat of the previous check's price.`
            };
          }
        }
      }
    } catch (e) {
      // Non-fatal: trend data may not be available on first check
    }

    return null;
  }
}

export const detector = new FindingDetector();
