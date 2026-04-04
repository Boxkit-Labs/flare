import { FindingDetector } from '../backend/src/services/finding-detector.js';
import { WatcherRow } from '../backend/src/types.js';

async function testFindingDetector() {
  const detector = new FindingDetector();
  console.log('=== Testing Finding Detector ===\n');

  // 1. FLIGHT TEST (Price Drop)
  const flightWatcher: WatcherRow = {
    watcher_id: 'w-1',
    user_id: 'u-1',
    name: 'NYC to LON',
    type: 'flight',
    parameters: { origin: 'JFK', destination: 'LHR' },
    alert_conditions: { price_drop_percent: 10 },
    check_interval_minutes: 60,
    weekly_budget_usdc: 0.5,
    spent_this_week_usdc: 0,
    priority: 'medium',
    status: 'active'
  };

  const flightCheckData = { origin: 'JFK', destination: 'LHR', cheapest_price: 400, airline: 'Delta', departure_date: '2024-12-01' };
  const prevFlightCheckData = { cheapest_price: 500 };

  const flightFinding = await detector.detectFinding(flightWatcher, flightCheckData, prevFlightCheckData, 0.01, 'tx-1');
  console.log('Flight Price Drop Test:');
  console.log(flightFinding ? `  ✅ Result: ${flightFinding.headline}` : '  ❌ Failed: No finding detected');
  console.log(flightFinding ? `  Reasoning: ${flightFinding.agent_reasoning}\n` : '');

  // 2. CRYPTO TEST (Threshold Crossed)
  const cryptoWatcher: WatcherRow = {
    watcher_id: 'w-2',
    user_id: 'u-1',
    name: 'BTC Watch',
    type: 'crypto',
    parameters: {},
    alert_conditions: { price_above: { BTC: 70000 } },
    check_interval_minutes: 60,
    weekly_budget_usdc: 0.5,
    spent_this_week_usdc: 0,
    priority: 'medium',
    status: 'active'
  };

  const cryptoCheckData = { prices: { BTC: 71000, ETH: 3000 }, changes_24h: { BTC: 5, ETH: -2 } };
  const cryptoFinding = await detector.detectFinding(cryptoWatcher, cryptoCheckData, null, 0.01, 'tx-2');
  console.log('Crypto Threshold Test:');
  console.log(cryptoFinding ? `  ✅ Result: ${cryptoFinding.headline}` : '  ❌ Failed: No finding detected');
  console.log(cryptoFinding ? `  Reasoning: ${cryptoFinding.agent_reasoning}\n` : '');

  // 3. NEWS TEST (Min Articles)
  const newsWatcher: WatcherRow = {
    watcher_id: 'w-3',
    user_id: 'u-1',
    name: 'DeepSeek News',
    type: 'news',
    parameters: { keywords: 'DeepSeek' },
    alert_conditions: { min_relevance: 0.8, min_articles: 2 },
    check_interval_minutes: 60,
    weekly_budget_usdc: 0.5,
    spent_this_week_usdc: 0,
    priority: 'medium',
    status: 'active'
  };

  const newsCheckData = {
    articles: [
      { title: 'DeepSeek v3 Released', source: 'Source A', relevance_score: 0.95 },
      { title: 'AI Trends 2025', source: 'Source B', relevance_score: 0.85 },
      { title: 'Weather Report', source: 'Source C', relevance_score: 0.2 }
    ]
  };

  const newsFinding = await detector.detectFinding(newsWatcher, newsCheckData, null, 0.01, 'tx-3');
  console.log('News Relevance Test:');
  console.log(newsFinding ? `  ✅ Result: ${newsFinding.headline}` : '  ❌ Failed: No finding detected');
  console.log(newsFinding ? `  Detail: ${newsFinding.detail}\n` : '');

  // 4. JOB TEST (Min Salary)
  const jobWatcher: WatcherRow = {
    watcher_id: 'w-4',
    user_id: 'u-1',
    name: 'Senior Dev Jobs',
    type: 'job',
    parameters: {},
    alert_conditions: { min_salary: 150000 },
    check_interval_minutes: 60,
    weekly_budget_usdc: 0.5,
    spent_this_week_usdc: 0,
    priority: 'medium',
    status: 'active'
  };

  const jobCheckData = {
    listings: [
      { title: 'Senior Engineer', company: 'Tech Corp', salary: 160000, location: 'Remote' },
      { title: 'Junior Dev', company: 'StartUp', salary: 80000, location: 'NYC' }
    ]
  };

  const jobFinding = await detector.detectFinding(jobWatcher, jobCheckData, null, 0.01, 'tx-4');
  console.log('Job Salary Test:');
  console.log(jobFinding ? `  ✅ Result: ${jobFinding.headline}` : '  ❌ Failed: No finding detected');
  console.log(jobFinding ? `  Detail: ${jobFinding.detail}\n` : '');

  console.log('=== All Tests Conducted ===');
}

testFindingDetector().catch(console.error);
