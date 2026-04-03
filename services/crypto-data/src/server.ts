import express, { Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { stellarPaywall } from '../../../backend/src/middleware/stellar-paywall.js';
import { getCryptoData } from './mock-data.js';

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
  const { symbols } = req.body;
  if (!symbols || !Array.isArray(symbols)) {
    res.status(400).json({ error: "Missing symbols array" });
    return;
  }

  const allData = getCryptoData();
  
  // Filter by requested symbols
  const filteredPrices: Record<string, number> = {};
  const filteredChanges: Record<string, number> = {};
  const filteredVolumes: Record<string, string> = {};

  symbols.forEach(sym => {
    const s = sym.toUpperCase();
    if (allData.prices[s]) {
      filteredPrices[s] = allData.prices[s];
      filteredChanges[s] = allData.changes_24h[s];
      filteredVolumes[s] = allData.volumes[s];
    }
  });

  res.json({
    prices: filteredPrices,
    changes_24h: filteredChanges,
    volumes: filteredVolumes,
    checked_at: allData.checked_at
  });
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
