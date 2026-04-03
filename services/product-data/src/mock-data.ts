export interface Product {
  name: string;
  base_price: number;
  category: string;
}

export interface ProductResult {
  product_name: string;
  current_price: number;
  store: string;
  url: string;
  on_sale: boolean;
  discount_percent: number | null;
  price_history: number[];
  lowest_30_day: number;
  checked_at: string;
}

const CATALOG: Product[] = [
  { name: "Sony WH-1000XM5", base_price: 349.99, category: "electronics" },
  { name: "MacBook Air M3", base_price: 1099, category: "electronics" },
  { name: "Nike Air Max 90", base_price: 130, category: "shoes" },
  { name: "Adidas Ultraboost Light", base_price: 190, category: "shoes" },
  { name: "Le Creuset Dutch Oven", base_price: 419.95, category: "kitchen" },
  { name: "KitchenAid Artisan Stand Mixer", base_price: 449.99, category: "kitchen" },
  { name: "PlayStation 5 Slim", base_price: 499.99, category: "gaming" },
  { name: "Xbox Series X", base_price: 499, category: "gaming" },
  { name: "The Creative Act by Rick Rubin", base_price: 32, category: "books" },
  { name: "Atomic Habits by James Clear", base_price: 27, category: "books" },
  { name: "Bowflex SelectTech 552", base_price: 429, category: "fitness" },
  { name: "Peloton Bike+", base_price: 2495, category: "fitness" },
  { name: "Nintendo Switch OLED", base_price: 349.99, category: "gaming" },
  { name: "iPad Pro M4", base_price: 999, category: "electronics" },
  { name: "Dyson V15 Detect", base_price: 749, category: "kitchen" },
  { name: "Herman Miller Aeron", base_price: 1600, category: "electronics" }, // Office
  { name: "Logitech MX Master 3S", base_price: 99, category: "electronics" },
  { name: "Lululemon Align High-Rise Pant", base_price: 98, category: "fitness" },
  { name: "Nespresso Vertuo Next", base_price: 179, category: "kitchen" },
  { name: "Kindle Paperwhite", base_price: 139.99, category: "books" }
];

const STORES = ["Amazon", "Best Buy", "Walmart", "Target", "B&H Photo", "Costco"];

// In-memory price history: last 8 prices per product
const productHistory: Record<string, number[]> = {};

function fuzzyMatch(query: string, productName: string): boolean {
  const q = query.toLowerCase();
  const p = productName.toLowerCase();
  // Simple substring or word overlap
  if (p.includes(q)) return true;
  const qWords = q.split(/\s+/);
  return qWords.some(word => word.length > 2 && p.includes(word));
}

export function getProductData(query: string): ProductResult | null {
  const product = CATALOG.find(p => fuzzyMatch(query, p.name));
  if (!product) return null;

  const history = productHistory[product.name] || [product.base_price];
  const lastPrice = history[history.length - 1];

  // Apply ±10% variation
  const variation = (Math.random() * 0.2) - 0.1; // -0.1 to +0.1
  let currentPrice = lastPrice * (1 + variation);

  // Apply sale: 1 in 6, 20-35% discount
  let onSale = false;
  let discountPercent = null;
  if (Math.random() < 0.166) {
    onSale = true;
    discountPercent = Math.round(20 + Math.random() * 15);
    currentPrice = currentPrice * (1 - discountPercent / 100);
  }

  currentPrice = Math.round(currentPrice * 100) / 100;

  // Update history
  history.push(currentPrice);
  if (history.length > 8) {
    history.shift();
  }
  productHistory[product.name] = history;

  const lowest30Day = Math.min(...history, product.base_price * 0.6); // Simulated floor

  return {
    product_name: product.name,
    current_price: currentPrice,
    store: STORES[Math.floor(Math.random() * STORES.length)],
    url: `https://example.com/product/${product.name.replace(/\s+/g, '-').toLowerCase()}`,
    on_sale: onSale,
    discount_percent: discountPercent,
    price_history: [...history],
    lowest_30_day: Math.round(lowest30Day * 100) / 100,
    checked_at: new Date().toISOString()
  };
}
