import axios, { AxiosInstance, AxiosError } from 'axios';
import { 
  EventSearchParams, 
  EventResult, 
  EventSearchResponse, 
  EventProviderInterface, 
  TicketTier,
  EventCategory,
  EventStatus
} from '../types';

export class TicketmasterProvider implements EventProviderInterface {
  private client: AxiosInstance;
  private apiKey: string;
  private baseUrl = 'https://app.ticketmaster.com/discovery/v2';

  constructor(apiKey: string) {
    this.apiKey = apiKey;
    this.client = axios.create({
      baseURL: this.baseUrl,
      params: {
        apikey: this.apiKey
      }
    });

    // Handle rate limiting delay
    this.client.interceptors.response.use(async (response) => {
      const remaining = parseInt(response.headers['x-rate-limit-remaining'] || '1000', 10);
      if (remaining < 100) {
        await new Promise(resolve => setTimeout(resolve, 1000));
      }
      return response;
    });
  }

  getName(): string {
    return 'Ticketmaster';
  }

  getSupportedCountries(): string[] {
    return [
      'US', 'CA', 'MX', 'GB', 'IE', 'DE', 'FR', 'ES', 'IT', 'NL', 
      'BE', 'AT', 'CH', 'SE', 'NO', 'DK', 'FI', 'PL', 'AU', 'NZ'
    ];
  }

  private mapCategoryToTicketmaster(category?: EventCategory): string | undefined {
    if (!category) return undefined;
    const mapping: Record<string, string> = {
      music: 'Music',
      sports: 'Sports',
      arts: 'Arts & Theatre',
      comedy: 'Comedy',
      conference: 'Miscellaneous',
      family: 'Family'
    };
    return mapping[category] || undefined;
  }

  private mapTicketmasterToCategory(segmentName: string): EventCategory {
    const mapping: Record<string, EventCategory> = {
      'Music': 'music',
      'Sports': 'sports',
      'Arts & Theatre': 'arts',
      'Comedy': 'comedy',
      'Miscellaneous': 'conference',
      'Family': 'family'
    };
    return mapping[segmentName] || 'other';
  }

  private mapStatus(statusCode: string): EventStatus {
    switch (statusCode) {
      case 'onsale':
      case 'offsale':
        return 'active';
      case 'cancelled':
        return 'cancelled';
      case 'postponed':
        return 'postponed';
      case 'rescheduled':
        return 'rescheduled';
      default:
        return 'active';
    }
  }

  private parseEvent(tmEvent: any): EventResult {
    const venue = tmEvent._embedded?.venues?.[0];
    const classifications = tmEvent.classifications?.[0];
    
    // Pick image: 16:9 ratio and at least 640px width
    const image = tmEvent.images?.find((img: any) => 
      img.ratio === '16_9' && img.width >= 640
    ) || tmEvent.images?.[0];

    // Price ranges to TicketTiers
    const priceRanges = tmEvent.priceRanges || [];
    const ticketTiers: TicketTier[] = priceRanges.map((pr: any) => ({
      name: pr.type || 'Standard',
      minPrice: pr.min || 0,
      maxPrice: pr.max || 0,
      currency: pr.currency || 'USD',
      available: true // Ticketmaster doesn't explicitly say tier availability here, usually inferred from event status
    }));

    const isFree = ticketTiers.length === 0 || ticketTiers.every(t => t.maxPrice === 0);

    return {
      id: tmEvent.id,
      platform: this.getName(),
      name: tmEvent.name,
      description: tmEvent.info || tmEvent.pleaseNote,
      category: this.mapTicketmasterToCategory(classifications?.segment?.name),
      startDate: tmEvent.dates?.start?.dateTime || tmEvent.dates?.start?.localDate,
      endDate: tmEvent.dates?.end?.dateTime,
      venueName: venue?.name || 'Unknown Venue',
      venueAddress: venue?.address?.line1,
      city: venue?.city?.name,
      country: venue?.country?.countryCode,
      lat: venue?.location?.latitude ? parseFloat(venue.location.latitude) : undefined,
      lng: venue?.location?.longitude ? parseFloat(venue.location.longitude) : undefined,
      imageUrl: image?.url,
      url: tmEvent.url,
      popularity: tmEvent.score ? tmEvent.score / 100 : undefined,
      isFree,
      ticketTiers,
      currency: priceRanges[0]?.currency || 'USD',
      status: this.mapStatus(tmEvent.dates?.status?.code),
      lastChecked: new Date().toISOString()
    };
  }

  async search(params: EventSearchParams): Promise<EventSearchResponse> {
    try {
      const tmParams: any = {
        keyword: params.q,
        city: params.city,
        countryCode: params.country,
        radius: params.radius || 50,
        unit: 'km',
        classificationName: this.mapCategoryToTicketmaster(params.category),
        startDateTime: params.dateFrom,
        endDateTime: params.dateTo,
        page: params.page ? params.page - 1 : 0,
        size: params.limit || 20
      };

      if (params.lat && params.lng) {
        tmParams.latlong = `${params.lat},${params.lng}`;
      }

      const response = await this.client.get('/events.json', { params: tmParams });
      
      const events = response.data._embedded?.events || [];
      const pageInfo = response.data.page || {};

      return {
        results: events.map((e: any) => this.parseEvent(e)),
        totalCount: pageInfo.totalElements || 0,
        page: (pageInfo.number || 0) + 1,
        totalPages: pageInfo.totalPages || 0,
        platform: this.getName()
      };
    } catch (error) {
      return this.handleError(error);
    }
  }

  async getEventById(id: string): Promise<EventResult | null> {
    try {
      const response = await this.client.get(`/events/${id}.json`);
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
        console.warn('[Ticketmaster] Rate limit reached');
        message = 'Rate limit reached';
      } else if (axiosError.response?.status === 401) {
        console.error('[Ticketmaster] Invalid API key');
        message = 'API key error';
      } else {
        console.error(`[Ticketmaster] Network or server error: ${axiosError.message}`);
        message = 'Network failure';
      }
    } else {
      console.error(`[Ticketmaster] Unknown error: ${error.message}`);
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
