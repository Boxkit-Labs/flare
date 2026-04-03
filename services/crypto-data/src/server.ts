import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { verify, settle } from 'x402-stellar';
import { getCryptoData } from './mock-data.js';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3002;

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
        description: "Premium crypto data access",
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
 * POST /api/crypto
 * Protected by 0.003 USDC (30,000 stroops)
 */
app.post('/api/crypto', x402Protector("30000"), (req: Request, res: Response) => {
  const { symbols, base_currency } = req.body;
  if (!symbols || !Array.isArray(symbols)) {
    res.status(400).json({ error: "Missing or invalid symbols array" });
    return;
  }

  const allData = getCryptoData();
  
  // Filter for requested symbols if provided, or return all
  const filteredPrices: Record<string, number> = {};
  const filteredChanges: Record<string, number> = {};
  const filteredVolumes: Record<string, string> = {};
  
  symbols.forEach(s => {
      const upper = s.toUpperCase();
      if (allData.prices[upper]) {
          filteredPrices[upper] = allData.prices[upper];
          filteredChanges[upper] = allData.changes_24h[upper];
          filteredVolumes[upper] = allData.volumes[upper];
      }
  });

  res.json({
      prices: filteredPrices,
      changes_24h: filteredChanges,
      volumes: filteredVolumes,
      spike_detected: allData.spike_detected,
      spike_coin: allData.spike_coin,
      base_currency: base_currency || "USD",
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
  console.log(`Target Address: ${RECEIVING_ADDRESS}`);
  console.log(`Network: ${NETWORK}`);
});
