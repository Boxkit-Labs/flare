import cron from 'node-cron';
import { getActiveWatchers, getWatcherById, updateWatcher, getAllUsers, getTodayBriefing } from '../db/queries.js';
import { WatcherRow } from '../types.js';
import { CheckExecutor } from './check-executor.js';
import { briefingGenerator } from './briefing-generator.js';

export class SchedulerService {
  private activeJobs: Map<string, NodeJS.Timeout>;
  public isRunning: boolean;
  private checkExecutor: CheckExecutor;

  constructor(checkExecutor: CheckExecutor) {
    this.activeJobs = new Map();
    this.isRunning = false;
    this.checkExecutor = checkExecutor;
  }

  async start(): Promise<void> {
    if (this.isRunning) return;

    // Load active watchers from SQLite
    const watchers = getActiveWatchers();
    
    for (const watcher of watchers) {
      this.scheduleWatcher(watcher);
    }
    
    this.isRunning = true;
    console.log(`Scheduler started with ${watchers.length} active watchers.`);

    // Initialize Midnight Budget Reset Cron
    this.initWeeklyBudgetCron();

    // Initialize 15-minute Morning Briefing Cron
    this.initBriefingCron();
  }

  scheduleWatcher(watcher: WatcherRow): void {
    if (this.activeJobs.has(watcher.watcher_id)) {
      this.removeWatcher(watcher.watcher_id);
    }

    // Determine initial delay
    let delay = 0;
    if (watcher.next_check_at) {
      const nextTime = new Date(watcher.next_check_at).getTime();
      const now = Date.now();
      delay = Math.max(0, nextTime - now);
    }

    const intervalMs = (watcher.check_interval_minutes || 60) * 60 * 1000;

    // Set initial timeout
    const timeoutId = setTimeout(async () => {
      await this.executeScheduledCheck(watcher.watcher_id, intervalMs);
    }, delay);

    this.activeJobs.set(watcher.watcher_id, timeoutId);
    console.log(`Scheduled ${watcher.name} — next check in ${delay}ms, interval ${watcher.check_interval_minutes}min.`);
  }

  async executeScheduledCheck(watcherId: string, intervalMs: number): Promise<void> {
    // 1. Run the actual blockchain/fetch logic
    await this.checkExecutor.runCheck(watcherId);

    // 2. Clear current job from map as it just executed
    this.activeJobs.delete(watcherId);

    if (!this.isRunning) return; // Scheduler was stopped mid-execution

    // 3. Reload watcher state to determine recurring continuation
    const updatedWatcher = getWatcherById(watcherId) as WatcherRow;

    if (!updatedWatcher) {
      console.log(`Watcher ${watcherId} no longer exists. Unscheduled.`);
      return;
    }

    if (updatedWatcher.status !== 'active') {
      console.log(`Watcher ${updatedWatcher.name} paused: ${updatedWatcher.status} (Reason: ${updatedWatcher.error_message || 'Budget/Manual'})`);
      return; // Do not reschedule
    }

    // 4. Schedule the recurring interval execution if it's still active
    const nextExecution = async () => {
       await this.executeScheduledCheck(watcherId, intervalMs);
    };

    const newTimeout = setTimeout(nextExecution, intervalMs);
    this.activeJobs.set(watcherId, newTimeout);
  }

  addWatcher(watcher: WatcherRow): void {
    if (watcher.status === 'active') {
      this.scheduleWatcher(watcher);
      console.log(`Added new watcher to scheduler: ${watcher.name}`);
    }
  }

  removeWatcher(watcherId: string): void {
    const job = this.activeJobs.get(watcherId);
    if (job) {
      clearTimeout(job);
      this.activeJobs.delete(watcherId);
      console.log(`Removed watcher from scheduler: ${watcherId}`);
    }
  }

  rescheduleWatcher(watcher: WatcherRow): void {
    this.removeWatcher(watcher.watcher_id);
    this.scheduleWatcher(watcher);
  }

  stop(): void {
    for (const [_, timeoutId] of this.activeJobs.entries()) {
      clearTimeout(timeoutId);
    }
    this.activeJobs.clear();
    this.isRunning = false;
    console.log('Scheduler stopped.');
  }

  getStatus(): { running: boolean; activeWatchers: number; watcherIds: string[] } {
    return {
      running: this.isRunning,
      activeWatchers: this.activeJobs.size,
      watcherIds: Array.from(this.activeJobs.keys())
    };
  }

  private initWeeklyBudgetCron(): void {
    // Runs at midnight (00:00) UTC every day
    cron.schedule('0 0 * * *', () => {
       console.log('Running daily midnight maintenance job for Watchers...');
       
       const limitTimestamp = new Date();
       limitTimestamp.setDate(limitTimestamp.getDate() - 7); // Exactly 7 days ago

       // Note: To be more efficient we could select just needed ones in SQL,
       // but since we need to examine them here, we do it in memory.
       // Easiest is to select active and paused_budget watchers to reset.
       const db = require('../db/database.js').default;
       
       try {
         // SQLite transaction for safety
         const runReset = db.transaction(() => {
            const updatableWatchers = db.prepare(`SELECT * FROM watchers WHERE status IN ('active', 'paused_budget')`).all();
            
            for (const row of updatableWatchers) {
                if (!row.week_start) continue;

                const weekStartDate = new Date(row.week_start);
                
                // If the week start is older than 7 days, we reset it
                if (weekStartDate <= limitTimestamp) {
                   const nowStr = new Date().toISOString();
                   const updates: any = {
                       spent_this_week_usdc: 0,
                       week_start: nowStr
                   };

                   // Reactivate if it was paused exclusively for budget
                   if (row.status === 'paused_budget') {
                       updates.status = 'active';
                   }

                   // Note: this uses the centralized updateWatcher function to handle JSON correctly
                   updateWatcher(row.watcher_id, updates);
                   
                   // If we just reactivated it, kick off scheduling
                   if (row.status === 'paused_budget' && this.isRunning) {
                      const reactivated = getWatcherById(row.watcher_id);
                      if(reactivated) this.scheduleWatcher(reactivated);
                   }
                }
            }
         });
         
         runReset();
         console.log('Daily maintenance complete.');

       } catch (err) {
         console.error('Error during daily cron budget reset:', err);
       }
       
    }, {
      timezone: "UTC"
    });
  }

  private initBriefingCron(): void {
    cron.schedule('*/15 * * * *', async () => {
        console.log('Running 15-minute check for Morning Briefings...');
        try {
            const users = getAllUsers() as any[];
            for (const user of users) {
                if (!user.briefing_time || !user.timezone) continue;

                // Format current time in user's timezone HH:MM
                const userTimeStr = new Date().toLocaleTimeString('en-US', { 
                    timeZone: user.timezone, 
                    hour12: false, 
                    hour: '2-digit', 
                    minute: '2-digit' 
                });

                // e.g. "07:00"
                if (userTimeStr === user.briefing_time) {
                    const existingBriefing = getTodayBriefing(user.user_id);
                    if (!existingBriefing) {
                        console.log(`Generating morning briefing for user: ${user.user_id}`);
                        await briefingGenerator.generateBriefing(user.user_id);
                    }
                }
            }
        } catch (err) {
            console.error('Error during briefing cron execution:', err);
        }
    });
  }
}
