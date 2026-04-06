import { v4 as uuidv4 } from 'uuid';

export interface Listing {
  id: string;
  address: string;
  neighborhood: string;
  city: string;
  type: 'apartment' | 'house' | 'condo';
  bedrooms: number;
  bathrooms: number;
  sqft: number;
  rent?: number;
  price?: number;
  amenities: string[];
  listing_date: string;
  days_on_market: number;
  is_new: boolean;
  price_reduced: boolean;
  reduction_percent?: number;
}

const CITIES = {
  "Austin": ["Downtown", "East Side", "Zilker", "Domain"],
  "San Francisco": ["SoMa", "Mission", "Marina", "Nob Hill"],
  "New York": ["Brooklyn Heights", "Upper East Side", "Williamsburg", "Astoria"],
  "Denver": ["Capitol Hill", "LoDo", "RiNo", "Cherry Creek"],
  "Miami": ["Brickell", "Wynwood", "South Beach", "Coral Gables"]
};

// Initial Pool (50+ listings)
const LISTING_POOL: Listing[] = [];
const PROPERTY_TYPES: any[] = ['apartment', 'house', 'condo'];
const AMENITIES = ['pet_friendly', 'parking', 'laundry', 'gym', 'pool', 'balcony'];

Object.entries(CITIES).forEach(([city, neighborhoods]) => {
  neighborhoods.forEach(nh => {
    // Generate 3 properties per neighborhood
    for (let i = 0; i < 3; i++) {
      const type = PROPERTY_TYPES[i % 3];
      const isRental = Math.random() > 0.4;
      const basePrice = isRental ? 1500 + Math.random() * 3000 : 400000 + Math.random() * 2000000;
      
      LISTING_POOL.push({
        id: uuidv4(),
        address: `${100 + i * 15} ${nh} St`,
        neighborhood: nh,
        city,
        type,
        bedrooms: 1 + Math.floor(Math.random() * 4),
        bathrooms: 1 + Math.floor(Math.random() * 3),
        sqft: 700 + Math.floor(Math.random() * 2000),
        rent: isRental ? Math.round(basePrice) : undefined,
        price: !isRental ? Math.round(basePrice) : undefined,
        amenities: AMENITIES.filter(() => Math.random() > 0.5),
        listing_date: new Date(Date.now() - (Math.random() * 30 * 86400000)).toISOString(),
        days_on_market: Math.floor(Math.random() * 30),
        is_new: Math.random() > 0.8,
        price_reduced: Math.random() > 0.85
      });
    }
  });
});

const startTime = Date.now();

export function getRealEstateData(params: {
  city?: string;
  neighborhood?: string;
  type?: string;
  bedrooms?: number;
  min_price?: number;
  max_price?: number;
  amenities?: string[];
  is_rental: boolean;
}): any {
  const { city, neighborhood, type, bedrooms, min_price, max_price, amenities, is_rental } = params;

  // Simulate rotation: 1 in 5 add new, 1 in 6 reduce price
  const hours = Math.floor((Date.now() - startTime) / 3600000);
  if (hours > 0 && Math.random() < 0.2) {
    const cityNames = Object.keys(CITIES);
    const randomCity = cityNames[Math.floor(Math.random() * cityNames.length)];
    const randomNH = (CITIES as any)[randomCity][0];
    LISTING_POOL.push({
      id: uuidv4(),
      address: `${Math.floor(Math.random() * 999)} New St`,
      neighborhood: randomNH,
      city: randomCity,
      type: 'apartment',
      bedrooms: 2,
      bathrooms: 2,
      sqft: 1100,
      rent: is_rental ? 2500 : undefined,
      price: !is_rental ? 550000 : undefined,
      amenities: ['parking', 'gym'],
      listing_date: new Date().toISOString(),
      days_on_market: 0,
      is_new: true,
      price_reduced: false
    });
  }

  // Filter
  let results = LISTING_POOL.filter(l => {
    if (is_rental && !l.rent) return false;
    if (!is_rental && !l.price) return false;
    if (city && l.city !== city) return false;
    if (neighborhood && l.neighborhood !== neighborhood) return false;
    if (type && l.type !== type) return false;
    if (bedrooms && l.bedrooms < bedrooms) return false;
    
    const price = is_rental ? l.rent! : l.price!;
    if (min_price && price < min_price) return false;
    if (max_price && price > max_price) return false;
    
    if (amenities && amenities.length > 0) {
      if (!amenities.every(a => l.amenities.includes(a))) return false;
    }
    return true;
  });

  const enriched = results.map(l => {
    const price = is_rental ? l.rent! : l.price!;
    return {
      ...l,
      price_per_sqft: !is_rental ? Math.round(price / l.sqft) : undefined
    };
  }).sort((a, b) => new Date(b.listing_date).getTime() - new Date(a.listing_date).getTime());

  return {
    listings: enriched,
    total_matches: enriched.length,
    new_since_last_check: enriched.filter(l => l.is_new).length,
    price_reduced_count: enriched.filter(l => l.price_reduced).length,
    market_insight: enriched.length > 0 ? `Market in ${city || 'selected areas'} is showing ${enriched.filter(l => l.price_reduced).length > 2 ? 'increased' : 'stable'} supply.` : "No matches found.",
    checked_at: new Date().toISOString()
  };
}

export function getInvestmentAnalysis(city: string, neighborhood?: string): any {
  const filtered = LISTING_POOL.filter(l => l.city === city && (!neighborhood || l.neighborhood === neighborhood));
  if (filtered.length === 0) return { error: "No data for this location" };

  const rentals = filtered.filter(l => l.rent);
  const avgRent = rentals.reduce((acc, l) => acc + l.rent!, 0) / (rentals.length || 1);
  const avgDOM = filtered.reduce((acc, l) => acc + l.days_on_market, 0) / filtered.length;

  return {
    location: { city, neighborhood },
    average_rent: Math.round(avgRent),
    average_days_on_market: Math.round(avgDOM),
    price_trend: Math.random() > 0.5 ? 'up' : 'down',
    insight: `Average rent in ${neighborhood || city} is $${Math.round(avgRent).toLocaleString()}, ${Math.random() > 0.5 ? 'up' : 'down'} 3% from last month.`,
    checked_at: new Date().toISOString()
  };
}
