import express, { Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { stellarPaywall } from '../../../backend/src/middleware/stellar-paywall.js';
import { getPriceStats, getPortfolioStats, getPairStats, getMarketOverview } from './mock-data.js';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3002;

app.use(cors());
app.use(express.json());

// Configuration - Use the proven recipient address GDKU...
const RECIPIENT_ADDRESS = process.env.SERVICE_OPERATOR_PUBLIC || 'GDKU2DY4TTRRSQ6BBFYTDV2GEWREHCIDUM5FFXLIF66PDOO3HYJ2YZIF';
const USDC_CONTRACT = 'CBIELTK6YBZJU5UP2WWQEUCYKLPU6AUNZ2BQ4WWFEIE3USCIHMXQDAMA';
const SOROBAN_RPC_URL = 'https://soroban-testnet.stellar.org';

/**
 * POST /api/crypto
 * Protected by 0.003 USDC (30,000 stroops)
 */
app.post('/api/crypto', stellarPaywall({
  priceStroops: 30000,
  recipientAddress: RECIPIENT_ADDRESS,
  usdcContractId: USDC_CONTRACT,
  rpcUrl: SOROBAN_RPC_URL
}), (req: Request, res: Response) => {
  const { mode = 'price', symbols, holdings, base, quote } = req.body;

  try {
    switch (mode) {
      case 'portfolio':
        if (!holdings) return res.status(400).json({ error: "Missing holdings for portfolio mode" });
        return res.json(getPortfolioStats(holdings));
      
      case 'pair':
        if (!base || !quote) return res.status(400).json({ error: "Missing base/quote for pair mode" });
        return res.json(getPairStats(base.toUpperCase(), quote.toUpperCase()));
      
      case 'market':
        return res.json(getMarketOverview());
      
      case 'price':
      default:
        if (!symbols || !Array.isArray(symbols)) {
          return res.status(400).json({ error: "Missing symbols array" });
        }
        return res.json({
          prices: getPriceStats(symbols.map(s => s.toUpperCase())),
          checked_at: new Date().toISOString()
        });
    }
  } catch (e: any) {
    res.status(500).json({ error: e.message });
  }
});

/**
 * GET /health
 */
app.get('/health', (req: Request, res: Response) => {
  res.json({ service: "crypto-data", status: "ok" });
});

app.listen(PORT, () => {
  console.log(`Crypto Data Service listening on port ${PORT}`);
  console.log(`Direct Stellar Verification Enabled - Recipient: ${RECIPIENT_ADDRESS}`);
});
