import express, { Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { stellarPaywall } from '../../../backend/src/middleware/stellar-paywall.js';
import { getFinanceData } from './mock-data.js';

dotenv.config();

const app = express();
const PORT = 3006;

app.use(cors());
app.use(express.json());

// Configuration - Use the proven recipient address GDKU...
const RECIPIENT_ADDRESS = process.env.SERVICE_OPERATOR_PUBLIC || 'GDKU2DY4TTRRSQ6BBFYTDV2GEWREHCIDUM5FFXLIF66PDOO3HYJ2YZIF';
const USDC_CONTRACT = 'CBIELTK6YBZJU5UP2WWQEUCYKLPU6AUNZ2BQ4WWFEIE3USCIHMXQDAMA';
const SOROBAN_RPC_URL = 'https://soroban-testnet.stellar.org';

/**
 * POST /api/stocks
 * Protected by 0.004 USDC (40,000 stroops)
 */
app.post('/api/stocks', stellarPaywall({
  priceStroops: 40000,
  recipientAddress: RECIPIENT_ADDRESS,
  usdcContractId: USDC_CONTRACT,
  rpcUrl: SOROBAN_RPC_URL
}), (req: Request, res: Response) => {
  const { mode = 'quote', symbols, positions } = req.body;
  
  try {
    const data = getFinanceData(symbols);

    switch (mode) {
      case 'portfolio':
        if (!positions || !Array.isArray(positions)) return res.status(400).json({ error: "Missing positions array" });
        
        let totalValue = 0;
        let totalCost = 0;
        const breakdown = positions.map((p: any) => {
          const s = data.stocks.find((st: any) => st.symbol === p.symbol.toUpperCase());
          if (!s) return { symbol: p.symbol, error: "Not found" };
          const value = p.shares * s.price;
          const cost = p.shares * p.average_cost;
          totalValue += value;
          totalCost += cost;
          return {
            symbol: s.symbol,
            shares: p.shares,
            current_value: value,
            gain_loss: value - cost,
            gain_loss_percent: ((value - cost) / cost) * 100
          };
        });

        return res.json({
          total_value: totalValue,
          total_gain_loss: totalValue - totalCost,
          today_change_percent: data.indices.sp500.change_percent,
          breakdown,
          best_performer: breakdown.sort((a, b) => (b.gain_loss_percent || 0) - (a.gain_loss_percent || 0))[0]?.symbol,
          worst_performer: breakdown.sort((a, b) => (a.gain_loss_percent || 0) - (b.gain_loss_percent || 0))[0]?.symbol,
          checked_at: new Date().toISOString()
        });

      case 'events':
        return res.json({
          events: data.stocks.map((s: any) => ({
            symbol: s.symbol,
            upcoming_earnings: s.event?.includes('Surprise') ? 'Next Week' : 'TBD',
            recent_insider_trades: Math.random() > 0.7 ? 'CEO Buy' : 'None',
            analyst_rating: s.event?.includes('Analyst') ? s.event.split(': ')[1] : 'Hold'
          })),
          checked_at: new Date().toISOString()
        });

      case 'market':
        return res.json({
          indices: data.indices,
          market_status: data.market_status,
          checked_at: new Date().toISOString()
        });

      case 'quote':
      default:
        return res.json({
          quotes: data.stocks.map((s: any) => ({
            symbol: s.symbol,
            price: s.price,
            change: s.change_24h,
            change_percent: s.change_percent_24h,
            volume: s.volume_24h,
            high_52w: s.high_52w,
            low_52w: s.low_52w
          })),
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
  res.json({ service: "finance-data", status: "ok" });
});

app.listen(PORT, () => {
  console.log(`Finance Data Service listening on port ${PORT}`);
  console.log(`Direct Stellar Verification Enabled - Recipient: ${RECIPIENT_ADDRESS}`);
});
