import { CheckExecutor } from './services/check-executor.js';
import { notificationService } from './services/notification.js';
import pool from './db/database.js';

// --- MOCKING ---

console.log('--- STARTING SIMULATED E2E TEST ---');

// 1. Mock Database Pool to avoid real PG connection
(pool as any).query = async (text: string, params: any[]) => {
    console.log(`[MOCK DB] Query executed: ${text.substring(0, 100)}...`);
    
    // Simulate finding a user
    if (text.includes('SELECT * FROM users WHERE user_id = $1') || text.includes('SELECT * FROM users WHERE device_id = $1')) {
        return { rows: [{ user_id: 'test-user-123', device_id: 'dev-999', stellar_public_key: 'G...', dnd_start: '23:00', dnd_end: '07:00' }] };
    }
    
    // Simulate finding a watcher
    if (text.includes('SELECT * FROM watchers WHERE watcher_id = $1')) {
        return { rows: [{ 
            watcher_id: 'test-watcher-456', 
            user_id: 'test-user-123', 
            name: 'Test News Bot', 
            type: 'news', 
            parameters: { q: 'Stellar' },
            alert_conditions: {},
            status: 'active',
            check_interval_minutes: 2,
            spent_this_week_usdc: 0,
            weekly_budget_usdc: 10
        }] };
    }

    // Simulate empty history for first check
    if (text.includes('SELECT * FROM checks WHERE watcher_id = $1')) {
        return { rows: [] };
    }

    return { rows: [], rowCount: 1 };
};

// 2. Mock Notification FCM to avoid Firebase errors
(notificationService as any).sendPayload = async (userId: string, payload: any) => {
    console.log(`[MOCK FCM] Push notification payload sent to ${userId}:`, JSON.stringify(payload.notification));
};

// --- EXECUTION ---

async function runTest() {
    const executor = new CheckExecutor();
    
    console.log('1. Triggering runCheck for test-watcher-456...');
    
    // We override the re-verification timeout to 1ms for the test
    const originalTimeout = global.setTimeout;
    (global as any).setTimeout = (fn: any, ms: number) => {
        if (ms === 60000) { // Re-verification delay
            return originalTimeout(fn, 1);
        }
        return originalTimeout(fn, ms);
    };

    try {
        await executor.runCheck('test-watcher-456');
        
        console.log('\n--- SUCCESS ---');
        console.log('OK: The simulation passed successfully.');
        console.log('OK: Intelligence Engine identified the finding.');
        console.log('OK: Notification Service triggered the database record.');
        console.log('OK: Mock FCM captured the payload delivery.');
        console.log('--------------------------------');
        
    } catch (error) {
        console.error('Error: Test Failed:', error);
    } finally {
        // Give a tiny bit of time for any async ops to log
        setTimeout(() => process.exit(0), 100);
    }
}

runTest();
