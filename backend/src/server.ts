import express, { Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import usersRouter from './routes/users';
import watchersRouter from './routes/watchers';
import findingsRouter from './routes/findings';
import briefingsRouter from './routes/briefings';
import walletRouter from './routes/wallet';
import transactionsRouter from './routes/transactions';

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use('/api/users', usersRouter);
app.use('/api/watchers', watchersRouter);
app.use('/api/findings', findingsRouter);
app.use('/api/briefings', briefingsRouter);
app.use('/api/wallet', walletRouter);
app.use('/api/transactions', transactionsRouter);

app.get('/health', (req: Request, res: Response) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    version: '0.1.0'
  });
});

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});
