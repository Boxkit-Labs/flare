import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { verify, settle } from 'x402-stellar';
import { getArticlesForQuery } from './mock-data.js';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3003;

app.use(cors());
app.use(express.json());

// Configuration from environment variables
const RECEIVING_ADDRESS = process.env.RECEIVING_ADDRESS || process.env.SERVICE_OPERATOR_PUBLIC;
const NETWORK = process.env.NETWORK || process.env.STELLAR_NETWORK || 'testnet';
const USDC_ASSET = process.env.USDC_ASSET || 'CAS3J7GYCCXGQC3Y7CWA3BTR5VHHGDM7B6N7LTSLXNGLJ7U67C7CC77T'; // Testnet USDC SAC

/**
 * x402 Middleware
 * Following the Stellar pattern from x402-payments skill.
 */
const x402Protector = (amountStroops: string) => {
  return async (req: Request, res: Response, next: NextFunction) => {
    const paymentHeader = req.header('X-PAYMENT');

    // 1. Build the challenge if no payment header
    const challenge = {
      x402Version: 2,
      resource: {
        url: `${req.protocol}://${req.get('host')}${req.originalUrl}`,
        description: "Premium news data access",
        mimeType: "application/json",
      },
      accepts: [{
        scheme: "exact",
        network: NETWORK.includes('testnet') ? "stellar:testnet" : "stellar:pubnet",
        amount: amountStroops,
        payTo: RECEIVING_ADDRESS,
        maxTimeoutSeconds: 300,
        asset: USDC_ASSET,
        extra: { areFeesSponsored: true }
      }]
    };

    if (!paymentHeader) {
      res.status(402).json(challenge);
      return;
    }

    try {
      // 2. Decode and Verify
      const payload = JSON.parse(Buffer.from(paymentHeader, 'base64').toString('utf8'));
      
      console.log(`[X402] Verifying payment for ${req.path}...`);
      const verifyResult = await verify(payload, challenge.accepts[0] as any);
      
      if (!verifyResult.isValid) {
        res.status(401).json({ error: verifyResult.invalidReason || "Payment verification failed" });
        return;
      }

      // 3. Settle
      console.log(`[X402] Settling payment...`);
      const settleResult = await settle(payload, challenge.accepts[0] as any);

      if (!settleResult.success) {
        res.status(502).json({ error: settleResult.errorReason || "Payment settlement failed" });
        return;
      }

      console.log(`[X402] Payment successful: ${settleResult.transaction}`);
      
      // Attach transaction hash to response headers
      res.setHeader('X-STELLAR-TX-HASH', settleResult.transaction || '');
      
      next();
    } catch (err: any) {
      console.error('[X402] Error processing payment:', err);
      res.status(401).json({ error: "Invalid payment format or network error" });
    }
  };
};

/**
 * POST /api/news
 * Protected by 0.005 USDC (50,000 stroops)
 */
app.post('/api/news', x402Protector("50000"), (req: Request, res: Response) => {
  const { keywords, max_results, language } = req.body;
  
  if (!keywords || !Array.isArray(keywords)) {
    res.status(400).json({ error: "Missing or invalid keywords array" });
    return;
  }

  const limit = max_results ? parseInt(max_results.toString()) : 5;
  const result = getArticlesForQuery(keywords, limit);

  res.json({
      ...result,
      language: language || "en"
  });
});

/**
 * GET /health
 */
app.get('/health', (req: Request, res: Response) => {
  res.json({ service: "news-data", status: "ok" });
});

app.listen(PORT, () => {
  console.log(`News Data Service listening on port ${PORT}`);
  console.log(`Target Address: ${RECEIVING_ADDRESS}`);
  console.log(`Network: ${NETWORK}`);
});
