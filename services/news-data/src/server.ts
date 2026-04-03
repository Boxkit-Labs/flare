import express, { Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { stellarPaywall } from '../../../backend/src/middleware/stellar-paywall.js';
import { getArticlesForQuery } from './mock-data.js';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3003;

app.use(cors());
app.use(express.json());

// Configuration
const RECIPIENT_ADDRESS = process.env.SERVICE_OPERATOR_PUBLIC || 'GDKU2DY4TTRRSQ6BBFYTDV2GEWREHCIDUM5FFXLIF66PDOO3HYJ2YZIF';
const USDC_CONTRACT = 'CBIELTK6YBZJU5UP2WWQEUCYKLPU6AUNZ2BQ4WWFEIE3USCIHMXQDAMA';
const SOROBAN_RPC_URL = 'https://soroban-testnet.stellar.org';

/**
 * POST /api/news
 * Protected by 0.005 USDC (50,000 stroops)
 */
app.post('/api/news', stellarPaywall({
  priceStroops: 50000,
  recipientAddress: RECIPIENT_ADDRESS,
  usdcContractId: USDC_CONTRACT,
  rpcUrl: SOROBAN_RPC_URL
}), (req: Request, res: Response) => {
  const { keywords, max_results } = req.body;
  
  if (!keywords || !Array.isArray(keywords)) {
    res.status(400).json({ error: "Missing keywords array" });
    return;
  }

  const result = getArticlesForQuery(keywords, max_results || 10);
  res.json(result);
});

/**
 * GET /health
 */
app.get('/health', (req: Request, res: Response) => {
  res.json({ service: "news-data", status: "ok" });
});

app.listen(PORT, () => {
  console.log(`News Data Service listening on port ${PORT}`);
  console.log(`Direct Stellar Verification Enabled`);
});
