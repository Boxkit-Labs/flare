export type EventCategory = 
  | 'music' 
  | 'sports' 
  | 'arts' 
  | 'comedy' 
  | 'conference' 
  | 'festival' 
  | 'theatre' 
  | 'nightlife' 
  | 'family' 
  | 'other';

export type EventStatus = 'active' | 'cancelled' | 'postponed' | 'rescheduled';

export interface EventSearchParams {
  q?: string;
  city?: string;
  country?: string; // ISO country code
  lat?: number;
  lng?: number;
  radius?: number; // defaulting to 50 in implementation
  category?: EventCategory;
  dateFrom?: string; // ISO string
  dateTo?: string; // ISO string
  platform?: string;
  minPrice?: number;
  maxPrice?: number;
  isFree?: boolean;
  page?: number; // defaulting to 1 in implementation
  limit?: number; // defaulting to 20 in implementation
}

export interface TicketTier {
  name: string; // e.g., GA, VIP, VVIP
  minPrice: number;
  maxPrice: number;
  currency: string;
  available: boolean;
  quantityRemaining?: number;
  quantityTotal?: number;
  onSaleDate?: string; // ISO string
  offSaleDate?: string; // ISO string
}

export interface EventResult {
  id: string; // external ID from platform
  platform: string;
  name: string;
  description?: string;
  category: EventCategory;
  startDate: string; // ISO string
  endDate?: string; // ISO string
  venueName: string;
  venueAddress?: string;
  city: string;
  country: string;
  lat?: number;
  lng?: number;
  imageUrl?: string;
  url: string; // direct booking URL
  popularity?: number; // 0 to 1
  isFree: boolean;
  ticketTiers: TicketTier[];
  currency: string;
  status: EventStatus;
  lastChecked: string; // ISO timestamp
}

export interface EventSearchResponse {
  results: EventResult[];
  totalCount: number;
  page: number;
  totalPages: number;
  platform: string;
  error?: string;
}

export interface EventProviderInterface {
  search(params: EventSearchParams): Promise<EventSearchResponse>;
  getEventById(id: string): Promise<EventResult | null>;
  getName(): string; // platform display name
  getSupportedCountries(): string[]; // ISO country codes
}
