import * as dotenv from 'dotenv';
import { 
  EventProviderInterface, 
  EventSearchParams, 
  EventSearchResponse, 
  EventResult,
  EventStatus
} from './types.js';
import { TicketmasterProvider } from './providers/ticketmaster.js';
import { SeatGeekProvider } from './providers/seatgeek.js';
import { EventbriteProvider } from './providers/eventbrite.js';

dotenv.config();

export class EventService {
  private static instance: EventService;
  private providers: Map<string, EventProviderInterface> = new Map();

  private constructor() {
    this.initializeProviders();
  }

  public static getInstance(): EventService {
    if (!EventService.instance) {
      EventService.instance = new EventService();
    }
    return EventService.instance;
  }

  private initializeProviders() {
    const tmKey = process.env.TICKETMASTER_API_KEY;
    if (tmKey) {
      this.providers.set('ticketmaster', new TicketmasterProvider(tmKey));
    }

    const sgClientId = process.env.SEATGEEK_CLIENT_ID;
    if (sgClientId) {
      this.providers.set('seatgeek', new SeatGeekProvider(sgClientId));
    }

    const ebToken = process.env.EVENTBRITE_TOKEN;
    if (ebToken) {
      this.providers.set('eventbrite', new EventbriteProvider(ebToken));
    }
  }

  public getSupportedPlatforms() {
    return Array.from(this.providers.values()).map(p => ({
      name: p.getName().toLowerCase(),
      displayName: p.getName(),
      supportedCountries: p.getSupportedCountries(),
      available: true
    }));
  }

  public getAvailableCountries(): string[] {
    const countries = new Set<string>();
    this.providers.forEach(p => {
      p.getSupportedCountries().forEach(c => countries.add(c));
    });
    return Array.from(countries).sort();
  }

  async search(params: EventSearchParams): Promise<EventSearchResponse> {
    const selectedPlatform = params.platform?.toLowerCase();
    
    // Route to single provider if specified and valid
    if (selectedPlatform && selectedPlatform !== 'all') {
      const provider = this.providers.get(selectedPlatform);
      if (provider) {
        let response = await provider.search(params);
        response.results = this.applyPostFilters(response.results, params);
        return response;
      }
    }

    // Otherwise, call all applicable providers
    const applicableProviders = Array.from(this.providers.values()).filter(p => {
      if (!params.country) return true;
      return p.getSupportedCountries().includes(params.country.toUpperCase());
    });

    if (applicableProviders.length === 0) {
      return {
        results: [],
        totalCount: 0,
        page: 1,
        totalPages: 0,
        platform: 'all',
        warnings: ['No providers support the requested country or no providers initialized']
      };
    }

    const results = await Promise.allSettled(
      applicableProviders.map(p => p.search(params))
    );

    let mergedResults: EventResult[] = [];
    let warnings: string[] = [];
    let totalCount = 0;
    let maxTotalPages = 0;

    results.forEach((result, index) => {
      const providerName = applicableProviders[index].getName();
      if (result.status === 'fulfilled') {
        const value = result.value;
        if (value.error) {
          warnings.push(`${providerName}: ${value.error}`);
        }
        mergedResults.push(...value.results);
        totalCount += value.totalCount;
        maxTotalPages = Math.max(maxTotalPages, value.totalPages);
      } else {
        warnings.push(`${providerName}: Search failed due to an internal error`);
      }
    });

    // Deduplicate
    mergedResults = this.deduplicateEvents(mergedResults);

    // Filter
    mergedResults = this.applyPostFilters(mergedResults, params);

    // Sort
    mergedResults = this.sortEvents(mergedResults);

    return {
      results: mergedResults,
      totalCount: mergedResults.length, // merged total might be different due to dedup/filter, but for simplicity
      page: params.page || 1,
      totalPages: maxTotalPages,
      platform: 'all',
      warnings: warnings.length > 0 ? warnings : undefined
    };
  }

  async getEventById(platform: string, id: string): Promise<EventResult | null> {
    const provider = this.providers.get(platform.toLowerCase());
    if (!provider) return null;
    return provider.getEventById(id);
  }

  private deduplicateEvents(events: EventResult[]): EventResult[] {
    const seen = new Map<string, EventResult>();
    
    events.forEach(event => {
      const date = event.startDate?.split('T')[0] || 'no-date';
      const key = `${event.name.toLowerCase()}|${date}|${event.city?.toLowerCase()}`;
      
      const existing = seen.get(key);
      if (!existing || event.ticketTiers.length > existing.ticketTiers.length) {
        seen.set(key, event);
      }
    });

    return Array.from(seen.values());
  }

  private applyPostFilters(events: EventResult[], params: EventSearchParams): EventResult[] {
    return events.filter(event => {
      // Free filter
      if (params.isFree === true && !event.isFree) return false;
      if (params.isFree === false && event.isFree) return false;

      // Price range filter
      if (params.minPrice !== undefined || params.maxPrice !== undefined) {
        const min = params.minPrice ?? 0;
        const max = params.maxPrice ?? Infinity;
        
        const hasTierInRange = event.ticketTiers.some(tier => 
          (tier.minPrice >= min && tier.minPrice <= max) || 
          (tier.maxPrice >= min && tier.maxPrice <= max) ||
          (tier.minPrice <= min && tier.maxPrice >= max)
        );
        
        if (!hasTierInRange && !event.isFree) return false;
        if (event.isFree && min > 0) return false; // Free events don't match minPrice > 0
      }

      return true;
    });
  }

  private sortEvents(events: EventResult[]): EventResult[] {
    return events.sort((a, b) => {
      // 1. Price data first
      const aHasPrice = a.ticketTiers.length > 0;
      const bHasPrice = b.ticketTiers.length > 0;
      if (aHasPrice && !bHasPrice) return -1;
      if (!aHasPrice && bHasPrice) return 1;

      // 2. Date soonest first
      const aDate = a.startDate ? new Date(a.startDate).getTime() : Infinity;
      const bDate = b.startDate ? new Date(b.startDate).getTime() : Infinity;
      if (aDate !== bDate) return aDate - bDate;

      // 3. Popularity
      const aPop = a.popularity || 0;
      const bPop = b.popularity || 0;
      return bPop - aPop;
    });
  }
}

export const eventService = EventService.getInstance();
