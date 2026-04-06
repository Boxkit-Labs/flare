import { v4 as uuidv4 } from 'uuid';

interface FlightResult {
  id: string;
  airline: string;
  price: number;
  cabin: string;
  stops: number;
  duration: string; // e.g., "14h 20m"
  departure_date: string;
  return_date?: string;
  is_direct: boolean;
  booking_url: string;
}

interface FlightDataResponse {
  results: FlightResult[];
  origin: string | string[];
  destination: string | string[];
  is_error_fare: boolean;
  is_historical_low: boolean;
  checked_at: string;
}

const AIRLINES = [
  { name: "United", tier: "premium", multiplier: 1.0 },
  { name: "Delta", tier: "premium", multiplier: 1.05 },
  { name: "Air France", tier: "premium", multiplier: 1.1 },
  { name: "Lufthansa", tier: "premium", multiplier: 1.15 },
  { name: "British Airways", tier: "premium", multiplier: 1.2 },
  { name: "ANA", tier: "premium", multiplier: 1.3 },
  { name: "JAL", tier: "premium", multiplier: 1.3 },
  { name: "Emirates", tier: "luxury", multiplier: 1.5 },
  { name: "Singapore Airlines", tier: "luxury", multiplier: 1.6 },
  { name: "Qatar Airways", tier: "luxury", multiplier: 1.55 },
  { name: "Southwest", tier: "budget", multiplier: 0.7 },
  { name: "JetBlue", tier: "budget", multiplier: 0.8 },
  { name: "Ryanair", tier: "budget", multiplier: 0.5 },
];

const CABIN_MULTIPLIERS: Record<string, number> = {
  economy: 1.0,
  premium_economy: 1.6,
  business: 4.5,
  first: 9.0,
};

// In-memory state
const historicalLows: Record<string, number> = {};

export function getFlightResults(params: {
  origin: string | string[];
  destination: string | string[];
  cabin?: string;
  direct_only?: boolean;
  trip_type?: 'one_way' | 'round_trip';
  date_range?: { start: string; end: string };
  preferred_airlines?: string[];
}): FlightDataResponse {
  const { origin, destination, cabin = 'any', direct_only = false, trip_type = 'round_trip', preferred_airlines } = params;
  
  const results: FlightResult[] = [];
  const routeKey = `${Array.isArray(origin) ? origin.join(',') : origin}-${Array.isArray(destination) ? destination.join(',') : destination}`;
  
  let isErrorFare = false;
  let isHistoricalLow = false;

  // 1 in 4 chance for a dramatic drop (Demo purposes)
  const isDemoDrop = Math.random() < 0.25;

  // Generate results for multiple combinations
  const origins = Array.isArray(origin) ? origin : [origin];
  const destinations = Array.isArray(destination) ? destination : [destination];

  origins.forEach(org => {
     destinations.forEach(dest => {
        // Generate possible airlines
        const list = preferred_airlines && preferred_airlines.length > 0 
           ? AIRLINES.filter(a => preferred_airlines.includes(a.name))
           : AIRLINES;

        list.forEach(airline => {
           // Base price calculation
           let basePrice = 500 + (Math.random() * 1000); // $500 - $1500
           basePrice *= airline.multiplier;

           // Apply Demo logic
           if (isDemoDrop && results.length === 0) {
              const dropPercent = 0.6 + (Math.random() * 0.2); // 60-80% drop
              basePrice *= (1 - dropPercent);
              isErrorFare = dropPercent >= 0.6;
           }

           // Cabin filtering
           const cabinsToGen = cabin === 'any' ? ['economy', 'business'] : [cabin];
           
           cabinsToGen.forEach(c => {
              const finalPrice = Math.round(basePrice * (CABIN_MULTIPLIERS[c] || 1));
              const stops = direct_only ? 0 : (Math.random() > 0.7 ? 1 : 0);
              
              const today = new Date();
              const depDate = new Date(today.getTime() + (Math.random() * 30 * 24 * 60 * 60 * 1000));
              
              results.push({
                 id: uuidv4(),
                 airline: airline.name,
                 price: finalPrice,
                 cabin: c,
                 stops: stops,
                 duration: `${Math.floor(Math.random() * 12 + 2)}h ${Math.floor(Math.random() * 60)}m`,
                 departure_date: depDate.toISOString().split('T')[0],
                 return_date: trip_type === 'round_trip' 
                    ? new Date(depDate.getTime() + (7 * 24 * 60 * 60 * 1000)).toISOString().split('T')[0] 
                    : undefined,
                 is_direct: stops === 0,
                 booking_url: `https://flare-flights.ai/book/${uuidv4()}`
              });

              // Historical low check
              const lowKey = `${org}-${dest}-${c}`;
              if (!historicalLows[lowKey] || finalPrice < historicalLows[lowKey]) {
                 if (historicalLows[lowKey]) isHistoricalLow = true; // Flag if we broke a record
                 historicalLows[lowKey] = finalPrice;
              }
           });
        });
     });
  });

  // Sort and pick top results
  const sorted = results.sort((a, b) => a.price - b.price).slice(0, 10);

  return {
    results: sorted,
    origin,
    destination,
    is_error_fare: isErrorFare,
    is_historical_low: isHistoricalLow,
    checked_at: new Date().toISOString()
  };
}
