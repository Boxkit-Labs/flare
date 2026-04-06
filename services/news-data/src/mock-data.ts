export interface Article {
  id: string;
  title: string;
  source: string;
  url: string;
  summary: string;
  keywords: string[];
  companies: string[];
  people: string[];
  sentiment_score: number; // -1 to +1
  sentiment_label: 'positive' | 'negative' | 'neutral';
  source_count: number; // Multi-source verification
  published_at: string;
}

const SOURCES = ["TechCrunch", "CoinDesk", "The Block", "Bloomberg", "Reuters", "Decrypt", "Financial Times", "CNBC", "Wall Street Journal"];

const COMPANIES = ["Apple", "Tesla", "Stellar", "NVIDIA", "Microsoft", "Google", "Amazon", "Meta", "Coinbase", "Binance"];
const PEOPLE = ["Jed McCaleb", "Elon Musk", "Denelle Dixon", "Vitalik Buterin", "Jensen Huang", "Sam Altman"];

// Pre-define 60+ articles for a rich pool
const ARTICLE_POOL: Article[] = [
  ...Array.from({ length: 65 }).map((_, i) => {
    const sentiment = (Math.random() * 2) - 1; // -1 to 1
    const company = COMPANIES[i % COMPANIES.length];
    const person = PEOPLE[i % PEOPLE.length];
    const topics = ["AI", "Blockchain", "Regulation", "DeFi", "Smart Contracts", "Payments", "Web3"];
    const topic = topics[i % topics.length];
    
    return {
      id: `art-${i}`,
      title: `${company} ${['unveils', 'launches', 'critiques', 'dominates', 'integrates'][i % 5]} new ${topic} ${['initiative', 'platform', 'framework', 'protocol'][i % 4]}`,
      source: SOURCES[i % SOURCES.length],
      url: `https://mock-news.io/article/${i}`,
      summary: `A breakthrough development in ${topic} involving ${company} and ${person} has sent ripples through the industry. Experts suggest this could lead to a 30% increase in efficiency for ${topic} systems globally.`,
      keywords: [topic.toLowerCase(), company.toLowerCase(), person.toLowerCase(), "innovation"],
      companies: [company],
      people: [person],
      sentiment_score: parseFloat(sentiment.toFixed(2)),
      sentiment_label: (sentiment > 0.2 ? 'positive' : (sentiment < -0.2 ? 'negative' : 'neutral')) as 'positive' | 'negative' | 'neutral',
      source_count: Math.floor(Math.random() * 5) + 1,
      published_at: new Date(Date.now() - (i * 1.5 * 3600000)).toISOString()
    };
  })
];

const startTime = Date.now();

export function getNewsResults(params: {
  keywords?: string[];
  companies?: string[];
  people?: string[];
  exclude_keywords?: string[];
  max_results?: number;
}): any {
  const { keywords = [], companies = [], people = [], exclude_keywords = [], max_results = 10 } = params;

  // Simulate hourly rotation: update timestamps of random articles
  const hoursSinceStart = Math.floor((Date.now() - startTime) / 3600000);
  if (hoursSinceStart > 0) {
    for (let j = 0; j < Math.min(hoursSinceStart, 5); j++) {
        const idx = Math.floor(Math.random() * ARTICLE_POOL.length);
        ARTICLE_POOL[idx].published_at = new Date().toISOString();
    }
  }

  const results = ARTICLE_POOL.filter(article => {
    // 1. Keyword Exclusion
    if (exclude_keywords.some(ek => 
      article.title.toLowerCase().includes(ek.toLowerCase()) || 
      article.summary.toLowerCase().includes(ek.toLowerCase())
    )) return false;

    // 2. Monitoring logic (OR across types)
    const keywordMatch = keywords.length === 0 || keywords.some(k => 
      article.keywords.includes(k.toLowerCase()) || 
      article.title.toLowerCase().includes(k.toLowerCase())
    );
    
    const companyMatch = companies.length === 0 || companies.some(c => 
      article.companies.map(ac => ac.toLowerCase()).includes(c.toLowerCase())
    );

    const personMatch = people.length === 0 || people.some(p => 
      article.people.map(ap => ap.toLowerCase()).includes(p.toLowerCase())
    );

    return keywordMatch && companyMatch && personMatch;
  });

  // Calculate scores and extra flags
  const enriched = results.map(r => {
    const isBreaking = (Date.now() - new Date(r.published_at).getTime()) < 3600000;
    return {
      ...r,
      is_breaking: isBreaking,
      is_trending: r.source_count >= 3
    };
  })
  .sort((a, b) => new Date(b.published_at).getTime() - new Date(a.published_at).getTime())
  .slice(0, max_results);

  const avgSentiment = enriched.length > 0 
    ? enriched.reduce((sum, a) => sum + a.sentiment_score, 0) / enriched.length
    : 0;

  return {
    articles: enriched,
    total_matches: results.length,
    average_sentiment: parseFloat(avgSentiment.toFixed(2)),
    average_sentiment_label: avgSentiment > 0.2 ? 'positive' : (avgSentiment < -0.2 ? 'negative' : 'neutral'),
    checked_at: new Date().toISOString()
  };
}
