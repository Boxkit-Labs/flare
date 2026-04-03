import express, { Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { stellarPaywall } from '../../../backend/src/middleware/stellar-paywall.js';
import { searchJobs } from './mock-data.js';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3005;

app.use(cors());
app.use(express.json());

// Configuration - Use the proven recipient address GDKU...
const RECIPIENT_ADDRESS = process.env.SERVICE_OPERATOR_PUBLIC || 'GDKU2DY4TTRRSQ6BBFYTDV2GEWREHCIDUM5FFXLIF66PDOO3HYJ2YZIF';
const USDC_CONTRACT = 'CBIELTK6YBZJU5UP2WWQEUCYKLPU6AUNZ2BQ4WWFEIE3USCIHMXQDAMA';
const SOROBAN_RPC_URL = 'https://soroban-testnet.stellar.org';

/**
 * POST /api/jobs
 * Protected by 0.007 USDC (70,000 stroops)
 */
app.post('/api/jobs', stellarPaywall({
  priceStroops: 70000,
  recipientAddress: RECIPIENT_ADDRESS,
  usdcContractId: USDC_CONTRACT,
  rpcUrl: SOROBAN_RPC_URL
}), (req: Request, res: Response) => {
  const { keywords, location, remote_ok, salary_min } = req.body;
  
  if (!keywords || !Array.isArray(keywords)) {
    res.status(400).json({ error: "Missing or invalid keywords array" });
    return;
  }

  const result = searchJobs(keywords, location, remote_ok, salary_min);
  res.json({
      ...result,
      query_params: { keywords, location, remote_ok, salary_min }
  });
});

/**
 * GET /health
 */
app.get('/health', (req: Request, res: Response) => {
  res.json({ service: "job-data", status: "ok" });
});

app.listen(PORT, () => {
  console.log(`Job Data Service listening on port ${PORT}`);
  console.log(`Direct Stellar Verification Enabled - Recipient: ${RECIPIENT_ADDRESS}`);
});
