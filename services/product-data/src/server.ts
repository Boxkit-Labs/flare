import express, { Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { stellarPaywall } from '../../../backend/src/middleware/stellar-paywall.js';
import { getProductData } from './mock-data.js';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3004;

app.use(cors());
app.use(express.json());

// Configuration - Use the proven recipient address GDKU...
const RECIPIENT_ADDRESS = process.env.SERVICE_OPERATOR_PUBLIC || 'GDKU2DY4TTRRSQ6BBFYTDV2GEWREHCIDUM5FFXLIF66PDOO3HYJ2YZIF';
const USDC_CONTRACT = 'CBIELTK6YBZJU5UP2WWQEUCYKLPU6AUNZ2BQ4WWFEIE3USCIHMXQDAMA';
const SOROBAN_RPC_URL = 'https://soroban-testnet.stellar.org';

/**
 * POST /api/products
 * Protected by 0.006 USDC (60,000 stroops)
 */
app.post('/api/products', stellarPaywall({
  priceStroops: 60000,
  recipientAddress: RECIPIENT_ADDRESS,
  usdcContractId: USDC_CONTRACT,
  rpcUrl: SOROBAN_RPC_URL
}), (req: Request, res: Response) => {
  const { product_name } = req.body;
  if (!product_name) {
    res.status(400).json({ error: "Missing product_name" });
    return;
  }

  const result = getProductData(product_name);
  if (!result) {
    res.status(404).json({ error: "Product not found" });
    return;
  }
  res.json(result);
});

/**
 * GET /health
 */
app.get('/health', (req: Request, res: Response) => {
  res.json({ service: "product-data", status: "ok" });
});

app.listen(PORT, () => {
  console.log(`Product Data Service listening on port ${PORT}`);
  console.log(`Direct Stellar Verification Enabled - Recipient: ${RECIPIENT_ADDRESS}`);
});
