import { v4 as uuidv4 } from 'uuid';

// --- Global State ---
const state: any = {
    flights: {},
    crypto: {},
    products: {},
    jobs: [],
    stocks: {},
    realestate: [],
    sports: { tickets: [], scores: [] }
};

const startTime = Date.now();

// --- 1. Flight Data (Enhanced) ---
const AIRLINES = ["ANA", "Stellar Airways", "Lumen Wings", "Galactic Express", "Horizon Air", "JAL", "Delta", "United", "Emirates"];
const CABINS = ["economy", "premium_economy", "business", "first"];

export function getFlightPrice(origin: string, destination: string, filters: any = {}) {
    const routeKey = `${origin}-${destination}`;
    if (!state.flights[routeKey]) {
        state.flights[routeKey] = [Math.floor(400 + Math.random() * 600)];
    }

    const history = state.flights[routeKey];
    const lastPrice = history[history.length - 1];
    
    // Simulate error fare (1 in 20)
    let isErrorFare = Math.random() < 0.05;
    let price = isErrorFare ? lastPrice * 0.35 : lastPrice * (1 + (Math.random() * 0.1 - 0.05));
    price = Math.round(price);

    history.push(price);
    if (history.length > 10) history.shift();

    const isATH = price <= Math.min(...history);

    return {
        origin,
        destination,
        cheapest_price: price,
        airline: AIRLINES[Math.floor(Math.random() * AIRLINES.length)],
        cabin_class: filters.cabin || "economy",
        is_error_fare: isErrorFare,
        is_historical_low: isATH,
        price_history: [...history],
        checked_at: new Date().toISOString()
    };
}

// --- 2. Crypto Data (Enhanced) ---
const CRYPTO_CONFIG: any = {
    BTC: { base: 68000, vol: 0.03 }, XLM: { base: 0.14, vol: 0.05 }, ETH: { base: 3200, vol: 0.04 }, SOL: { base: 145, vol: 0.06 }
};

export function getCryptoData(symbols: string[] = ['BTC', 'ETH', 'XLM', 'SOL']) {
    const prices: any = {};
    const changes: any = {};

    symbols.forEach(s => {
        const conf = CRYPTO_CONFIG[s] || { base: 100, vol: 0.05 };
        if (!state.crypto[s]) state.crypto[s] = [conf.base];
        const hist = state.crypto[s];
        const last = hist[hist.length - 1];
        const next = last * (1 + (Math.random() * conf.vol * 2 - conf.vol));
        hist.push(next);
        if (hist.length > 20) hist.shift();
        prices[s] = parseFloat(next.toFixed(s === 'XLM' ? 4 : 2));
        changes[s] = parseFloat(((next - hist[0]) / hist[0] * 100).toFixed(2));
    });

    return { prices, changes_24h: changes, volumes: symbols.reduce((a,s)=>({...a,[s]:Math.random()*3}), {}), checked_at: new Date().toISOString() };
}

// --- 3. News Data (Enhanced) ---
export function getNewsAlerts(topic: string = 'Stellar') {
    return {
        articles: [
            { id: uuidv4(), title: `${topic} Network adoption spikes`, source: "TechDaily", sentiment_score: 0.8, sentiment_label: 'positive', relevance_score: 0.95 },
            { id: uuidv4(), title: `Market analysis: ${topic} potential`, source: "FinanceTimes", sentiment_score: 0.2, sentiment_label: 'neutral', relevance_score: 0.88 }
        ],
        trending_score: 85,
        checked_at: new Date().toISOString()
    };
}

// --- 4. Product Data (Enhanced) ---
export function getProductPrices(query: string) {
    const base = 299;
    if (!state.products[query]) state.products[query] = [base];
    const hist = state.products[query];
    const last = hist[hist.length-1];
    const price = last * (1 + (Math.random()*0.1-0.05));
    hist.push(price);
    
    return {
        product_name: query,
        current_price: parseFloat(price.toFixed(2)),
        stores: [
            { store: "Amazon", price: parseFloat(price.toFixed(2)), in_stock: true },
            { store: "Best Buy", price: parseFloat((price * 0.95).toFixed(2)), in_stock: true }
        ],
        is_ath: price <= Math.min(...hist),
        on_sale: Math.random() > 0.8,
        checked_at: new Date().toISOString()
    };
}

// --- 5. Job Data (Enhanced) ---
export function getJobPostings(role: string) {
    return {
        listings: [
            { id: uuidv4(), title: `Senior ${role}`, company: "Stellar Dev", salary: 165000, is_hot: true, posted_at: new Date().toISOString() },
            { id: uuidv4(), title: `Staff ${role}`, company: "Galactic Labs", salary: 210000, is_hot: false, posted_at: new Date().toISOString() }
        ],
        salary_trends: { p50: 160000, p90: 220000, trend: 'up' },
        checked_at: new Date().toISOString()
    };
}

// --- 6. Stock Data (New) ---
const STOCK_CONFIG: any = {
    AAPL: 185, TSLA: 171, NVDA: 890, MSFT: 420
};

export function getStockData(symbols: string[] = ['AAPL', 'TSLA', 'NVDA']) {
    const stocks = symbols.map(s => {
        const base = STOCK_CONFIG[s] || 100;
        if (!state.stocks[s]) state.stocks[s] = [base];
        const hist = state.stocks[s];
        const next = hist[hist.length-1] * (1 + (Math.random()*0.02-0.01));
        hist.push(next);
        return {
            symbol: s,
            price: parseFloat(next.toFixed(2)),
            change_percent: parseFloat(((next - hist[0])/hist[0]*100).toFixed(2)),
            high_52w: base * 1.2,
            low_52w: base * 0.8,
            event: Math.random() > 0.9 ? "Analyst Upgrade" : undefined
        };
    });
    return { stocks, checked_at: new Date().toISOString() };
}

// --- 7. Real Estate Data (New) ---
export function getRealEstateData(city: string = 'Austin') {
    return {
        listings: [
            { id: uuidv4(), address: "123 Solar St", city, neighborhood: "Downtown", type: "condo", price: 550000, is_new: true, listing_date: new Date().toISOString() },
            { id: uuidv4(), address: "456 Stellar Ave", city, neighborhood: "East Side", type: "house", price: 820000, price_reduced: true, listing_date: new Date().toISOString() }
        ],
        stats: { avg_rent: 2100, trend: 'down' },
        checked_at: new Date().toISOString()
    };
}

// --- 8. Sports Data (New) ---
export function getSportsData(team: string = 'Warriors') {
    return {
        match: { home: team, away: "Lakers", score: "102-98", time: "Final", odds: { home: 1.8, away: 2.1 } },
        tickets: [
            { section: "Floor", price: 450, history: [500, 480, 450], price_dropped: true },
            { section: "Lower Bowl", price: 220, history: [220, 220, 220], price_dropped: false }
        ],
        checked_at: new Date().toISOString()
    };
}
