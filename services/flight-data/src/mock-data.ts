import { v4 as uuidv4 } from 'uuid'; // Wait, I don't have uuid in package.json. I'll just use Math.random.

interface FlightPrice {
  price: number;
  checked_at: string;
}

interface FlightData {
  origin: string;
  destination: string;
  cheapest_price: number;
  airline: string;
  departure_date: string;
  return_date: string;
  price_history: number[];
  checked_at: string;
}

const BASE_PRICES: Record<string, number> = {
  "JFK-TYO": 1200,
  "JFK-LHR": 650,
  "LAX-CDG": 890,
  "SFO-SIN": 1100,
  "ORD-FCO": 780
};

const AIRLINES = ["United", "Delta", "ANA", "JAL", "BA", "Air France", "Lufthansa"];

// In-memory storage for realistic trends
const priceState: Record<string, number[]> = {};

export function getFlightPrice(origin: string, destination: string): FlightData {
  const routeKey = `${origin}-${destination}`;
  
  // 1. Get or generate base price
  let basePrice = BASE_PRICES[routeKey] || (Math.floor(Math.random() * (1500 - 400 + 1)) + 400);
  
  // 2. Trend from last price if exists
  const history = priceState[routeKey] || [];
  let currentBase = history.length > 0 ? history[history.length - 1] : basePrice;

  // 3. Add daily variation: ±15%
  const variation = (Math.random() * 0.3) - 0.15; // -0.15 to +0.15
  let price = currentBase * (1 + variation);

  // 4. Trigger price drop: 1 in 5 checks, 30-40% drop
  const isPriceDrop = Math.random() < 0.2;
  if (isPriceDrop) {
    const dropPercent = 0.3 + (Math.random() * 0.1); // 0.3 to 0.4
    price = price * (1 - dropPercent);
  }

  price = Math.round(price);

  // 5. Update history (keep last 5)
  history.push(price);
  if (history.length > 5) {
    history.shift();
  }
  priceState[routeKey] = history;

  // 6. Generate random dates (simulated)
  const today = new Date();
  const departureDate = new Date(today);
  departureDate.setDate(today.getDate() + Math.floor(Math.random() * 30) + 7); // 7-37 days from now
  
  const returnDate = new Date(departureDate);
  returnDate.setDate(departureDate.getDate() + Math.floor(Math.random() * 14) + 3); // 3-17 days from dep

  return {
    origin,
    destination,
    cheapest_price: price,
    airline: AIRLINES[Math.floor(Math.random() * AIRLINES.length)],
    departure_date: departureDate.toISOString().split('T')[0],
    return_date: returnDate.toISOString().split('T')[0],
    price_history: [...history],
    checked_at: new Date().toISOString()
  };
}
