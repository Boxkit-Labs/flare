import axios, { AxiosInstance, AxiosError } from 'axios';
import { 
  EventSearchParams, 
  EventResult, 
  EventSearchResponse, 
  EventProviderInterface, 
  TicketTier,
  EventCategory
} from '../types.js';

export class SeatGeekProvider implements EventProviderInterface {
  private client: AxiosInstance;
  private clientId: string;
  private baseUrl = 'https://api.seatgeek.com/2';

  constructor(clientId: string) {
    this.clientId = clientId;
    this.client = axios.create({
      baseURL: this.baseUrl,
      params: {
        client_id: this.clientId
      }
    });

    // Handle rate limiting delay if needed (same pattern as Ticketmaster)
    this.client.interceptors.response.use(async (response) => {
      const remaining = parseInt(response.headers['x-rate-limit-remaining'] || '1000', 10);
      if (remaining < 100) {
        await new Promise(resolve => setTimeout(resolve, 1000));
      }
      return response;
    });
  }

  getName(): string {
    return 'SeatGeek';
  }

  getSupportedCountries(): string[] {
    return ['US', 'CA'];
  }

  private kmToMiles(km: number): string {
    return `${Math.round(km * 0.621371)}mi`;
  }

  private mapCategoryToSeatGeek(category?: EventCategory): string | undefined {
    if (!category) return undefined;
    const mapping: Record<string, string> = {
      music: 'concert',
      sports: 'sports',
      comedy: 'comedy',
      theatre: 'theater',
      family: 'family'
    };
    return mapping[category] || undefined;
  }

  private mapSeatGeekToCategory(taxonomies: any[]): EventCategory {
    if (!taxonomies || taxonomies.length === 0) return 'other';
    
    const primeTaxonomy = taxonomies[0].name;
    const mapping: Record<string, EventCategory> = {
      'concert': 'music',
      'sports': 'sports',
      'comedy': 'comedy',
      'theater': 'theatre',
      'family': 'family'
    };
    
    return mapping[primeTaxonomy] || 'other';
  }

  private parseEvent(sgEvent: any): EventResult {
    const venue = sgEvent.venue || {};
    const stats = sgEvent.stats || {};
    const performer = sgEvent.performers?.[0] || {};

    const ticketTiers: TicketTier[] = [];
    if (stats.lowest_price !== null || stats.highest_price !== null) {
      ticketTiers.push({
        name: 'Marketplace',
        minPrice: stats.lowest_price || 0,
        maxPrice: stats.highest_price || 0,
        currency: 'USD',
        available: (sgEvent.listing_count || 0) > 0,
        quantityRemaining: sgEvent.listing_count
      });
    }

    const isFree = ticketTiers.length === 0 || ticketTiers.every(t => t.maxPrice === 0);

    return {
      id: sgEvent.id.toString(),
      platform: this.getName(),
      name: sgEvent.title,
      description: sgEvent.description || sgEvent.short_title,
      category: this.mapSeatGeekToCategory(sgEvent.taxonomies),
      startDate: sgEvent.datetime_utc,
      venueName: venue.name || 'Unknown Venue',
      venueAddress: venue.address,
      city: venue.city,
      country: venue.country,
      lat: venue.location?.lat,
      lng: venue.location?.lon,
      imageUrl: performer.image,
      url: sgEvent.url,
      popularity: sgEvent.score || 0,
      isFree,
      ticketTiers,
      currency: 'USD',
      status: 'active', // SeatGeek doesn't list cancelled events usually
      lastChecked: new Date().toISOString()
    };
  }

  async search(params: EventSearchParams): Promise<EventSearchResponse> {
    try {
      const sgParams: any = {
        q: params.q,
        'venue.city': params.city,
        'venue.country': params.country,
        lat: params.lat,
        lon: params.lng,
        range: params.radius ? this.kmToMiles(params.radius) : undefined,
        'taxonomies.name': this.mapCategoryToSeatGeek(params.category),
        'datetime_utc.gte': params.dateFrom,
        'datetime_utc.lte': params.dateTo,
        page: params.page || 1,
        per_page: params.limit || 20
      };

      // Remove undefined keys
      Object.keys(sgParams).forEach(key => sgParams[key] === undefined && delete sgParams[key]);

      const response = await this.client.get('/events', { params: sgParams });
      
      const events = response.data.events || [];
      const meta = response.data.meta || {};

      return {
        results: events.map((e: any) => this.parseEvent(e)),
        totalCount: meta.total || 0,
        page: meta.page || 1,
        totalPages: Math.ceil((meta.total || 0) / (meta.per_page || 20)),
        platform: this.getName()
      };
    } catch (error) {
      return this.handleError(error);
    }
  }

  async getEventById(id: string): Promise<EventResult | null> {
    try {
      const response = await this.client.get(`/events/${id}`);
      return this.parseEvent(response.data);
    } catch (error) {
      this.handleError(error);
      return null;
    }
  }

  private handleError(error: any): EventSearchResponse {
    let message = 'An unexpected error occurred';
    
    if (axios.isAxiosError(error)) {
      const axiosError = error as AxiosError;
      if (axiosError.response?.status === 429) {
        console.warn('[SeatGeek] Rate limit reached');
        message = 'Rate limit reached';
      } else if (axiosError.response?.status === 401) {
        console.error('[SeatGeek] Invalid client ID');
        message = 'API key error';
      } else {
        console.error(`[SeatGeek] Network or server error: ${axiosError.message}`);
        message = 'Network failure';
      }
    } else {
      console.error(`[SeatGeek] Unknown error: ${error.message}`);
    }

    return {
      results: [],
      totalCount: 0,
      page: 1,
      totalPages: 0,
      platform: this.getName(),
      error: message
    };
  }
}
