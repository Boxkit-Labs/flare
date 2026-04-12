import express, { Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import usersRouter from './routes/users.js';
import watchersRouter from './routes/watchers.js';
import findingsRouter from './routes/findings.js';
import briefingsRouter from './routes/briefings.js';
import walletRouter from './routes/wallet.js';
import transactionsRouter from './routes/transactions.js';
import servicesRouter from './routes/services.js';
import notificationsRouter from './routes/notifications.js';

import { CheckExecutor } from './services/check-executor.js';
import { SchedulerService } from './services/scheduler.js';
import { briefingGenerator } from './services/briefing-generator.js';
import { MppService } from './services/mpp-service.js';
import './services/mpp-stream.js';

dotenv.config();

const app = express();
const port = process.env.PORT ? parseInt(process.env.PORT) : 3000;

const executor = new CheckExecutor();
briefingGenerator.setCheckExecutor(executor);
export const scheduler = new SchedulerService(executor);

app.use(cors());
app.use(express.json());
app.use('/api/users', usersRouter);
app.use('/api/watchers', watchersRouter);
app.use('/api/findings', findingsRouter);
app.use('/api/briefings', briefingsRouter);
app.use('/api/wallet', walletRouter);
app.use('/api/transactions', transactionsRouter);
app.use('/api/notifications', notificationsRouter);
app.use('/services', servicesRouter);

import { initializeDatabase } from './db/database.js';

app.get('/health', (req: Request, res: Response) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    version: '0.1.0'
  });
});

async function main() {
  try {

    await initializeDatabase();
    console.log('Database schema initialized');

    await MppService.init();

    app.listen(port, '0.0.0.0', () => {
      console.log(`Server is running on 0.0.0.0:${port}`);

      scheduler.start().catch(e => console.error("Scheduler failed to start:", e));
    });
  } catch (err) {
    console.error('Failed to start:', err);
    process.exit(1);
  }
}

main();
