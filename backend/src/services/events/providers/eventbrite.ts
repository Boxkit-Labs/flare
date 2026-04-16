import axios, { AxiosInstance, AxiosError } from 'axios';
import { 
  EventSearchParams, 
  EventResult, 
  EventSearchResponse, 
  EventProviderInterface, 
  TicketTier,
  EventCategory,
  EventStatus
} from '../types.js';

export class EventbriteProvider implements EventProviderInterface {
  private client: AxiosInstance;
  private token: string;
  private baseUrl = 'https://www.eventbriteapi.com/v3';

  constructor(token: string) {
    this.token = token;
    this.client = axios.create({
      baseURL: this.baseUrl,
      headers: {
        'Authorization': `Bearer ${this.token}`
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
    return 'Eventbrite';
  }

  getSupportedCountries(): string[] {
    return [
      'US', 'CA', 'GB', 'IE', 'AU', 'NZ', 'DE', 'FR', 'ES', 'IT', 
      'NL', 'BE', 'BR', 'MX', 'AR', 'NG', 'GH', 'KE', 'ZA', 'IN', 
      'SG', 'HK', 'JP'
    ];
  }

  private mapCategoryToEventbrite(category?: EventCategory): string | undefined {
    if (!category) return undefined;
    const mapping: Record<string, string> = {
      music: '103',
      sports: '108',
      arts: '105',
      conference: '101',
      festival: '110',
      family: '115'
    };
    return mapping[category] || undefined;
  }

  private mapStatus(status: string): EventStatus {
    switch (status) {
      case 'live':
      case 'ended': // Per prompt requirements
        return 'active';
      case 'canceled':
        return 'cancelled';
      default:
        return 'active';
    }
  }

  private truncateDescription(text?: string): string | undefined {
    if (!text) return undefined;
    return text.length > 500 ? text.substring(0, 500) + '...' : text;
  }

  private parseEvent(ebEvent: any): EventResult {
    const venue = ebEvent.venue || {};
    const category = ebEvent.category || {};
    const ticketClasses = ebEvent.ticket_classes || [];
    
    const ticketTiers: TicketTier[] = [];

    if (ebEvent.is_free) {
      ticketTiers.push({
        name: 'Free',
        minPrice: 0,
        maxPrice: 0,
        currency: ebEvent.currency || 'USD',
        available: ebEvent.capacity ? (ebEvent.capacity > (ebEvent.inventory_total || 0)) : true
      });
    } else {
      ticketTiers.push(...ticketClasses.map((tc: any) => ({
        name: tc.name,
        minPrice: tc.cost ? parseFloat(tc.cost.major_value) : 0,
        maxPrice: tc.cost ? parseFloat(tc.cost.major_value) : 0,
        currency: tc.cost ? tc.cost.currency : 'USD',
        available: tc.on_sale_status === 'AVAILABLE',
        quantityRemaining: (tc.quantity_total || 0) - (tc.quantity_sold || 0),
        onSaleDate: tc.sales_start,
        offSaleDate: tc.sales_end
      })));
    }

    return {
      id: ebEvent.id,
      platform: this.getName(),
      name: ebEvent.name?.text || 'Untitled Event',
      description: this.truncateDescription(ebEvent.summary || ebEvent.description?.text),
      category: (category.short_name?.toLowerCase() as EventCategory) || 'other',
      startDate: ebEvent.start?.utc,
      endDate: ebEvent.end?.utc,
      venueName: venue.name || 'Unknown Venue',
      venueAddress: venue.address?.localized_address_display,
      city: venue.address?.city,
      country: venue.address?.country,
      lat: venue.latitude ? parseFloat(venue.latitude) : undefined,
      lng: venue.longitude ? parseFloat(venue.longitude) : undefined,
      imageUrl: ebEvent.logo?.url,
      url: ebEvent.url,
      popularity: undefined,
      isFree: ebEvent.is_free,
      ticketTiers,
      currency: ebEvent.currency || 'USD',
      status: this.mapStatus(ebEvent.status),
      lastChecked: new Date().toISOString()
    };
  }

  private isNigeriaLocation(city?: string, country?: string): boolean {
    if (country === 'NG') return true;
    if (!city) return false;
    const ngCities = ['lagos', 'abuja', 'port harcourt', 'ibadan', 'kano', 'benin', 'enugu'];
    return ngCities.some(c => city.toLowerCase().includes(c));
  }

  async search(params: EventSearchParams): Promise<EventSearchResponse> {
    try {
      let locationAddress = params.city;
      if (params.country) {
        locationAddress = locationAddress ? `${locationAddress}, ${params.country}` : params.country;
      }

      if (this.isNigeriaLocation(params.city, params.country)) {
          const cityBase = params.city || 'Lagos';
          locationAddress = `${cityBase}, Nigeria`;
      }

      const ebParams: any = {
        q: params.q,
        'location.address': locationAddress,
        'location.latitude': params.lat,
        'location.longitude': params.lng,
        'location.within': params.radius ? `${params.radius}km` : undefined,
        'categories': this.mapCategoryToEventbrite(params.category),
        'price': params.isFree ? 'free' : undefined,
        'expand': 'ticket_classes,venue,category',
        'page': params.page || 1
      };

      // Remove undefined keys
      Object.keys(ebParams).forEach(key => ebParams[key] === undefined && delete ebParams[key]);

      const response = await this.client.get('/events/search/', { params: ebParams });
      
      const events = response.data.events || [];
      const pagination = response.data.pagination || {};

      return {
        results: events.map((e: any) => this.parseEvent(e)),
        totalCount: pagination.object_count || 0,
        page: pagination.page_number || 1,
        totalPages: pagination.page_count || 1,
        platform: this.getName()
      };
    } catch (error) {
      return this.handleError(error);
    }
  }

  async getEventById(id: string): Promise<EventResult | null> {
    try {
      const response = await this.client.get(`/events/${id}/`, {
        params: { expand: 'ticket_classes,venue,category' }
      });
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
        console.warn('[Eventbrite] Rate limit reached');
        message = 'Rate limit reached';
      } else if (axiosError.response?.status === 401 || axiosError.response?.status === 403) {
        console.error('[Eventbrite] Auth error');
        message = 'API key error';
      } else {
        console.error(`[Eventbrite] Network or server error: ${axiosError.message}`);
        message = 'Network failure';
      }
    } else {
      console.error(`[Eventbrite] Unknown error: ${error.message}`);
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
