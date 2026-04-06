import { v4 as uuidv4 } from 'uuid';

export interface EventTicket {
  id: string;
  name: string;
  venue: string;
  city: string;
  date: string;
  category: 'concert' | 'sports' | 'theater' | 'festival';
  tiers: Array<{
    name: string;
    price: number;
    inventory: number;
    history: number[];
  }>;
}

export interface SportMatch {
  id: string;
  sport: string;
  home_team: string;
  away_team: string;
  score: string;
  time: string;
  key_events: string[];
  odds: { home: number; draw?: number; away: number };
  injuries: string[];
}

const EVENTS: EventTicket[] = [
  { id: 'e1', name: 'Taylor Swift: Eras Tour', venue: 'SoFi Stadium', city: 'Los Angeles', date: '2026-08-15', category: 'concert', tiers: [] },
  { id: 'e2', name: 'NBA Finals: Game 7', venue: 'TD Garden', city: 'Boston', date: '2026-06-20', category: 'sports', tiers: [] },
  { id: 'e3', name: 'Coachella: Weekend 1', venue: 'Empire Polo Club', city: 'Indio', date: '2027-04-12', category: 'festival', tiers: [] },
  { id: 'e4', name: 'Super Bowl LXI', venue: 'Levi\'s Stadium', city: 'Santa Clara', date: '2027-02-08', category: 'sports', tiers: [] },
  { id: 'e5', name: 'Hamilton', venue: 'Richard Rodgers Theatre', city: 'New York', date: '2026-05-10', category: 'theater', tiers: [] },
  // ... more added in rotation
];

const TEAMS = [
  { name: 'Lakers', sport: 'Basketball' }, { name: 'Warriors', sport: 'Basketball' },
  { name: 'Man City', sport: 'Soccer' }, { name: 'Real Madrid', sport: 'Soccer' },
  { name: 'KC Chiefs', sport: 'Football' }, { name: 'SF 49ers', sport: 'Football' }
];

const RESTAURANTS = ["Nobu", "Carbone", "Polo Bar", "Franklin BBQ", "French Laundry"];

// Initialize Tiers
EVENTS.forEach(e => {
  const base = e.category === 'concert' ? 800 : (e.category === 'sports' ? 1200 : 300);
  e.tiers = [
    { name: 'Floor', price: base * 2, inventory: 50, history: [base * 1.8] },
    { name: 'Lower Bowl', price: base * 1.2, inventory: 150, history: [base * 1.1] },
    { name: 'Upper Bowl', price: base * 0.6, inventory: 300, history: [base * 0.5] },
    { name: 'GA', price: base * 0.4, inventory: 500, history: [base * 0.35] }
  ];
});

const startTime = Date.now();

export function getTicketData(query?: string): any {
  // Simulate price fluctuations
  EVENTS.forEach(e => {
    e.tiers.forEach(t => {
      const daysToEvent = (new Date(e.date).getTime() - Date.now()) / 86400000;
      const growth = (30 / Math.max(1, daysToEvent)) * 0.05; // Prices rise as date nears
      
      let price = t.price * (1 + growth + (Math.random() * 0.02 - 0.01));
      
      // Seller dump: 1 in 10 chance per tier
      if (Math.random() < 0.1) {
        price *= 0.75; // 25% drop
      }

      t.history.push(t.price);
      if (t.history.length > 10) t.history.shift();
      t.price = Math.round(price);
    });
  });

  const results = query ? EVENTS.filter(e => e.name.toLowerCase().includes(query.toLowerCase())) : EVENTS;
  return { events: results, checked_at: new Date().toISOString() };
}

export function getSportsData(): any {
  const matches = TEAMS.slice(0, 3).map((team, i) => {
    const opponent = TEAMS[TEAMS.length - 1 - i];
    const homeScore = Math.floor(Math.random() * 4);
    const awayScore = Math.floor(Math.random() * 4);
    
    return {
      id: uuidv4(),
      sport: team.sport,
      home_team: team.name,
      away_team: opponent.name,
      score: `${homeScore}-${awayScore}`,
      time: 'Live 65\'',
      key_events: [`${team.name} Goal (52')`, `Yellow Card: ${opponent.name} (12')`],
      odds: { home: 1.8 + Math.random(), away: 2.1 + Math.random() },
      injuries: Math.random() > 0.8 ? [`${team.name} Star Player: Out`] : []
    };
  });

  return { matches, checked_at: new Date().toISOString() };
}

export function getDiscoveryData(): any {
  const reservations = RESTAURANTS.map(name => ({
    name,
    availability: Math.random() > 0.7 ? "Available at 8:00 PM" : "Sold Out",
    city: "New York/LA/Austin"
  }));

  const announcements = [
    { title: "Drake: It's All A Blur Tour - Added Dates", date: "announced today" },
    { title: "World Cup 2026: Final Venue Confirmed", date: "announced today" }
  ];

  return { reservations, announcements, checked_at: new Date().toISOString() };
}
