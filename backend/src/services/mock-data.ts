
import { v4 as uuidv4 } from 'uuid';

const AIRLINES = ["Stellar Airways", "Lumen Wings", "Galactic Express", "Horizon Air", "Nebula Jets"];
const AIRPORTS: Record<string, string> = {
    "NYC": "John F. Kennedy Intl",
    "LON": "Heathrow Airport",
    "TYO": "Narita Intl",
    "PAR": "Charles de Gaulle",
    "SIN": "Changi Airport",
    "BER": "Berlin Brandenburg"
};

const flightPriceState: Record<string, number[]> = {};

export function getFlightPrice(origin: string, destination: string) {
    const routeKey = `${origin}-${destination}`;
    if (!flightPriceState[routeKey]) {
        flightPriceState[routeKey] = [Math.floor(400 + Math.random() * 600)];
    }

    const history = flightPriceState[routeKey];
    const lastPrice = history[history.length - 1];
    const isErrorFare = Math.random() < 0.25;
    let price = isErrorFare ? Math.round(lastPrice * 0.35) : Math.round(lastPrice + (Math.random() * 60 - 30));

    price = Math.max(150, price);
    history.push(price);
    if (history.length > 5) history.shift();

    const today = new Date();
    const dep = new Date(today.getTime() + 14 * 24 * 60 * 60 * 1000);
    const ret = new Date(dep.getTime() + 7 * 24 * 60 * 60 * 1000);

    return {
        origin: origin.toUpperCase(),
        origin_full: AIRPORTS[origin.toUpperCase()] || "International Airport",
        destination: destination.toUpperCase(),
        destination_full: AIRPORTS[destination.toUpperCase()] || "International Airport",
        cheapest_price: price,
        currency: "USD",
        airline: AIRLINES[Math.floor(Math.random() * AIRLINES.length)],
        flight_number: `FL-${Math.floor(1000 + Math.random() * 9000)}`,
        departure_date: dep.toISOString().split('T')[0],
        return_date: ret.toISOString().split('T')[0],
        itinerary: {
            stops: Math.random() > 0.7 ? 1 : 0,
            duration_minutes: 480 + Math.floor(Math.random() * 240),
            cabin_class: "Economy (Saver)",
            baggage: "1 Personal Item, 1 Carry-on included",
            amenities: ["Wi-Fi available", "In-seat power", "Meal included"]
        },
        price_history: [...history],
        is_error_fare: isErrorFare,
        is_historical_low: price < 350,
        deal_rating: price < 400 ? "Excellent" : "Fair",
        checked_at: new Date().toISOString()
    };
}

const CRYPTO_METADATA: Record<string, any> = {
    XLM: { name: "Stellar", foundation: "SDF", consensus: "SCP" },
    ETH: { name: "Ethereum", foundation: "Ethereum Foundation", consensus: "PoS" },
    BTC: { name: "Bitcoin", foundation: "Open Source", consensus: "PoW" },
    SOL: { name: "Solana", foundation: "Solana Labs", consensus: "PoH" },
    USDC: { name: "USD Coin", foundation: "Circle", consensus: "Fiat-Backed" }
};

const cryptoPriceHistory: Record<string, number[]> = {};

