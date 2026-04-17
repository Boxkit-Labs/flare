import { eventService } from './event-service.js';
import { storePriceSnapshot } from './price-tracker.js';
import { EventResult, EventSearchParams } from './types.js';
import { getChecksByWatcherId } from '../../db/queries.js';

export interface EventCheckResult {
  success: boolean;
  data: any;
  summary: string;
  agentReasoning: string;
  findings: EventFinding[];
}

export interface EventFinding {
  type: 'price_drop' | 'price_spike' | 'status_change' | 'new_listing' | 'availability_change';
  headline: string;
  detail: string;
  data: any;
}

// ─── specific_event mode ────────────────────────────────────────────

export async function executeSpecificEventCheck(
  watcherId: string,
  params: any
): Promise<EventCheckResult> {
  const { platform, externalId, watchedTiers, alertConditions } = params;

  try {
    const event = await eventService.getEventById(platform, externalId);

    if (!event) {
      return {
        success: false,
        data: null,
        summary: 'Event no longer found on platform.',
        agentReasoning: `Event ${externalId} on ${platform} could not be retrieved. It may have been removed or the platform is experiencing issues.`,
        findings: []
      };
    }

    // Store full price snapshot
    await storePriceSnapshot(watcherId, event);

    // Check for status changes (cancelled, postponed, rescheduled)
    const findings: EventFinding[] = [];

    if (event.status === 'cancelled') {
      findings.push({
        type: 'status_change',
        headline: `🚫 ${event.name} has been CANCELLED`,
        detail: `The event "${event.name}" at ${event.venueName} has been cancelled by the organizer.`,
        data: { eventName: event.name, status: event.status, platform, externalId }
      });
    } else if (event.status === 'postponed') {
      findings.push({
        type: 'status_change',
        headline: `⏸️ ${event.name} has been POSTPONED`,
        detail: `The event "${event.name}" at ${event.venueName} has been postponed. Check the event page for a new date.`,
        data: { eventName: event.name, status: event.status, platform, externalId, url: event.url }
      });
    } else if (event.status === 'rescheduled') {
      findings.push({
        type: 'status_change',
        headline: `📅 ${event.name} has been RESCHEDULED`,
        detail: `The event "${event.name}" has been rescheduled to ${event.startDate}.`,
        data: { eventName: event.name, status: event.status, newDate: event.startDate, platform, externalId }
      });
    }

    // Filter tiers if user specified specific ones
    let relevantTiers = event.ticketTiers;
    if (watchedTiers && watchedTiers.length > 0) {
      relevantTiers = event.ticketTiers.filter(t =>
        watchedTiers.some((wt: string) => t.name.toLowerCase().includes(wt.toLowerCase()))
      );
    }

    // Check alert conditions against tiers
    if (alertConditions) {
      for (const tier of relevantTiers) {
        // Price drop detection
        if (alertConditions.maxPrice && tier.minPrice <= alertConditions.maxPrice) {
          findings.push({
            type: 'price_drop',
            headline: `💰 ${tier.name} tickets for ${event.name} at ${event.currency} ${tier.minPrice}`,
            detail: `${tier.name} tickets are now available at ${event.currency} ${tier.minPrice}, which is at or below your target of ${event.currency} ${alertConditions.maxPrice}.`,
            data: { tierName: tier.name, currentPrice: tier.minPrice, targetPrice: alertConditions.maxPrice, currency: event.currency }
          });
        }

        // Availability change
        if (alertConditions.alertOnAvailability && !tier.available) {
          findings.push({
            type: 'availability_change',
            headline: `⚠️ ${tier.name} tickets for ${event.name} are SOLD OUT`,
            detail: `${tier.name} tier is no longer available for "${event.name}".`,
            data: { tierName: tier.name, available: false }
          });
        }
      }
    }

    // Build summary
    const tierSummaries = relevantTiers.map(t =>
      `${t.name}: ${event.currency} ${t.minPrice}–${t.maxPrice} (${t.available ? 'Available' : 'Sold Out'})`
    );
    const summary = `${event.name} at ${event.venueName} | Status: ${event.status} | ${tierSummaries.join(' | ')}`;

    const agentReasoning = findings.length > 0
      ? `Found ${findings.length} alert condition(s) met: ${findings.map(f => f.type).join(', ')}.`
      : `Checked ${relevantTiers.length} tier(s) for "${event.name}". No alert conditions met. Prices and availability recorded.`;

    return {
      success: true,
      data: event,
      summary,
      agentReasoning,
      findings
    };
  } catch (error: any) {
    return {
      success: false,
      data: null,
      summary: `Error checking event: ${error.message}`,
      agentReasoning: `Failed to fetch event ${externalId} from ${platform}: ${error.message}`,
      findings: []
    };
  }
}

