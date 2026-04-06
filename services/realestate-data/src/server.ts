import express, { Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { stellarPaywall } from '../../../backend/src/middleware/stellar-paywall.js';
import { getRealEstateData, getInvestmentAnalysis } from './mock-data.js';

dotenv.config();

const app = express();
const PORT = 3007;

app.use(cors());
app.use(express.json());

// Configuration - Use the proven recipient address GDKU...
const RECIPIENT_ADDRESS = process.env.SERVICE_OPERATOR_PUBLIC || 'GDKU2DY4TTRRSQ6BBFYTDV2GEWREHCIDUM5FFXLIF66PDOO3HYJ2YZIF';
const USDC_CONTRACT = 'CBIELTK6YBZJU5UP2WWQEUCYKLPU6AUNZ2BQ4WWFEIE3USCIHMXQDAMA';
const SOROBAN_RPC_URL = 'https://soroban-testnet.stellar.org';

/**
 * POST /api/realestate
 * Protected by 0.008 USDC (80,000 stroops)
 */
app.post('/api/realestate', stellarPaywall({
  priceStroops: 80000,
  recipientAddress: RECIPIENT_ADDRESS,
  usdcContractId: USDC_CONTRACT,
  rpcUrl: SOROBAN_RPC_URL
}), (req: Request, res: Response) => {
  const { mode = 'rental', city, neighborhood, type, bedrooms, min_price, max_price, amenities } = req.body;

  try {
    switch (mode) {
      case 'investment':
        if (!city) return res.status(400).json({ error: "Missing city for investment analysis" });
        return res.json(getInvestmentAnalysis(city, neighborhood));
      
      case 'purchase':
        return res.json(getRealEstateData({ city, neighborhood, type, bedrooms, min_price, max_price, amenities, is_rental: false }));
      
      case 'rental':
      default:
        return res.json(getRealEstateData({ city, neighborhood, type, bedrooms, min_price, max_price, amenities, is_rental: true }));
    }
  } catch (e: any) {
    res.status(500).json({ error: e.message });
  }
});

/**
 * GET /health
 */
app.get('/health', (req: Request, res: Response) => {
  res.json({ service: "realestate-data", status: "ok" });
});

app.listen(PORT, () => {
  console.log(`Real Estate Data Service listening on port ${PORT}`);
  console.log(`Direct Stellar Verification Enabled - Recipient: ${RECIPIENT_ADDRESS}`);
});
