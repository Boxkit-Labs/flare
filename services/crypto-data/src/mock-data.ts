interface CryptoData {
  prices: Record<string, number>;
  changes_24h: Record<string, number>;
  volumes: Record<string, string>;
  spike_detected: boolean;
  spike_coin: string | null;
  checked_at: string;
}

const BASE_PRICES: Record<string, number> = {
  XLM: 0.14,
  ETH: 3200,
  BTC: 68000,
  SOL: 145,
  USDT: 1.00,
  XRP: 0.52
};

const VOLATILITY: Record<string, number> = {
  XLM: 0.03,
  XRP: 0.03,
  ETH: 0.05,
  SOL: 0.05,
  BTC: 0.04,
  USDT: 0.001
};

const VOLUMES: Record<string, string> = {
  BTC: "high",
  ETH: "high",
  SOL: "high",
  XLM: "medium",
  XRP: "medium",
  USDT: "extremely high"
};

// In-memory history: last 10 prices per symbol
const priceHistory: Record<string, number[]> = {};

// Initialize history if empty
Object.keys(BASE_PRICES).forEach(symbol => {
  if (!priceHistory[symbol]) {
    priceHistory[symbol] = [BASE_PRICES[symbol]];
  }
});

export function getCryptoData(): CryptoData {
  const symbols = Object.keys(BASE_PRICES);
  const prices: Record<string, number> = {};
  const changes_24h: Record<string, number> = {};
  
  let spikeDetected = false;
  let spikeCoin: string | null = null;
  
  // 1 in 8 chance of a spike
  if (Math.random() < 0.125) {
    spikeDetected = true;
    spikeCoin = symbols[Math.floor(Math.random() * symbols.length)];
  }

  symbols.forEach(symbol => {
    const history = priceHistory[symbol];
    const lastPrice = history[history.length - 1];
    
    // Add volatility
    const vol = VOLATILITY[symbol];
    const variation = (Math.random() * 2 * vol) - vol; // -vol to +vol
    let newPrice = lastPrice * (1 + variation);
    
    // Add spike if detected for this coin
    if (spikeDetected && symbol === spikeCoin) {
      const spikeMove = 0.08 + (Math.random() * 0.07); // 8-15% jump
      newPrice = newPrice * (1 + spikeMove);
    }
    
    // Stablecoin floor/ceiling for USDT
    if (symbol === 'USDT') {
        newPrice = Math.max(0.999, Math.min(1.001, newPrice));
    }

    // Round for presentation (Sats for BTC/ETH, 4 decimals for others)
    prices[symbol] = symbol === 'BTC' || symbol === 'ETH' ? Math.round(newPrice * 100) / 100 : Math.round(newPrice * 10000) / 10000;
    
    // Update history
    history.push(prices[symbol]);
    if (history.length > 10) {
      history.shift();
    }
    
    // Calculate simulated 24h change based on first and last entry in the short history
    // Since we only have 10 checks, we'll amplify the move to look like 24h
    const firstInHistory = history[0];
    const percentChange = ((prices[symbol] - firstInHistory) / firstInHistory) * 100;
    changes_24h[symbol] = Math.round(percentChange * 100) / 100;
  });

  return {
    prices,
    changes_24h,
    volumes: VOLUMES,
    spike_detected: spikeDetected,
    spike_coin: spikeCoin,
    checked_at: new Date().toISOString()
  };
}
