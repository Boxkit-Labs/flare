import { v4 as uuidv4 } from 'uuid';

interface Product {
  id: string;
  name: string;
  category: string;
  base_price: number;
}

interface StorePrice {
  store: string;
  price: number;
  in_stock: boolean;
  on_sale: boolean;
  discount_percent?: number;
  url: string;
}

interface ProductComparison {
  product_name: string;
  category: string;
  stores: StorePrice[];
  cheapest: {
    store: string;
    price: number;
    difference: number;
  };
  is_ath: boolean;
  checked_at: string;
}

const STORES = ["Amazon", "Best Buy", "Walmart", "Target", "B&H Photo", "Costco"];

const CATALOG: Product[] = [
  // Electronics
  { id: "p1", name: "Sony WH-1000XM5", category: "electronics", base_price: 349 },
  { id: "p2", name: "MacBook Air M3", category: "electronics", base_price: 1099 },
  { id: "p3", name: "iPad Pro M4", category: "electronics", base_price: 999 },
  { id: "p4", name: "Logitech MX Master 3S", category: "electronics", base_price: 99 },
  { id: "p5", name: "Kindle Paperwhite", category: "electronics", base_price: 139 },
  
  // Audio
  { id: "p6", name: "Sonos Era 300", category: "audio", base_price: 449 },
  { id: "p7", name: "Bose QuietComfort Ultra", category: "audio", base_price: 429 },
  { id: "p8", name: "AirPods Pro 2", category: "audio", base_price: 249 },
  
  // Gaming
  { id: "p9", name: "PlayStation 5 Slim", category: "gaming", base_price: 499 },
  { id: "p10", name: "Xbox Series X", category: "gaming", base_price: 499 },
  { id: "p11", name: "Nintendo Switch OLED", category: "gaming", base_price: 349 },
  { id: "p12", name: "Steam Deck OLED", category: "gaming", base_price: 549 },
  { id: "p13", name: "LG C3 42-inch OLED TV", category: "gaming", base_price: 899 },
  { id: "p14", name: "Samsung Odyssey G7", category: "gaming", base_price: 699 },
  
  // Kitchen
  { id: "p15", name: "Le Creuset Dutch Oven", category: "kitchen", base_price: 419 },
  { id: "p16", name: "KitchenAid Artisan Mixer", category: "kitchen", base_price: 449 },
  { id: "p17", name: "Dyson V15 Detect", category: "kitchen", base_price: 749 },
  { id: "p18", name: "Nespresso Vertuo Next", category: "kitchen", base_price: 179 },
  { id: "p19", name: "Ninja AF101 Air Fryer", category: "kitchen", base_price: 119 },
  
  // Fitness
  { id: "p20", name: "Bowflex SelectTech 552", category: "fitness", base_price: 429 },
  { id: "p21", name: "Peloton Bike+", category: "fitness", base_price: 2495 },
  { id: "p22", name: "Lululemon Align Pant", category: "fitness", base_price: 98 },
  { id: "p23", name: "Garmin Epix Gen 2", category: "fitness", base_price: 799 },
  
  // Shoes/Clothing
  { id: "p24", name: "Nike Air Max 90", category: "shoes", base_price: 130 },
  { id: "p25", name: "Adidas Ultraboost Light", category: "shoes", base_price: 190 },
  { id: "p26", name: "Patagonia Better Sweater", category: "clothing", base_price: 129 },
  { id: "p27", name: "Levi's 501 Original", category: "clothing", base_price: 79 },
  
  // Furniture
  { id: "p28", name: "Herman Miller Aeron", category: "furniture", base_price: 1600 },
  { id: "p29", name: "Steelcase Gesture", category: "furniture", base_price: 1300 },
  { id: "p30", name: "Eames Lounge Chair Rep", category: "furniture", base_price: 800 },
  
  // Extra (to reach 40+)
  ...Array.from({ length: 15 }).map((_, i) => ({
    id: `extra-${i}`,
    name: `Premium ${['Toaster', 'Backpack', 'Monitor', 'Desk Lamp', 'Yoga Mat'][i % 5]} ${i + 31}`,
    category: ['kitchen', 'clothing', 'gaming', 'furniture', 'fitness'][i % 5],
    base_price: 50 + (i * 20)
  }))
];

// In-memory state for price history and availability
const priceHistory: Record<string, number> = {};
const availabilityState: Record<string, boolean> = {};