export function getCryptoData() {
    const symbols = Object.keys(CRYPTO_METADATA);
    const data: Record<string, any> = {};

    symbols.forEach(symbol => {
        if (!cryptoPriceHistory[symbol]) cryptoPriceHistory[symbol] = [100];
        const history = cryptoPriceHistory[symbol];
        const last = history[history.length - 1];
        const change = (Math.random() * 0.06 - 0.03);
        const newPrice = last * (1 + change);
        history.push(newPrice);
        if (history.length > 20) history.shift();

        data[symbol] = {
            ...CRYPTO_METADATA[symbol],
            price: symbol === 'XLM' ? 0.14 + (Math.random() * 0.02) : (symbol === 'BTC' ? 69000 + Math.random() * 1000 : 3400 + Math.random() * 100),
            change_24h: Math.round(change * 10000) / 100,
            market_cap: symbol === 'BTC' ? "1.4T" : (symbol === 'XLM' ? "4.2B" : "400B"),
            volume_24h_usdc: symbol === 'XLM' ? "120M" : "45B",
            rsi_14: 45 + Math.floor(Math.random() * 20),
            sentiment: Math.random() > 0.6 ? "Bullish" : "Neutral",
            signals: ["Strong Support at EMA-20", "Increased Whale Activity"]
        };
    });

    return {
        assets: data,
        volumes: { XLM: 3.1, BTC: 1.2, ETH: 0.9 },
        global_market_cap: "2.64T",
        dominance: { BTC: "52.1%", ETH: "16.8%" },
        checked_at: new Date().toISOString()
    };
}

const NEWS_SOURCES = ["Stellar Hub", "CryptoDaily", "The Block", "ChainWire", "Protocol Insider"];

export function getNewsAlerts() {
    const topics = [
        { t: "Stellar Protocol 21", d: "A major upgrade to the Stellar network introducing advanced smart contract capabilities via Soroban." },
        { t: "USDC Integration", d: "Global payment processor announces native USDC support on 3 new blockchain networks." },
        { t: "Soroban Mainnet Growth", d: "Developer activity on Soroban spikes 400% following the release of the new SDK." },
        { t: "Meridien 2024", d: "Annual Stellar conference announces keynote speakers from IMF and World Bank." },
        { t: "DeFi on Stellar", d: "New automated market maker (AMM) protocol launches with $50M in initial liquidity." }
    ];

    return {
        articles: topics.map(topic => ({
            id: uuidv4(),
            title: `Breaking: ${topic.t} Revealed`,
            summary: topic.d,
            content: `${topic.d} Industry experts believe this will have a profound impact on the future of cross-border payments and programmable finance. The upgrade period is expected to conclude by EOD.`,
            source: NEWS_SOURCES[Math.floor(Math.random() * NEWS_SOURCES.length)],
            author: "Flare Intelligence Agent",
            relevance_score: 0.88 + Math.random() * 0.1,
            tags: ["Stellar", "Finance", "Tech"],
            url: "https://flare.intelligence/news/view",
            timestamp: new Date().toISOString()
        })),
        trending_score: 94,
        market_impact: "High",
        checked_at: new Date().toISOString()
    };
}

export function getJobPostings(role: string) {
    const titles = ["Senior Engineer", "Lead Architect", "Protocol Dev", "Systems Designer"];
    const companies = ["Stellar Foundation", "Circle", "Anchorage Digital", "MoneyGram", "WalletConnect"];

    return {
        role_queried: role,
        listings: titles.map((t, i) => {
            const isHot = Math.random() < 0.45;
            const salary = 145000 + Math.floor(Math.random() * 80000);
            return {
                id: uuidv4(),
                title: `${t} (${role})`,
                company: companies[i % companies.length],
                location: "Remote / Global",
                salary_range: `$${salary.toLocaleString()} - $${(salary + 40000).toLocaleString()}`,
                salary: salary,
                is_hot: isHot,
                experience_level: "Senior",
                employment_type: "Full-time",
                description: `We are looking for a highly skilled ${t} to join our core team. You will be responsible for designing and implementing high-throughput systems that power the future of digital assets.`,
                requirements: ["5+ years of experience", "Proficiency in Rust or Go", "Cloud infrastructure knowledge"],
                benefits: ["Competitive Equity", "Unlimited PTO", "Health/Dental/Vision"],
                posted_at: "2 hours ago"
            };
        }),
        market_demand: "Very High",
        checked_at: new Date().toISOString()
    };
}

