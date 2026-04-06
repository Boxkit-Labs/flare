import express, { Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { stellarPaywall } from '../../../backend/src/middleware/stellar-paywall.js';
import { getFlightResults } from './mock-data.js';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3001;

app.use(cors());
app.use(express.json());

// Configuration - Use the proven recipient address GDKU...
const RECIPIENT_ADDRESS = process.env.SERVICE_OPERATOR_PUBLIC || 'GDKU2DY4TTRRSQ6BBFYTDV2GEWREHCIDUM5FFXLIF66PDOO3HYJ2YZIF';
const USDC_CONTRACT = 'CBIELTK6YBZJU5UP2WWQEUCYKLPU6AUNZ2BQ4WWFEIE3USCIHMXQDAMA';
const SOROBAN_RPC_URL = 'https://soroban-testnet.stellar.org';

/**
 * POST /api/flights
 * Protected by 0.008 USDC (80,000 stroops)
 */
app.post('/api/flights', stellarPaywall({
  priceStroops: 80000,
  recipientAddress: RECIPIENT_ADDRESS,
  usdcContractId: USDC_CONTRACT,
  rpcUrl: SOROBAN_RPC_URL
}), (req: Request, res: Response) => {
  const { 
    origin, 
    destination, 
    cabin, 
    direct_only, 
    trip_type, 
    date_range, 
    preferred_airlines 
  } = req.body;

  if (!origin || !destination) {
    res.status(400).json({ error: "Missing origin or destination" });
    return;
  }

  const flightData = getFlightResults({
    origin,
    destination,
    cabin,
    direct_only,
    trip_type,
    date_range,
    preferred_airlines
  });
  
  res.json(flightData);
});

/**
 * GET /health
 */
app.get('/health', (req: Request, res: Response) => {
  res.json({ service: "flight-data", status: "ok" });
});

app.listen(PORT, () => {
  console.log(`Flight Data Service listening on port ${PORT}`);
  console.log(`Direct Stellar Verification Enabled - Recipient: ${RECIPIENT_ADDRESS}`);
});
