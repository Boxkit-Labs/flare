/**
 * Domain entities for the Events feature.
 * Pure domain objects with no framework dependencies.
 */

// ─── TicketTierEntity ────────────────────────────────────────────────

export class TicketTierEntity {
  constructor(
    public readonly name: string,
    public readonly minPrice: number,
    public readonly maxPrice: number,
    public readonly currency: string,
    public readonly available: boolean,
    public readonly quantityRemaining?: number,
    public readonly quantityTotal?: number,
    public readonly onSaleDate?: string,
    public readonly offSaleDate?: string
  ) {}

  /**
   * Returns a displayable price string (e.g., "₦45,000" or "$50.00").
   */
  get displayPrice(): string {
    const formatter = new Intl.NumberFormat(undefined, {
      style: 'currency',
      currency: this.currency,
      minimumFractionDigits: this.minPrice % 1 === 0 ? 0 : 2
    });
    
    if (this.minPrice === this.maxPrice) {
      return formatter.format(this.minPrice);
    }
    return `${formatter.format(this.minPrice)} - ${formatter.format(this.maxPrice)}`;
  }

  /**
   * Returns human-readable availability text.
   */
  get availabilityText(): string {
    if (!this.available) return 'Sold Out';
    if (this.quantityRemaining !== undefined && this.quantityRemaining <= 10) {
      return `Only ${this.quantityRemaining} left!`;
    }
    return 'Available';
  }

  /**
   * Returns a color hint for availability (e.g. for frontend use).
   */
  get availabilityColor(): string {
    if (!this.available) return '#FF3B30'; // Red
    if (this.quantityRemaining !== undefined && this.quantityRemaining <= 10) {
      return '#FF9500'; // Orange
    }
    return '#34C759'; // Green
  }
}

// ─── EventEntity ─────────────────────────────────────────────────────

export class EventEntity {
  constructor(
    public readonly externalId: string,
    public readonly platform: string,
    public readonly name: string,
    public readonly category: string,
    public readonly date: string, // ISO string
    public readonly venue: string,
    public readonly city: string,
    public readonly country: string,
    public readonly eventUrl: string,
    public readonly isFree: boolean,
    public readonly ticketTiers: TicketTierEntity[],
    public readonly currency: string,
    public readonly status: 'active' | 'cancelled' | 'postponed' | 'rescheduled',
    public readonly lastChecked: string, // ISO string
    public readonly description?: string,
    public readonly endDate?: string,
    public readonly venueAddress?: string,
    public readonly latitude?: number,
    public readonly longitude?: number,
    public readonly imageUrl?: string,
    public readonly popularity?: number // 0 to 1
  ) {}

  /**
   * Returns the lowest price formatted, or "Free" if applicable.
   */
  get formattedLowestPrice(): string {
    if (this.isFree) return 'Free';
    if (this.ticketTiers.length === 0) return 'TBD';
    
    const min = Math.min(...this.ticketTiers.map(t => t.minPrice));
    return new Intl.NumberFormat(undefined, {
      style: 'currency',
      currency: this.currency,
      minimumFractionDigits: min % 1 === 0 ? 0 : 2
    }).format(min);
  }

  /**
   * Returns the full price range of the event.
   */
  get priceRangeString(): string {
    if (this.isFree) return 'Free';
    if (this.ticketTiers.length === 0) return 'Price TBD';
    
    const prices = this.ticketTiers.flatMap(t => [t.minPrice, t.maxPrice]);
    const min = Math.min(...prices);
    const max = Math.max(...prices);
    
    const formatter = new Intl.NumberFormat(undefined, {
      style: 'currency',
      currency: this.currency,
      minimumFractionDigits: 0
    });
    
    return min === max ? formatter.format(min) : `${formatter.format(min)} - ${formatter.format(max)}`;
  }

  /**
   * Returns the overall ticket availability status.
   */
  get ticketsAvailability(): 'Available' | 'Sold Out' | 'Limited' {
    if (this.status === 'cancelled') return 'Sold Out';
    const anyAvailable = this.ticketTiers.some(t => t.available);
    if (!anyAvailable) return 'Sold Out';
    
    const totalRemaining = this.ticketTiers.reduce((acc, t) => acc + (t.quantityRemaining || 0), 0);
    const hasLimited = this.ticketTiers.some(t => t.available && t.quantityRemaining !== undefined && t.quantityRemaining <= 10);
    
    if (hasLimited) return 'Limited';
    return 'Available';
  }

  /**
   * Returns a friendly formatted date (e.g., Oct 24, 2024).
   */
  get formattedDate(): string {
    return new Date(this.date).toLocaleDateString(undefined, {
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    });
  }

  /**
   * Returns the display name of the platform.
   */
  get platformDisplayName(): string {
    const platforms: Record<string, string> = {
      ticketmaster: 'Ticketmaster',
      seatgeek: 'SeatGeek',
      eventbrite: 'Eventbrite'
    };
    return platforms[this.platform.toLowerCase()] || this.platform;
  }

  /**
   * Returns an emoji representing the event category.
   */
  get categoryEmoji(): string {
    const emojis: Record<string, string> = {
      music: '🎵',
      sports: '⚽',
      arts: '🎭',
      comedy: '😂',
      conference: '🤝',
      festival: '🎡',
      theatre: '🎭',
      nightlife: '🌙',
      family: '👨‍👩‍👧‍👦',
      other: '🎫'
    };
    return emojis[this.category.toLowerCase()] || '🎫';
  }

  /**
   * Returns true if the event date has already passed.
   */
  get isPast(): boolean {
    return new Date(this.date).getTime() < Date.now();
  }

  /**
   * Returns the number of days until the event starts.
   */
  get daysUntil(): number {
    const diff = new Date(this.date).getTime() - Date.now();
    return Math.max(0, Math.ceil(diff / (1000 * 60 * 60 * 24)));
  }
}

// ─── EventPricePointEntity ───────────────────────────────────────────

export class EventPricePointEntity {
  constructor(
    public readonly checkedAt: string, // ISO string
    public readonly tierName: string,
    public readonly minPrice: number,
    public readonly maxPrice: number,
    public readonly available: boolean,
    public readonly quantityRemaining?: number
  ) {}
}

// ─── EventWatcherParamsEntity ────────────────────────────────────────

export class EventWatcherParamsEntity {
  constructor(
    public readonly mode: 'specific_event' | 'search',
    public readonly watchTiers: string[] | 'all',
    public readonly externalId?: string,
    public readonly platform?: string,
    public readonly eventName?: string,
    public readonly query?: string,
    public readonly city?: string,
    public readonly country?: string,
    public readonly category?: string,
    public readonly eventDate?: string,
    public readonly isFree?: boolean
  ) {}

  /**
   * Serializes the entry for storage or API transmission.
   */
  serialize(): any {
    return {
      mode: this.mode,
      externalId: this.externalId,
      platform: this.platform,
      eventName: this.eventName,
      watchTiers: this.watchTiers,
      q: this.query,
      city: this.city,
      country: this.country,
      category: this.category,
      eventDate: this.eventDate,
      isFree: this.isFree
    };
  }

  /**
   * Creates an entity from a plain object.
   */
  static fromJson(json: any): EventWatcherParamsEntity {
    return new EventWatcherParamsEntity(
      json.mode,
      json.watchTiers || 'all',
      json.externalId,
      json.platform,
      json.eventName,
      json.q || json.query,
      json.city,
      json.country,
      json.category,
      json.eventDate,
      json.isFree
    );
  }
}
