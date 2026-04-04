import express, { Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { stellarPaywall } from './middleware/stellar-paywall.js';
import { 
    getFlightPrice, 
    getCryptoData, 
    getNewsAlerts, 
    getJobPostings, 
    getProductPrices 
} from './mock-data.js';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3001;

app.use(cors());
app.use(express.json());

// Configuration
const RECIPIENT_ADDRESS = process.env.SERVICE_OPERATOR_PUBLIC || 'GDKU2DY4TTRRSQ6BBFYTDV2GEWREHCIDUM5FFXLIF66PDOO3HYJ2YZIF';
const USDC_CONTRACT = 'CBIELTK6YBZJU5UP2WWQEUCYKLPU6AUNZ2BQ4WWFEIE3USCIHMXQDAMA';
const SOROBAN_RPC_URL = 'https://soroban-testnet.stellar.org';

/**
 * Health Check
 */
app.get('/health', (req: Request, res: Response) => {
    res.json({ status: 'ok', service: 'flare-combined-services', timestamp: new Date().toISOString() });
});

/**
 * 1. Flight Data Service
 * /flight/api/flights
 */
app.post('/flight/api/flights', stellarPaywall({
    priceStroops: 80000, // 0.008 USDC
    recipientAddress: RECIPIENT_ADDRESS,
    usdcContractId: USDC_CONTRACT,
    rpcUrl: SOROBAN_RPC_URL
}), (req: Request, res: Response) => {
    const { origin, destination } = req.body;
    if (!origin || !destination) {
        res.status(400).json({ error: "Missing origin or destination" });
        return;
    }
    res.json(getFlightPrice(origin.toUpperCase(), destination.toUpperCase()));
});

/**
 * 2. Crypto Data Service
 * /crypto/api/crypto
 */
app.get('/crypto/api/crypto', stellarPaywall({
    priceStroops: 50000, // 0.005 USDC
    recipientAddress: RECIPIENT_ADDRESS,
    usdcContractId: USDC_CONTRACT,
    rpcUrl: SOROBAN_RPC_URL
}), (req: Request, res: Response) => {
    res.json(getCryptoData());
});

/**
 * 3. News Data Service
 * /news/api/news
 */
app.get('/news/api/news', stellarPaywall({
    priceStroops: 30000, // 0.003 USDC
    recipientAddress: RECIPIENT_ADDRESS,
    usdcContractId: USDC_CONTRACT,
    rpcUrl: SOROBAN_RPC_URL
}), (req: Request, res: Response) => {
    res.json(getNewsAlerts());
});

/**
 * 4. Product Data Service
 * /product/api/products
 */
app.post('/product/api/products', stellarPaywall({
    priceStroops: 40000, // 0.004 USDC
    recipientAddress: RECIPIENT_ADDRESS,
    usdcContractId: USDC_CONTRACT,
    rpcUrl: SOROBAN_RPC_URL
}), (req: Request, res: Response) => {
    const { name } = req.body;
    if (!name) {
        res.status(400).json({ error: "Missing product name" });
        return;
    }
    res.json(getProductPrices(name));
});

/**
 * 5. Job Data Service
 * /job/api/jobs
 */
app.post('/job/api/jobs', stellarPaywall({
    priceStroops: 60000, // 0.006 USDC
    recipientAddress: RECIPIENT_ADDRESS,
    usdcContractId: USDC_CONTRACT,
    rpcUrl: SOROBAN_RPC_URL
}), (req: Request, res: Response) => {
    const { role } = req.body;
    if (!role) {
        res.status(400).json({ error: "Missing role" });
        return;
    }
    res.json(getJobPostings(role));
});

app.listen(PORT, () => {
    console.log(`Flare Combined Services listening on port ${PORT}`);
    console.log(`Recipient: ${RECIPIENT_ADDRESS}`);
});
