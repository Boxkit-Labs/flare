// Consolidated Mock Data for Combined Services

// --- Flight Data ---

const AIRLINES = ["Stellar Airways", "Lumen Wings", "Galactic Express", "Horizon Air"];

const flightPriceState: Record<string, number[]> = {};

export function getFlightPrice(origin: string, destination: string) {
    const routeKey = `${origin}-${destination}`;
    if (!flightPriceState[routeKey]) {
        flightPriceState[routeKey] = [Math.floor(400 + Math.random() * 600)];
    }

    const history = flightPriceState[routeKey];
    const lastPrice = history[history.length - 1];
    
    // Add volatility
    const volatility = (Math.random() * 40) - 20; // -20 to +20
    let price = Math.max(200, Math.min(1500, lastPrice + volatility));
    
    // 1 in 10 chance of price drop
    if (Math.random() < 0.1) {
        price = price * 0.75;
    }

    price = Math.round(price);
    history.push(price);
    if (history.length > 5) history.shift();

    const today = new Date();
    const dep = new Date(today.getTime() + 7 * 24 * 60 * 60 * 1000);
    const ret = new Date(dep.getTime() + 5 * 24 * 60 * 60 * 1000);

    return {
        origin,
        destination,
        cheapest_price: price,
        airline: AIRLINES[Math.floor(Math.random() * AIRLINES.length)],
        departure_date: dep.toISOString().split('T')[0],
        return_date: ret.toISOString().split('T')[0],
        price_history: [...history],
        checked_at: new Date().toISOString()
    };
}

// --- Crypto Data ---

const CRYPTO_BASE_PRICES: Record<string, number> = {
    XLM: 0.14, ETH: 3200, BTC: 68000, SOL: 145, USDT: 1.00, XRP: 0.52
};

const cryptoPriceHistory: Record<string, number[]> = {};

export function getCryptoData() {
    const symbols = Object.keys(CRYPTO_BASE_PRICES);
    const prices: Record<string, number> = {};
    const changes_24h: Record<string, number> = {};
    
    symbols.forEach(symbol => {
        if (!cryptoPriceHistory[symbol]) cryptoPriceHistory[symbol] = [CRYPTO_BASE_PRICES[symbol]];
        const history = cryptoPriceHistory[symbol];
        const lastPrice = history[history.length - 1];
        
        const variation = (Math.random() * 0.04) - 0.02; // -2% to +2%
        let newPrice = lastPrice * (1 + variation);
        
        prices[symbol] = symbol === 'BTC' || symbol === 'ETH' ? Math.round(newPrice * 100) / 100 : Math.round(newPrice * 10000) / 10000;
        history.push(prices[symbol]);
        if (history.length > 10) history.shift();
        
        changes_24h[symbol] = Math.round(((prices[symbol] - history[0]) / history[0]) * 10000) / 100;
    });

    return {
        prices,
        changes_24h,
        checked_at: new Date().toISOString()
    };
}

// --- News Data ---

const NEWS_TOPICS = ["Stellar Protocol 21", "Soroban Adoption", "USDC Yields", "Meridian Conference", "Smart Contract Security"];

export function getNewsAlerts() {
    return {
        alerts: NEWS_TOPICS.map(topic => ({
            title: `${topic} Update`,
            impact: Math.random() > 0.5 ? "high" : "medium",
            summary: `Significant developments in ${topic} reported today.`,
            timestamp: new Date().toISOString()
        })).slice(0, 3)
    };
}

// --- Job Data ---

const JOB_TITLES = ["Smart Contract Engineer", "Rust Developer", "Stellar Architect", "Protocol Researcher"];

export function getJobPostings(role: string) {
    return {
        role,
        postings: JOB_TITLES.map(title => ({
            title: `${title} - ${role}`,
            company: "Stellar Ecosystem Org",
            salary: `$${Math.floor(120 + Math.random() * 80)}k`,
            location: "Remote",
            posted_at: "Today"
        }))
    };
}

// --- Product Data ---

const PRODUCTS = ["MacBook Pro M3", "iPhone 15 Pro", "Sony WH-1000XM5", "iPad Air"];

export function getProductPrices(name: string) {
    return {
        product_name: name,
        current_price: 199 + Math.floor(Math.random() * 1000),
        store: "E-Shop",
        on_sale: Math.random() > 0.8,
        checked_at: new Date().toISOString()
    };
}
