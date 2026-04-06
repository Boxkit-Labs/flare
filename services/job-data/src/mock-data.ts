import { v4 as uuidv4 } from 'uuid';

export interface JobListing {
  id: string;
  title: string;
  company: string;
  location: string;
  remote: boolean;
  type: 'full-time' | 'contract' | 'freelance';
  salary_min: number;
  salary_max: number;
  hourly_rate?: number;
  duration_months?: number;
  keywords: string[];
  posted_at: string;
  url: string;
  skills_score: number;
  is_hot: boolean;
  is_new: boolean;
}

const COMPANIES = ["Google", "Stripe", "Stellar", "Meta", "Apple", "Coinbase", "Linear", "Figma", "OpenAI", "Anthropic", "Vercel", "Supabase"];
const ROLES = ["Senior Flutter Engineer", "Staff Mobile Engineer", "Blockchain Architect", "Full Stack Dev", "AI/ML Engineer", "Product Designer", "DevOps Specialist", "Marketing Lead"];

const JOB_POOL: JobListing[] = Array.from({ length: 85 }).map((_, i) => {
  const company = COMPANIES[i % COMPANIES.length];
  const role = ROLES[i % ROLES.length];
  const type: any = (i % 5 === 0) ? 'contract' : (i % 7 === 0 ? 'freelance' : 'full-time');
  
  const salaryMin = 90000 + (Math.floor(Math.random() * 10) * 15000);
  const salaryMax = salaryMin + 30000 + (Math.floor(Math.random() * 5) * 10000);
  
  const skillsScore = 60 + Math.floor(Math.random() * 40);
  const isHot = salaryMax > 220000;

  return {
    id: `job-${i}`,
    title: role,
    company,
    location: i % 3 === 0 ? "Remote" : "New York, NY",
    remote: i % 3 === 0,
    type,
    salary_min: salaryMin,
    salary_max: salaryMax,
    hourly_rate: type !== 'full-time' ? 80 + Math.floor(Math.random() * 70) : undefined,
    duration_months: type !== 'full-time' ? 3 + Math.floor(Math.random() * 9) : undefined,
    keywords: [role.toLowerCase().split(' ')[0], company.toLowerCase(), "tech"],
    posted_at: new Date(Date.now() - (i * 2 * 3600000)).toISOString(),
    url: `https://jobs.io/apply/${uuidv4()}`,
    skills_score: skillsScore,
    is_hot: isHot,
    is_new: i < 5
  };
});

const startTime = Date.now();

export function getCompanyJobs(companyName: string): any {
  const jobs = JOB_POOL.filter(j => j.company.toLowerCase() === companyName.toLowerCase());
  const newToday = jobs.filter(j => (Date.now() - new Date(j.posted_at).getTime()) < 86400000).length;
  
  let insight = `${companyName} is maintaining steady hiring.`;
  if (newToday > 1) {
    insight = `${companyName} is actively hiring ${jobs[0]?.title.split(' ').pop()}s — ${newToday} new roles today!`;
  }

  return {
    company: companyName,
    jobs,
    insight,
    total_openings: jobs.length,
    new_today: newToday,
    checked_at: new Date().toISOString()
  };
}

export function getSalaryTrends(roleTitle: string): any {
  const filtered = JOB_POOL.filter(j => j.title.toLowerCase().includes(roleTitle.toLowerCase()));
  if (filtered.length === 0) return { error: "No data for this role" };

  const salaries = filtered.map(j => j.salary_max).sort((a, b) => a - b);
  const avg = salaries.reduce((a, b) => a + b, 0) / salaries.length;
  
  const getPercentile = (p: number) => salaries[Math.floor((p / 100) * (salaries.length - 1))];

  return {
    role: roleTitle,
    average: Math.round(avg),
    percentiles: {
      p25: getPercentile(25),
      p50: getPercentile(50),
      p75: getPercentile(75),
      p90: getPercentile(90)
    },
    trend: Math.random() > 0.5 ? 'up' : 'down',
    top_payers: [...new Set(filtered.sort((a, b) => b.salary_max - a.salary_max).slice(0, 3).map(j => j.company))],
    insight: `Market demand for ${roleTitle} is ${avg > 160000 ? 'very high' : 'stable'}.`
  };
}

export function getFreelanceJobs(): any {
  const jobs = JOB_POOL.filter(j => j.type === 'contract' || j.type === 'freelance');
  return {
    jobs: jobs.map(j => ({
      ...j,
      is_high_value: (j.hourly_rate || 0) > 130
    })),
    total: jobs.length,
    checked_at: new Date().toISOString()
  };
}

export function searchJobs(params: { keywords?: string[]; min_salary?: number; skills_min?: number }): any {
  // Simulating rotation: add 2-3 jobs every few hours
  const hours = Math.floor((Date.now() - startTime) / 3600000);
  const rotationCount = Math.floor(hours / 3) * 2;
  
  let results = JOB_POOL.filter(j => {
    const keywordMatch = !params.keywords || params.keywords.some(k => j.title.toLowerCase().includes(k.toLowerCase()) || j.keywords.includes(k.toLowerCase()));
    const salaryMatch = !params.min_salary || j.salary_min >= params.min_salary;
    const skillsMatch = !params.skills_min || j.skills_score >= params.skills_min;
    return keywordMatch && salaryMatch && skillsMatch;
  });

  return {
    results: results.slice(0, 20),
    total: results.length,
    checked_at: new Date().toISOString()
  };
}
