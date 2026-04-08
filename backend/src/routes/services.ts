import express, { Request, Response } from 'express';
import { stellarPaywall } from '../middleware/stellar-paywall.js';
import { 
    getFlightPrice, 
    getCryptoData, 
    getNewsAlerts, 
    getJobPostings, 
    getProductPrices,
    getStockData,
    getRealEstateData,
    getSportsData
} from '../services/mock-data.js';

const router = express.Router();

// Configuration from environment
const RECIPIENT_ADDRESS = process.env.SERVICE_OPERATOR_PUBLIC || 'GDKU2DY4TTRRSQ6BBFYTDV2GEWREHCIDUM5FFXLIF66PDOO3HYJ2YZIF';
const USDC_CONTRACT = 'CBIELTK6YBZJU5UP2WWQEUCYKLPU6AUNZ2BQ4WWFEIE3USCIHMXQDAMA';
const SOROBAN_RPC_URL = process.env.SOROBAN_RPC_URL || 'https://soroban-testnet.stellar.org';

/**
 * 1. Flight Data Service
 */
router.post('/flight/api/flights', stellarPaywall({
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
 */
router.get('/crypto/api/crypto', stellarPaywall({
    priceStroops: 50000, // 0.005 USDC
    recipientAddress: RECIPIENT_ADDRESS,
    usdcContractId: USDC_CONTRACT,
    rpcUrl: SOROBAN_RPC_URL
}), (req: Request, res: Response) => {
    res.json(getCryptoData());
});

/**
 * 3. News Data Service
 */
router.get('/news/api/news', stellarPaywall({
    priceStroops: 30000, // 0.003 USDC
    recipientAddress: RECIPIENT_ADDRESS,
    usdcContractId: USDC_CONTRACT,
    rpcUrl: SOROBAN_RPC_URL
}), (req: Request, res: Response) => {
    res.json(getNewsAlerts());
});

/**
 * 4. Product Data Service
 */
router.post('/product/api/products', stellarPaywall({
    priceStroops: 40000, // 0.004 USDC
    recipientAddress: RECIPIENT_ADDRESS,
    usdcContractId: USDC_CONTRACT,
    rpcUrl: SOROBAN_RPC_URL
}), (req: Request, res: Response) => {
    const name = req.body.product_name || req.body.name;
    if (!name) {
        res.status(400).json({ error: "Missing product name" });
        return;
    }
    res.json(getProductPrices(name));
});

/**
 * 5. Job Data Service
 */
router.post('/job/api/jobs', stellarPaywall({
    priceStroops: 60000, // 0.006 USDC
    recipientAddress: RECIPIENT_ADDRESS,
    usdcContractId: USDC_CONTRACT,
    rpcUrl: SOROBAN_RPC_URL
}), (req: Request, res: Response) => {
    const role = req.body.role || (req.body.keywords && req.body.keywords[0]) || 'Developer';
    res.json(getJobPostings(role));
});

/**
 * 6. Stock Data Service
 */
router.get('/stocks/api/stocks', stellarPaywall({
    priceStroops: 35000, // 0.0035 USDC
    recipientAddress: RECIPIENT_ADDRESS,
    usdcContractId: USDC_CONTRACT,
    rpcUrl: SOROBAN_RPC_URL
}), (req: Request, res: Response) => {
    const symbol = req.query.symbol as string;
    res.json(getStockData(symbol));
});

/**
 * 7. Real Estate Data Service
 */
router.get('/realestate/api/realestate', stellarPaywall({
    priceStroops: 90000, // 0.009 USDC
    recipientAddress: RECIPIENT_ADDRESS,
    usdcContractId: USDC_CONTRACT,
    rpcUrl: SOROBAN_RPC_URL
}), (req: Request, res: Response) => {
    const neighborhood = req.query.neighborhood as string;
    res.json(getRealEstateData(neighborhood));
});

/**
 * 8. Sports Data Service
 */
router.get('/sports/api/sports', stellarPaywall({
    priceStroops: 45000, // 0.0045 USDC
    recipientAddress: RECIPIENT_ADDRESS,
    usdcContractId: USDC_CONTRACT,
    rpcUrl: SOROBAN_RPC_URL
}), (req: Request, res: Response) => {
    const team = req.query.team as string;
    res.json(getSportsData(team));
});

export default router;
