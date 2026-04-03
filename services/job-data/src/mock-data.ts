export interface JobListing {
  id: string;
  title: string;
  company: string;
  location: string;
  remote: boolean;
  salary_min: number;
  salary_max: number;
  keywords: string[];
  posted_at: string;
  url: string;
  relevance_score?: number;
  is_new?: boolean;
}

const COMPANIES = ["Stripe", "Coinbase", "Stellar", "Google", "Meta", "Apple", "Figma", "Linear", "Vercel", "Supabase"];
const TITLES = ["Flutter Developer", "Mobile Engineer", "Blockchain Developer", "Full Stack Engineer", "AI/ML Engineer", "DevOps Engineer", "Product Designer", "Smart Contract Developer"];
const LOCATIONS = ["San Francisco, CA", "New York, NY", "London, UK", "Berlin, DE", "Singapore", "Austin, TX", "Remote"];

const JOB_POOL: JobListing[] = Array.from({ length: 40 }).map((_, i) => {
  const company = COMPANIES[i % COMPANIES.length];
  const title = TITLES[i % TITLES.length];
  const locationIdx = i % LOCATIONS.length;
  const location = LOCATIONS[locationIdx];
  const remote = location === 'Remote' || i % 3 === 0;
  const salaryMin = 80000 + (Math.floor(Math.random() * 12) * 10000);
  const salaryMax = salaryMin + 20000 + (Math.floor(Math.random() * 5) * 10000);

  return {
    id: `job-${i}`,
    title,
    company,
    location: remote ? "Remote" : location,
    remote,
    salary_min: salaryMin,
    salary_max: salaryMax,
    keywords: [
      title.split(' ')[0].toLowerCase(),
      company.toLowerCase(),
      ["blockchain", "AI", "mobile", "web", "infra"][i % 5],
      ["stellar", "soroban", "react", "flutter", "typescript"][i % 5]
    ],
    posted_at: new Date(Date.now() - (i * 86400000)).toISOString(), // Distributed over last 40 days
    url: `https://example.com/jobs/job-${i}`
  };
});

const startTime = Date.now();
const seenJobIds = new Set<string>();

export function searchJobs(keywords: string[], location?: string, remoteOnly?: boolean, salaryMin?: number): any {
  // Simulate rotation: add 1-3 new jobs every 4 hours
  const hoursSinceStart = Math.floor((Date.now() - startTime) / (3600000 * 4));
  if (hoursSinceStart > 0) {
    for (let j = 0; j < Math.min(hoursSinceStart * 2, 10); j++) {
      const newId = `new-job-${hoursSinceStart}-${j}`;
      if (!JOB_POOL.some(job => job.id === newId)) {
          const company = COMPANIES[Math.floor(Math.random() * COMPANIES.length)];
          const title = TITLES[Math.floor(Math.random() * TITLES.length)];
          JOB_POOL.push({
            id: newId,
            title,
            company,
            location: Math.random() > 0.5 ? "Remote" : "New York, NY",
            remote: Math.random() > 0.5,
            salary_min: 120000,
            salary_max: 180000,
            keywords: ["new", "fresh", title.toLowerCase()],
            posted_at: new Date().toISOString(),
            url: `https://example.com/jobs/${newId}`
          });
      }
    }
  }

  let results = JOB_POOL.map(job => {
    // Score by keyword overlap
    const score = keywords.reduce((acc, k) => {
      let s = 0;
      if (job.title.toLowerCase().includes(k.toLowerCase())) s += 2;
      if (job.keywords.some(jk => jk.toLowerCase().includes(k.toLowerCase()))) s += 1;
      return acc + s;
    }, 0);

    return { ...job, relevance_score: score };
  });

  // Filters
  if (keywords.length > 0) {
    results = results.filter(j => j.relevance_score && j.relevance_score > 0);
  }
  if (location) {
    results = results.filter(j => j.location.toLowerCase().includes(location.toLowerCase()));
  }
  if (remoteOnly) {
    results = results.filter(j => j.remote);
  }
  if (salaryMin) {
    results = results.filter(j => j.salary_min >= salaryMin);
  }

  // Sort by relevance then date
  results.sort((a, b) => b.relevance_score! - a.relevance_score! || new Date(b.posted_at).getTime() - new Date(a.posted_at).getTime());

  // Detect new listings (seen per session)
  let newCount = 0;
  const listings = results.map(j => {
    const isNew = !seenJobIds.has(j.id);
    if (isNew) {
      newCount++;
      // Actually in a real session you'd wait for a "clear" or similar, but here we'll flag it
    }
    return {
      title: j.title,
      company: j.company,
      location: j.location,
      remote: j.remote,
      salary_range: `$${j.salary_min/1000}k - $${j.salary_max/1000}k`,
      url: j.url,
      relevance_score: j.relevance_score,
      posted_at: j.posted_at,
      is_new: isNew
    };
  });

  // Mark all as seen for next check in this session
  results.forEach(j => seenJobIds.add(j.id));

  return {
    listings,
    total_matches: results.length,
    new_since_last_check: newCount,
    checked_at: new Date().toISOString()
  };
}
