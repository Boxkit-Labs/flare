export interface Article {
  id: string;
  title: string;
  source: string;
  url: string;
  summary: string;
  keywords: string[];
  published_at: string;
  relevance_score?: number;
}

const SOURCES = ["TechCrunch", "CoinDesk", "The Block", "Bloomberg", "Reuters", "Decrypt"];

const ARTICLE_POOL: Article[] = [
  {
    id: "1",
    title: "Stellar Announces Soroban Mainnet Launch Date",
    source: "CoinDesk",
    url: "https://example.com/news/1",
    summary: "The Stellar Development Foundation has finalized the mainnet launch date for Soroban, its new smart contract platform. This marks a major milestone for the Stellar ecosystem.",
    keywords: ["stellar", "soroban", "blockchain", "smart contracts"],
    published_at: "2026-04-01T10:00:00Z"
  },
  {
    id: "2",
    title: "AI Agents are Revolutionizing DeFi Asset Management",
    source: "TechCrunch",
    url: "https://example.com/news/2",
    summary: "New autonomous AI agents are being deployed to manage complex DeFi portfolios, optimizing for yield and risk in real-time without human intervention.",
    keywords: ["AI agents", "DeFi", "AI", "finance"],
    published_at: "2026-04-01T12:00:00Z"
  },
  {
    id: "3",
    title: "x402 Protocol Gains Traction Among Web3 Developers",
    source: "The Block",
    url: "https://example.com/news/3",
    summary: "The x402 payment protocol is seeing a surge in adoption as developers look for seamless ways to monetize APIs and agent-to-agent interactions.",
    keywords: ["x402", "monetization", "web3", "API"],
    published_at: "2026-04-02T09:00:00Z"
  },
  {
    id: "4",
    title: "SEC Proposes New Framework for Stablecoin Regulation",
    source: "Reuters",
    url: "https://example.com/news/4",
    summary: "The SEC has released a comprehensive proposal for regulating stablecoins, focusing on reserve transparency and consumer protection standards.",
    keywords: ["crypto regulation", "stablecoins", "finance", "SEC"],
    published_at: "2026-04-02T15:00:00Z"
  },
  {
    id: "5",
    title: "Soroban Ecosystem Fund Surpasses $100M in Grants",
    source: "Decrypt",
    url: "https://example.com/news/5",
    summary: "The Soroban adoption fund has reached a new milestone, having distributed over $100 million to developers building innovative dApps on Stellar.",
    keywords: ["stellar", "soroban", "grants", "developers"],
    published_at: "2026-04-03T08:00:00Z"
  },
  {
    id: "6",
    title: "NVIDIA Unveils Next-Gen AI Chips for Decentralized Computing",
    source: "Bloomberg",
    url: "https://example.com/news/6",
    summary: "NVIDIA's latest hardware release is specifically optimized for decentralized AI training, promising a 40% increase in efficiency for global compute networks.",
    keywords: ["AI", "tech", "NVIDIA", "decentralized compute"],
    published_at: "2026-04-03T11:00:00Z"
  },
  // Adding more articles to reach 30+...
  ...Array.from({ length: 25 }).map((_, i) => ({
    id: `pool-${i}`,
    title: `Headline #${i + 7}: Market Trends in ${["AI", "Stellar", "DeFi", "Crypto", "Web3", "Tech"][i % 6]}`,
    source: SOURCES[i % SOURCES.length],
    url: `https://example.com/news/pool-${i}`,
    summary: `Detailed summary for article ${i + 7} covering the latest developments in ${["blockchain regulatory frameworks", "autonomous agent orchestration", "Soroban smart contract optimization", "cross-chain liquidity pools", "generative AI for developers"][i % 5]}.`,
    keywords: [
      ["stellar", "soroban"][i % 2],
      ["AI agents", "tech"][i % 2],
      ["finance", "crypto regulation", "DeFi", "x402"][i % 4]
    ],
    published_at: new Date(Date.now() - (i * 3600000)).toISOString()
  }))
];

const startTime = Date.now();

export function getArticlesForQuery(queryKeywords: string[], maxResults: number = 5): any {
  // Simulate hourly rotation: update 1-2 random articles' published_at
  const hoursSinceStart = Math.floor((Date.now() - startTime) / 3600000);
  if (hoursSinceStart > 0) {
    for (let j = 0; j < Math.min(hoursSinceStart, 5); j++) {
        const idx = Math.floor(Math.random() * ARTICLE_POOL.length);
        ARTICLE_POOL[idx].published_at = new Date().toISOString();
    }
  }

  const results = ARTICLE_POOL.map(article => {
    const overlap = article.keywords.filter(k => 
      queryKeywords.some(qk => k.toLowerCase().includes(qk.toLowerCase()) || qk.toLowerCase().includes(k.toLowerCase()))
    ).length;
    
    // Simple relevance score: matches / (total query keywords or 1)
    const score = queryKeywords.length > 0 ? Math.min(1, overlap / queryKeywords.length) : 0;
    
    return { ...article, relevance_score: Math.round(score * 100) / 100 };
  })
  .filter(a => a.relevance_score && a.relevance_score > 0)
  .sort((a, b) => (b.relevance_score || 0) - (a.relevance_score || 0) || new Date(b.published_at).getTime() - new Date(a.published_at).getTime())
  .slice(0, maxResults);

  return {
    articles: results.map(r => ({
      title: r.title,
      source: r.source,
      url: r.url,
      summary: r.summary,
      relevance_score: r.relevance_score,
      published_at: r.published_at
    })),
    total_matches: results.length,
    query_keywords: queryKeywords,
    checked_at: new Date().toISOString()
  };
}