export function getProductPrices(name: string) {
    const isATH = Math.random() < 0.45;
    const basePrice = 1299;
    const currentPrice = isATH ? 849 : basePrice + Math.floor(Math.random() * 200);

    return {
        product_name: name || "MacBook Pro M3",
        brand: "Apple",
        model_year: "2024",
        current_price: currentPrice,
        currency: "USD",
        discount_percent: Math.round((1 - currentPrice/basePrice) * 100),
        on_sale: isATH,
        is_ath: isATH,
        rating: { score: 4.8, count: 1240 },
        specs: { cpu: "M3 Max", ram: "32GB", storage: "1TB SSD" },
        stores: [
            { name: "TechMart", price: currentPrice, stock: "In Stock", delivery: "Tomorrow" },
            { name: "CloudRetail", price: currentPrice + 40, stock: "2 Left", delivery: "2-3 Days" },
            { name: "SuperStore", price: currentPrice + 110, stock: "In Stock", delivery: "Today" }
        ],
        price_trend: isATH ? "Falling" : "Stable",
        checked_at: new Date().toISOString()
    };
}

export function getStockData(symbol?: string) {
    const target = symbol?.toUpperCase() || "XLM";
    const price = 45.12 + Math.random() * 100;
    const change = (Math.random() * 14 - 7);
    const isVolatile = Math.abs(change) > 5;

    return {
        ticker: target,
        price: Math.round(price * 100) / 100,
        change_percent: Math.round(change * 100) / 100,
        volume: "14.5M",
        market_cap: "850B",
        pe_ratio: "28.4",
        dividend_yield: "1.2%",
        analyst_rating: change > 3 ? "Strong Buy" : (change < -3 ? "Hold" : "Buy"),
        event: isVolatile ? (change > 0 ? "Bullish Breakout" : "Support Breach") : null,
        stocks: [
            { symbol: target, price: Math.round(price * 100) / 100, change_percent: Math.round(change * 100) / 100, event: isVolatile ? "Volatile Action" : null },
            { symbol: "AMZN", price: 178.45, change_percent: 0.45 },
            { symbol: "NVDA", price: 920.10, change_percent: 2.15 }
        ],
        checked_at: new Date().toISOString()
    };
}

export function getRealEstateData(neighborhood?: string) {
    const nb = neighborhood || "Lower East Side";
    const isNew = Math.random() < 0.55;
    const price = 1200000 + Math.floor(Math.random() * 500000);

    return {
        neighborhood: nb,
        city: "New York",
        safety_score: 82,
        school_score: 9,
        walk_score: 98,
        stats: {
            median_price: 1450000,
            trend: "Rising",
            inventory_count: 58,
            avg_days_on_market: 22
        },
        listings: [
            {
                id: uuidv4(),
                address: "452 Orchard St, Apt 4B",
                price: price,
                type: "Condominium",
                is_new: isNew,
                price_reduced: !isNew && Math.random() < 0.4,
                beds: 2,
                baths: 2,
                sqft: 1250,
                price_per_sqft: Math.round(price / 1250),
                amenities: ["Rooftop Deck", "Gym", "Doorman", "Pet Friendly"],
                agent: { name: "Sarah Smith", rating: 4.9 }
            }
        ],
        checked_at: new Date().toISOString()
    };
}

export function getSportsData(team?: string) {
    const t = team || "Golden State Warriors";
    const isDrop = Math.random() < 0.65;
    const basePrice = 185;
    const currentPrice = isDrop ? 85 : basePrice;

    return {
        match: {
            home: t,
            away: "LA Lakers",
            venue: "Chase Center",
            date: "Thursday, Nov 14",
            time: "7:00 PM PST",
            broadcast: "TNT",
            weather: "Clear, 64°F"
        },
        team_stats: { win_streak: 4, rank_conf: 3 },
        tickets: [
            {
                section: "Lower Bowl, Row 12",
                price: currentPrice,
                currency: "USD",
                price_dropped: isDrop,
                drop_amount: basePrice - currentPrice,
                history: [basePrice, 175, 160, currentPrice],
                availability: "Only 4 Left",
                seller: "Verified Official Resale"
            }
        ],
        checked_at: new Date().toISOString()
    };
}
