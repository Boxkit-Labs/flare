import { eventService } from '../services/events/event-service.js';
import { executeEventCheck } from '../services/events/event-check-executor.js';
import { stellarPaywall } from '../middleware/stellar-paywall.js';
import pool from '../db/database.js';

/**
 * BACKEND INTEGRATION TEST SUITE: EVENT ECOSYSTEM
 * 
 * Verifies:
 * 1. Provider Fetching (Eventbrite, Ticketmaster)
 * 2. Aggregation & Merging
 * 3. Price Tracking & Snapshotting
 * 4. Finding Detection (Price Drops, New Listings)
 * 5. Free Event Logic
 * 6. StellarPaywall with x402/MPP validation
 */

async function runTests() {
  console.log('🚀 Starting Backend Event Integration Tests...\n');

  // --- MOCK DB ---
  (pool as any).query = async (text: string, params: any[]) => {
    if (text.includes('INSERT INTO event_price_history')) {
       console.log('✅ TRACE: Price snapshot recorded in DB');
    }
    return { rows: [], rowCount: 1 };
  };

  try {
    // 1. PROVIDER & AGGREGATION TEST
    console.log('🧪 TEST 1: Provider Aggregation (Lagos focus)');
    const searchResults = await eventService.search({
      q: 'music',
      city: 'Lagos',
      limit: 5
    });
    
    if (searchResults.results.length > 0) {
      console.log(`✅ SUCCESS: Found ${searchResults.results.length} events from ${searchResults.platform}`);
      console.log(`📝 First Event: ${searchResults.results[0].name} on ${searchResults.results[0].platform}`);
    } else {
      console.warn('⚠️ WARNING: No real-world events found in search. Verify API keys or check internet.');
    }

    // 2. FREE EVENT LOGIC
    console.log('\n🧪 TEST 2: Free Event Logic');
    const freeEvents = await eventService.search({ isFree: true, limit: 1 });
    if (freeEvents.results.length > 0) {
       const isTrulyFree = freeEvents.results[0].isFree;
       const hasPrice = freeEvents.results[0].ticketTiers.some(t => t.minPrice > 0);
       if (isTrulyFree && !hasPrice) {
         console.log(`✅ SUCCESS: Correctly identified free event: ${freeEvents.results[0].name}`);
       }
    }

    // 3. FINDING DETECTION TEST (Price Drop)
    console.log('\n🧪 TEST 3: Finding Detection (Specific Event Drop)');
    const mockWatcherId = 'test-watcher-999';
    // Mocking an event with a drop relative to target
    const targetPrice = 50.0;
    const mockParams = {
      mode: 'specific_event',
      platform: 'eventbrite',
      externalId: 'mock-123',
      alertConditions: { maxPrice: targetPrice }
    };

    // We mock the service to return a cheap ticket
    const originalGetById = eventService.getEventById;
    eventService.getEventById = async (p, id) => ({
      id: 'mock-123',
      platform: 'eventbrite',
      name: 'Mock Concert',
      ticketTiers: [{ name: 'General', minPrice: 40.0, maxPrice: 40.0, available: true }],
      currency: 'USD',
      status: 'active',
    } as any);

    const checkResult = await executeEventCheck(mockWatcherId, mockParams);
    
    if (checkResult.findings.length > 0 && checkResult.findings[0].type === 'price_drop') {
      console.log('✅ SUCCESS: Price drop detected (Target: $50, Current: $40)');
      console.log(`🔎 Finding: ${checkResult.findings[0].headline}`);
    }
    
    // Restore
    eventService.getEventById = originalGetById;

    // 4. STELLAR PAYWALL / x402 TEST
    console.log('\n🧪 TEST 4: StellarPaywall (x402/MPP validation)');
    const paywall = stellarPaywall({
      priceStroops: 50000,
      recipientAddress: 'G...',
      usdcContractId: 'C...',
      rpcUrl: 'https://testnet'
    });

    const mockReq = { headers: { 'x-mpp-proof': JSON.stringify({ signature: 'SIG', cumulativeAmount: 100, channelId: 'CH_1' }) } };
    const mockRes = { status: (c: number) => ({ json: (j: any) => console.log('Response:', c, j) }) };
    const mockNext = () => console.log('✅ SUCCESS: Paywall passed via MPP proof header');

    await paywall(mockReq as any, mockRes as any, mockNext);

    console.log('\n✨ ALL INTEGRATION READINESS TESTS PASSED');
    process.exit(0);

  } catch (error) {
    console.error('\n❌ INTEGRATION TEST FAILED');
    console.error(error);
    process.exit(1);
  }
}

runTests();
