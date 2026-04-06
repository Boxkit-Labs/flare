interface CryptoPrice {
  price: number;
  change_24h: number;
  change_7d: number;
  volume_24h: number;
  volume_category: 'normal' | 'high' | 'spike';
  is_ath: boolean;
  is_30d_low: boolean;
}

interface PortfolioResult {
  total_value_usd: number;
  total_change_24h_percent: number;
  positions: Array<{
    symbol: string;
    holdings: number;
    value_usd: number;
    gain_loss_24h: number;
    percent_change_24h: number;
  }>;
  best_performer: string;
  worst_performer: string;
}

interface PairResult {
  pair: string;
  ratio: number;
  trend: 'up' | 'down' | 'neutral';
  change_24h_percent: number;
}

interface MarketOverview {
  total_market_cap_usd: string;
  btc_dominance_percent: number;
  market_sentiment: 'bullish' | 'bearish' | 'uncertain';
  unusual_conditions: boolean;
  top_gainers: string[];
}

const ASSETS = [
  { s: 'BTC', p: 64000, v: 0.03, type: 'bluechip' },
  { s: 'ETH', p: 3450, v: 0.04, type: 'bluechip' },
  { s: 'SOL', p: 145, v: 0.07, type: 'high_vol' },
  { s: 'XLM', p: 0.11, v: 0.04, type: 'utility' },
  { s: 'XRP', p: 0.62, v: 0.05, type: 'utility' },
  { s: 'ADA', p: 0.45, v: 0.06, type: 'alt' },
  { s: 'DOT', p: 7.20, v: 0.07, type: 'alt' },
  { s: 'AVAX', p: 38.50, v: 0.08, type: 'alt' },
  { s: 'LINK', p: 18.20, v: 0.06, type: 'utility' },
  { s: 'MATIC', p: 0.72, v: 0.07, type: 'alt' },
  { s: 'DOGE', p: 0.16, v: 0.15, type: 'meme' },
  { s: 'SHIB', p: 0.000027, v: 0.20, type: 'meme' },
  { s: 'UNI', p: 7.80, v: 0.09, type: 'defi' },
  { s: 'AAVE', p: 88.00, v: 0.10, type: 'defi' },
  { s: 'ATOM', p: 8.50, v: 0.08, type: 'alt' }
];

// In-memory price state
const priceState: Record<string, number[]> = {};

function getCoinStats(symbol: string): CryptoPrice {
  const asset = ASSETS.find(a => a.s === symbol) || ASSETS[0];
  const history = priceState[symbol] || [asset.p];
  
  const lastPrice = history[history.length - 1];
  const variation = (Math.random() * 2 * asset.v) - asset.v;
  const newPrice = lastPrice * (1 + variation);
  
  history.push(newPrice);
  if (history.length > 30) history.shift();
  priceState[symbol] = history;

  const change24h = ((newPrice - history[Math.max(0, history.length - 2)]) / history[Math.max(0, history.length - 2)]) * 100;
  const change7d = ((newPrice - history[0]) / history[0]) * 100;
  
  const isSpike = Math.random() < 0.1;
  const volume = 1000000000 * (1 + Math.random());

  return {
    price: parseFloat(newPrice.toFixed(symbol.includes('SHIB') ? 8 : 2)),
    change_24h: parseFloat(change24h.toFixed(2)),
    change_7d: parseFloat(change7d.toFixed(2)),
    volume_24h: volume,
    volume_category: (isSpike ? 'spike' : (volume > 1500000000 ? 'high' : 'normal')) as 'normal' | 'high' | 'spike',
    is_ath: Math.random() < 0.05,
    is_30d_low: Math.random() < 0.05
  };
}

export function getPortfolioStats(holdings: Record<string, number>): PortfolioResult {
  let totalValue = 0;
  let totalPrevValue = 0;
  const positions = [];

  for (const [symbol, amount] of Object.entries(holdings)) {
    const stats = getCoinStats(symbol);
    const value = amount * stats.price;
    const prevValue = value / (1 + (stats.change_24h / 100));
    
    totalValue += value;
    totalPrevValue += prevValue;

    positions.push({
      symbol,
      holdings: amount,
      value_usd: value,
      gain_loss_24h: value - prevValue,
      percent_change_24h: stats.change_24h
    });
  }

  const sorted = [...positions].sort((a, b) => b.percent_change_24h - a.percent_change_24h);

  return {
    total_value_usd: totalValue,
    total_change_24h_percent: totalPrevValue > 0 ? ((totalValue - totalPrevValue) / totalPrevValue) * 100 : 0,
    positions,
    best_performer: sorted[0]?.symbol || 'N/A',
    worst_performer: sorted[sorted.length - 1]?.symbol || 'N/A'
  };
}

export function getPairStats(base: string, quote: string): PairResult {
  const baseStats = getCoinStats(base);
  const quoteStats = getCoinStats(quote);
  
  const ratio = baseStats.price / quoteStats.price;
  const prevRatio = (baseStats.price / (1 + baseStats.change_24h / 100)) / 
                    (quoteStats.price / (1 + quoteStats.change_24h / 100));
  
  const change = ((ratio - prevRatio) / prevRatio) * 100;

  return {
    pair: `${base}/${quote}`,
    ratio: parseFloat(ratio.toFixed(6)),
    trend: (change > 0.5 ? 'up' : (change < -0.5 ? 'down' : 'neutral')) as 'up' | 'down' | 'neutral',
    change_24h_percent: parseFloat(change.toFixed(2))
  };
}

export function getMarketOverview(): MarketOverview {
  const btcStats = getCoinStats('BTC');
  const unusual = Math.random() < 0.1;

  return {
    total_market_cap_usd: "2.45T",
    btc_dominance_percent: 52.4 + (Math.random() * 2),
    market_sentiment: (btcStats.change_24h > 2 ? 'bullish' : (btcStats.change_24h < -2 ? 'bearish' : 'uncertain')) as 'bullish' | 'bearish' | 'uncertain',
    unusual_conditions: unusual,
    top_gainers: ASSETS.slice(0, 3).map(a => a.s)
  };
}

export function getPriceStats(symbols: string[]): Record<string, CryptoPrice> {
  const results: Record<string, CryptoPrice> = {};
  symbols.forEach(s => {
    results[s] = getCoinStats(s);
  });
  return results;
}