// ─── search mode ────────────────────────────────────────────────────

export async function executeEventSearchCheck(
  watcherId: string,
  params: any
): Promise<EventCheckResult> {
  try {
    const searchParams: EventSearchParams = {
      q: params.q,
      city: params.city,
      country: params.country,
      lat: params.lat,
      lng: params.lng,
      radius: params.radius,
      category: params.category,
      dateFrom: params.dateFrom,
      dateTo: params.dateTo,
      platform: params.platform,
      minPrice: params.minPrice,
      maxPrice: params.maxPrice,
      isFree: params.isFree,
      page: 1,
      limit: 20
    };

    const response = await eventService.search(searchParams);

    if (!response || response.results.length === 0) {
      return {
        success: true,
        data: { results: [], resultIds: [] },
        summary: 'No events found matching your search criteria.',
        agentReasoning: 'Search returned zero results. Criteria may be too narrow or no events match currently.',
        findings: []
      };
    }

    // Get previous check's stored result IDs
    const previousChecks = await getChecksByWatcherId(watcherId, 1, 0);
    let previousResultIds: string[] = [];
    if (previousChecks.length > 0 && previousChecks[0].response_data) {
      try {
        const prevData = typeof previousChecks[0].response_data === 'string'
          ? JSON.parse(previousChecks[0].response_data)
          : previousChecks[0].response_data;
        previousResultIds = prevData.resultIds || [];
      } catch { /* first check, no previous data */ }
    }

    // Current result IDs
    const currentResultIds = response.results.map(e => `${e.platform}:${e.id}`);

    // Find new events
    const previousSet = new Set(previousResultIds);
    const newEvents = response.results.filter(e => !previousSet.has(`${e.platform}:${e.id}`));

    // Generate findings for new listings
    const findings: EventFinding[] = newEvents.map(event => ({
      type: 'new_listing' as const,
      headline: `🎫 New event: ${event.name}`,
      detail: `${event.name} at ${event.venueName}, ${event.city} on ${event.startDate?.split('T')[0] || 'TBD'}. ${event.isFree ? 'FREE' : `From ${event.currency} ${event.ticketTiers[0]?.minPrice || '?'}`}.`,
      data: {
        eventId: event.id,
        platform: event.platform,
        name: event.name,
        venue: event.venueName,
        city: event.city,
        date: event.startDate,
        isFree: event.isFree,
        url: event.url,
        category: event.category
      }
    }));

    const summary = `Found ${response.results.length} event(s). ${newEvents.length} new since last check.${response.warnings ? ` Warnings: ${response.warnings.join('; ')}` : ''}`;

    const agentReasoning = newEvents.length > 0
      ? `Identified ${newEvents.length} new event(s) matching search criteria since previous check. ${response.results.length} total results across ${response.platform} provider(s).`
      : `${response.results.length} events found but all were previously seen. No new listings to report.`;

    return {
      success: true,
      data: {
        results: response.results,
        resultIds: currentResultIds,
        newCount: newEvents.length,
        totalCount: response.totalCount,
        warnings: response.warnings
      },
      summary,
      agentReasoning,
      findings
    };
  } catch (error: any) {
    return {
      success: false,
      data: null,
      summary: `Error during event search: ${error.message}`,
      agentReasoning: `Event search failed: ${error.message}`,
      findings: []
    };
  }
}

// ─── Main event check dispatcher ────────────────────────────────────

export async function executeEventCheck(
  watcherId: string,
  params: any
): Promise<EventCheckResult> {
  const mode = params.mode || 'specific_event';

  if (mode === 'search') {
    return executeEventSearchCheck(watcherId, params);
  }

  return executeSpecificEventCheck(watcherId, params);
}
