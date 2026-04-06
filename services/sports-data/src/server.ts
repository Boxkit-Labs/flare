import express, { Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { stellarPaywall } from '../../../backend/src/middleware/stellar-paywall.js';
import { getTicketData, getSportsData, getDiscoveryData } from './mock-data.js';

dotenv.config();

const app = express();
const PORT = 3008;

app.use(cors());
app.use(express.json());

// Configuration - Use the proven recipient address GDKU...
const RECIPIENT_ADDRESS = process.env.SERVICE_OPERATOR_PUBLIC || 'GDKU2DY4TTRRSQ6BBFYTDV2GEWREHCIDUM5FFXLIF66PDOO3HYJ2YZIF';
const USDC_CONTRACT = 'CBIELTK6YBZJU5UP2WWQEUCYKLPU6AUNZ2BQ4WWFEIE3USCIHMXQDAMA';
const SOROBAN_RPC_URL = 'https://soroban-testnet.stellar.org';

/**
 * POST /api/sports
 * Protected by 0.005 USDC (50,000 stroops)
 */
app.post('/api/sports', stellarPaywall({
  priceStroops: 50000,
  recipientAddress: RECIPIENT_ADDRESS,
  usdcContractId: USDC_CONTRACT,
  rpcUrl: SOROBAN_RPC_URL
}), (req: Request, res: Response) => {
  const { mode = 'tickets', query } = req.body;

  try {
    switch (mode) {
      case 'scores':
        return res.json(getSportsData());
      
      case 'discovery':
        return res.json(getDiscoveryData());
      
      case 'tickets':
      default:
        return res.json(getTicketData(query));
    }
  } catch (e: any) {
    res.status(500).json({ error: e.message });
  }
});

/**
 * GET /health
 */
app.get('/health', (req: Request, res: Response) => {
  res.json({ service: "sports-data", status: "ok" });
});

app.listen(PORT, () => {
  console.log(`Sports & Events Data Service listening on port ${PORT}`);
  console.log(`Direct Stellar Verification Enabled - Recipient: ${RECIPIENT_ADDRESS}`);
});
