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

const RECIPIENT_ADDRESS = process.env.SERVICE_OPERATOR_PUBLIC || 'GDKU2DY4TTRRSQ6BBFYTDV2GEWREHCIDUM5FFXLIF66PDOO3HYJ2YZIF';
const USDC_CONTRACT = 'CBIELTK6YBZJU5UP2WWQEUCYKLPU6AUNZ2BQ4WWFEIE3USCIHMXQDAMA';
const SOROBAN_RPC_URL = process.env.SOROBAN_RPC_URL || 'https://soroban-testnet.stellar.org';

router.post('/flight/api/flights', stellarPaywall({
    priceStroops: 80000,
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

router.get('/crypto/api/crypto', stellarPaywall({
    priceStroops: 50000,
    recipientAddress: RECIPIENT_ADDRESS,
    usdcContractId: USDC_CONTRACT,
    rpcUrl: SOROBAN_RPC_URL
}), (req: Request, res: Response) => {
    res.json(getCryptoData());
});

router.get('/news/api/news', stellarPaywall({
    priceStroops: 30000,
    recipientAddress: RECIPIENT_ADDRESS,
    usdcContractId: USDC_CONTRACT,
    rpcUrl: SOROBAN_RPC_URL
}), (req: Request, res: Response) => {
    res.json(getNewsAlerts());
});

router.post('/product/api/products', stellarPaywall({
    priceStroops: 40000,
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

router.post('/job/api/jobs', stellarPaywall({
    priceStroops: 60000,
    recipientAddress: RECIPIENT_ADDRESS,
    usdcContractId: USDC_CONTRACT,
    rpcUrl: SOROBAN_RPC_URL
}), (req: Request, res: Response) => {
    const role = req.body.role || (req.body.keywords && req.body.keywords[0]) || 'Developer';
    res.json(getJobPostings(role));
});

router.get('/stocks/api/stocks', stellarPaywall({
    priceStroops: 35000,
    recipientAddress: RECIPIENT_ADDRESS,
    usdcContractId: USDC_CONTRACT,
    rpcUrl: SOROBAN_RPC_URL
}), (req: Request, res: Response) => {
    const symbol = req.query.symbol as string;
    res.json(getStockData(symbol));
});

router.get('/realestate/api/realestate', stellarPaywall({
    priceStroops: 90000,
    recipientAddress: RECIPIENT_ADDRESS,
    usdcContractId: USDC_CONTRACT,
    rpcUrl: SOROBAN_RPC_URL
}), (req: Request, res: Response) => {
    const neighborhood = req.query.neighborhood as string;
    res.json(getRealEstateData(neighborhood));
});

router.get('/sports/api/sports', stellarPaywall({
    priceStroops: 45000,
    recipientAddress: RECIPIENT_ADDRESS,
    usdcContractId: USDC_CONTRACT,
    rpcUrl: SOROBAN_RPC_URL
}), (req: Request, res: Response) => {
    const team = req.query.team as string;
    res.json(getSportsData(team));
});

export default router;
