export interface StockStats {
  symbol: string;
  name: string;
  price: number;
  change_24h: number;
  change_percent_24h: number;
  volume_24h: number;
  volume_category: 'normal' | 'high' | 'spike';
  high_52w: number;
  low_52w: number;
  pe_ratio: number;
  market_cap_tier: 'mega' | 'large' | 'mid';
  sector: string;
  history_30d: number[];
  event?: string;
}

interface MarketIndices {
  sp500: { price: number; change_percent: number };
  nasdaq: { price: number; change_percent: number };
}

const STOCKS = [
  { s: 'AAPL', n: 'Apple Inc.', p: 185.92, v: 0.015, sector: 'Tech', cap: 'mega', pe: 28.5 },
  { s: 'TSLA', n: 'Tesla, Inc.', p: 171.05, v: 0.035, sector: 'Tech', cap: 'mega', pe: 42.1 },
  { s: 'NVDA', n: 'NVIDIA Corp.', p: 894.52, v: 0.040, sector: 'Tech', cap: 'mega', pe: 72.4 },
  { s: 'GOOGL', n: 'Alphabet Inc.', p: 154.22, v: 0.018, sector: 'Tech', cap: 'mega', pe: 25.8 },
  { s: 'MSFT', n: 'Microsoft Corp.', p: 425.22, v: 0.014, sector: 'Tech', cap: 'mega', pe: 36.2 },
  { s: 'AMZN', n: 'Amazon.com, Inc.', p: 185.07, v: 0.020, sector: 'Tech', cap: 'mega', pe: 62.1 },
  { s: 'META', n: 'Meta Platforms', p: 527.34, v: 0.025, sector: 'Tech', cap: 'mega', pe: 32.4 },
  { s: 'JPM', n: 'JPMorgan Chase', p: 198.45, v: 0.012, sector: 'Finance', cap: 'mega', pe: 11.8 },
  { s: 'V', n: 'Visa Inc.', p: 278.44, v: 0.010, sector: 'Finance', cap: 'mega', pe: 31.4 },
  { s: 'GS', n: 'Goldman Sachs', p: 412.33, v: 0.015, sector: 'Finance', cap: 'large', pe: 14.2 },
  { s: 'DIS', n: 'Walt Disney Co.', p: 118.92, v: 0.022, sector: 'Entertainment', cap: 'large', pe: 24.5 },
  { s: 'NFLX', n: 'Netflix, Inc.', p: 636.18, v: 0.028, sector: 'Entertainment', cap: 'large', pe: 51.2 },
  { s: 'NKE', n: 'Nike, Inc.', p: 92.45, v: 0.018, sector: 'Consumer', cap: 'large', pe: 27.4 },
  { s: 'COST', n: 'Costco Wholesale', p: 712.33, v: 0.011, sector: 'Consumer', cap: 'large', pe: 45.8 },
  { s: 'WMT', n: 'Walmart Inc.', p: 60.22, v: 0.009, sector: 'Consumer', cap: 'mega', pe: 25.4 }
];

// In-memory price state
const priceState: Record<string, number[]> = {};

function getStockStats(symbol: string): StockStats {
  const meta = STOCKS.find(s => s.s === symbol) || STOCKS[0];
  const history = priceState[symbol] || Array.from({ length: 30 }).map((_, i) => meta.p * (1 + (Math.random() * 0.1 - 0.05)));
  
  const lastPrice = history[history.length - 1];
  
  // Smooth realistic movement (GBM Step)
  // NewPrice = LastPrice * exp((drift - 0.5 * sigma^2) + sigma * rand)
  // Simplified for mock:
  const sigma = meta.v;
  const rand = (Math.random() * 2 - 1) + (Math.random() * 2 - 1) + (Math.random() * 2 - 1); // Normal approx
  const change = (lastPrice * sigma * (rand / 3));
  let newPrice = lastPrice + change;

  let event = undefined;
  // Earnings Surprise (1 in 8)
  if (Math.random() < 0.125) {
    const surprise = (Math.random() * 0.07 + 0.05) * (Math.random() > 0.5 ? 1 : -1);
    newPrice *= (1 + surprise);
    event = `Earnings Surprise: ${surprise > 0 ? '+' : ''}${(surprise * 100).toFixed(1)}%`;
  }
  // Analyst Move (1 in 10)
  else if (Math.random() < 0.1) {
    const upgrade = Math.random() > 0.5;
    newPrice *= (upgrade ? 1.02 : 0.98);
    event = upgrade ? "Analyst Upgrade: Buy" : "Analyst Downgrade: Hold";
  }

  history.push(newPrice);
  if (history.length > 30) history.shift();
  priceState[symbol] = history;

  const prevPrice = history[history.length - 2] || history[0];
  const change24h = newPrice - prevPrice;
  
  const volumeRand = Math.random();
  const volCategory = volumeRand > 0.9 ? 'spike' : (volumeRand > 0.7 ? 'high' : 'normal');

  return {
    symbol,
    name: meta.n,
    price: parseFloat(newPrice.toFixed(2)),
    change_24h: parseFloat(change24h.toFixed(2)),
    change_percent_24h: parseFloat(((change24h / prevPrice) * 100).toFixed(2)),
    volume_24h: Math.floor(Math.random() * 10000000) * (volCategory === 'spike' ? 5 : (volCategory === 'high' ? 2 : 1)),
    volume_category: volCategory,
    high_52w: Math.round(Math.max(...history, meta.p * 1.2) * 100) / 100,
    low_52w: Math.round(Math.min(...history, meta.p * 0.8) * 100) / 100,
    pe_ratio: meta.pe,
    market_cap_tier: meta.cap as any,
    sector: meta.sector,
    history_30d: history.map(p => parseFloat(p.toFixed(2))),
    event
  };
}

export function getFinanceData(symbols?: string[]): any {
  const targetSymbols = symbols && symbols.length > 0 ? symbols.map(s => s.toUpperCase()) : STOCKS.map(s => s.s);
  const results = targetSymbols.map(s => getStockStats(s));
  
  // Calculate Indices
  const allCurrent = STOCKS.map(s => getStockStats(s.s));
  
  // S&P 500 (Equal weight for mock)
  const spAvg = allCurrent.reduce((acc, s) => acc + s.change_percent_24h, 0) / STOCKS.length;
  
  // NASDAQ (Tech heavy weight)
  const techStocks = allCurrent.filter(s => s.sector === 'Tech');
  const nasdaqAvg = (techStocks.reduce((acc, s) => acc + s.change_percent_24h, 0) / techStocks.length) * 0.7 + (spAvg * 0.3);

  return {
    stocks: results,
    indices: {
      sp500: { price: 5240 + (spAvg * 5), change_percent: parseFloat(spAvg.toFixed(2)) },
      nasdaq: { price: 16340 + (nasdaqAvg * 15), change_percent: parseFloat(nasdaqAvg.toFixed(2)) }
    },
    market_status: spAvg > 0.5 ? 'Bullish' : (spAvg < -0.5 ? 'Bearish' : 'Neutral'),
    checked_at: new Date().toISOString()
  };
}
