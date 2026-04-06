import express, { Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { stellarPaywall } from './middleware/stellar-paywall.js';
import { 
    getFlightPrice, 
    getCryptoData, 
    getNewsAlerts, 
    getJobPostings, 
    getProductPrices,
    getStockData,
    getRealEstateData,
    getSportsData
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
 * Health Check (Free)
 */
app.get('/health', (req: Request, res: Response) => {
    res.json({ status: 'ok', service: 'flare-combined-services', timestamp: new Date().toISOString() });
});

/**
 * 1. Flight Data Service (0.008 USDC)
 */
app.post('/flight/api/flights', stellarPaywall({
    priceStroops: 80000,
    recipientAddress: RECIPIENT_ADDRESS,
    usdcContractId: USDC_CONTRACT,
    rpcUrl: SOROBAN_RPC_URL
}), (req: Request, res: Response) => {
    const { origin, destination, filters } = req.body;
    res.json(getFlightPrice(origin || 'JFK', destination || 'LAX', filters));
});

/**
 * 2. Crypto Data Service (0.003 USDC)
 */
app.post('/crypto/api/crypto', stellarPaywall({
    priceStroops: 30000,
    recipientAddress: RECIPIENT_ADDRESS,
    usdcContractId: USDC_CONTRACT,
    rpcUrl: SOROBAN_RPC_URL
}), (req: Request, res: Response) => {
    const { symbols } = req.body;
    res.json(getCryptoData(symbols));
});

/**
 * 3. News Data Service (0.005 USDC)
 */
app.post('/news/api/news', stellarPaywall({
    priceStroops: 50000,
    recipientAddress: RECIPIENT_ADDRESS,
    usdcContractId: USDC_CONTRACT,
    rpcUrl: SOROBAN_RPC_URL
}), (req: Request, res: Response) => {
    const { topic } = req.body;
    res.json(getNewsAlerts(topic));
});

/**
 * 4. Product Data Service (0.006 USDC)
 */
app.post('/product/api/products', stellarPaywall({
    priceStroops: 60000,
    recipientAddress: RECIPIENT_ADDRESS,
    usdcContractId: USDC_CONTRACT,
    rpcUrl: SOROBAN_RPC_URL
}), (req: Request, res: Response) => {
    const { query } = req.body;
    res.json(getProductPrices(query || 'Sony XM5'));
});

/**
 * 5. Job Data Service (0.007 USDC)
 */
app.post('/job/api/jobs', stellarPaywall({
    priceStroops: 70000,
    recipientAddress: RECIPIENT_ADDRESS,
    usdcContractId: USDC_CONTRACT,
    rpcUrl: SOROBAN_RPC_URL
}), (req: Request, res: Response) => {
    const { role } = req.body;
    res.json(getJobPostings(role || 'Flutter Developer'));
});

/**
 * 6. Stocks Data Service (0.004 USDC)
 */
app.post('/stocks/api/stocks', stellarPaywall({
    priceStroops: 40000,
    recipientAddress: RECIPIENT_ADDRESS,
    usdcContractId: USDC_CONTRACT,
    rpcUrl: SOROBAN_RPC_URL
}), (req: Request, res: Response) => {
    const { symbols } = req.body;
    res.json(getStockData(symbols));
});

/**
 * 7. Real Estate Data Service (0.008 USDC)
 */
app.post('/realestate/api/realestate', stellarPaywall({
    priceStroops: 80000,
    recipientAddress: RECIPIENT_ADDRESS,
    usdcContractId: USDC_CONTRACT,
    rpcUrl: SOROBAN_RPC_URL
}), (req: Request, res: Response) => {
    const { city } = req.body;
    res.json(getRealEstateData(city));
});

/**
 * 8. Sports Data Service (0.005 USDC)
 */
app.post('/sports/api/sports', stellarPaywall({
    priceStroops: 50000,
    recipientAddress: RECIPIENT_ADDRESS,
    usdcContractId: USDC_CONTRACT,
    rpcUrl: SOROBAN_RPC_URL
}), (req: Request, res: Response) => {
    const { team } = req.body;
    res.json(getSportsData(team));
});

app.listen(PORT, () => {
    console.log(`Flare Consolidated Services listening on port ${PORT}`);
    console.log(`Recipient: ${RECIPIENT_ADDRESS}`);
});