function getStorePrice(product: Product, storeName: string): StorePrice {
  const variation = (Math.random() * 0.15) - 0.05; // -5% to +10%
  let price = product.base_price * (1 + variation);
  
  // Flash sale: 1 in 8 chance, 20-35% off
  let onSale = false;
  let discount = 0;
  if (Math.random() < 0.125) {
    onSale = true;
    discount = 20 + Math.floor(Math.random() * 15);
    price *= (1 - discount / 100);
  }

  // Stock: 10% chance out of stock
  const inStock = Math.random() > 0.1;

  return {
    store: storeName,
    price: Math.round(price * 100) / 100,
    in_stock: inStock,
    on_sale: onSale,
    discount_percent: onSale ? discount : undefined,
    url: `https://www.${storeName.toLowerCase().replace(/\s+/g, '')}.com/p/${product.id}`
  };
}

export function compareProduct(query: string): ProductComparison | null {
  const product = CATALOG.find(p => p.name.toLowerCase().includes(query.toLowerCase()));
  if (!product) return null;

  const stores = STORES.slice(0, 4 + Math.floor(Math.random() * 3)).map(s => getStorePrice(product, s));
  const inStockStores = stores.filter(s => s.in_stock);
  const cheapestStore = inStockStores.length > 0 
    ? inStockStores.reduce((prev, curr) => prev.price < curr.price ? prev : curr)
    : stores[0];
  
  const mostExpensive = stores.reduce((prev, curr) => prev.price > curr.price ? prev : curr);
  const isATH = !priceHistory[product.id] || cheapestStore.price < priceHistory[product.id];
  
  if (isATH) priceHistory[product.id] = cheapestStore.price;

  return {
    product_name: product.name,
    category: product.category,
    stores,
    cheapest: {
      store: cheapestStore.store,
      price: cheapestStore.price,
      difference: Math.round((mostExpensive.price - cheapestStore.price) * 100) / 100
    },
    is_ath: isATH,
    checked_at: new Date().toISOString()
  };
}

export function monitorWishlist(items: Array<{ name: string; target_price: number }>): any {
  const results = items.map(item => {
    const comparison = compareProduct(item.name);
    if (!comparison) return { name: item.name, error: "Product not found" };

    const best = comparison.stores.filter(s => s.in_stock).sort((a, b) => a.price - b.price)[0];
    const onSale = comparison.stores.some(s => s.on_sale);

    return {
      name: comparison.product_name,
      target_price: item.target_price,
      current_price: best?.price || comparison.stores[0].price,
      is_below_target: best ? best.price <= item.target_price : false,
      in_stock: comparison.stores.some(s => s.in_stock),
      on_sale: onSale,
      store: best?.store || comparison.stores[0].store
    };
  });

  return { items: results, checked_at: new Date().toISOString() };
}

export function checkAvailability(productName: string): any {
  const product = CATALOG.find(p => p.name.toLowerCase().includes(productName.toLowerCase()));
  if (!product) return { error: "Product not found" };

  const stores = STORES.map(s => getStorePrice(product, s));
  const currentlyAvailable = stores.some(s => s.in_stock);
  const previouslyAvailable = availabilityState[product.id] ?? true;
  
  const wasRestocked = currentlyAvailable && !previouslyAvailable;
  availabilityState[product.id] = currentlyAvailable;

  return {
    product_name: product.name,
    is_available: currentlyAvailable,
    was_restocked: wasRestocked,
    store_status: stores.map(s => ({ store: s.store, status: s.in_stock ? 'In Stock' : 'Out of Stock' })),
    checked_at: new Date().toISOString()
  };
}

export function searchCategoryDeals(query: string): any {
  // Extract category and budget from query like "gaming monitor under $300"
  const q = query.toLowerCase();
  const categories = [...new Set(CATALOG.map(p => p.category))];
  const category = categories.find(c => q.includes(c)) || 'gaming';
  
  const budgetMatch = q.match(/under \$(\d+)/);
  const budget = budgetMatch ? parseInt(budgetMatch[1]) : 10000;

  const matches = CATALOG.filter(p => p.category === category);
  const results = matches.map(p => {
    const comp = compareProduct(p.name)!;
    const best = comp.stores.filter(s => s.in_stock).sort((a, b) => a.price - b.price)[0];
    return {
      name: p.name,
      price: best?.price || p.base_price,
      store: best?.store || "Multiple",
      on_sale: comp.stores.some(s => s.on_sale),
      value_score: (p.base_price / (best?.price || p.base_price)) * 10
    };
  })
  .filter(r => r.price <= budget)
  .sort((a, b) => b.value_score - a.value_score);

  return {
    query,
    category,
    budget,
    matches: results.slice(0, 10),
    checked_at: new Date().toISOString()
  };
}
