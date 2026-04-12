import express from 'express';
import { Keypair } from '@stellar/stellar-sdk';
import dotenv from 'dotenv';
import path from 'path';
import { stellarPaywall } from '../../middleware/stellar-paywall.js';

dotenv.config({ path: path.join(process.cwd(), '.env') });
dotenv.config({ path: path.join(process.cwd(), '.env.wallets') });

const app = express();
app.use(express.json());

const operatorSecret = process.env.OPERATOR_SECRET;
if (!operatorSecret) {
    throw new Error('OPERATOR_SECRET must be set in backend/.env');
}
const operatorKeypair = Keypair.fromSecret(operatorSecret);
const operatorPublic = operatorKeypair.publicKey();

const USDC_CONTRACT = 'CBIELTK6YBZJU5UP2WWQEUCYKLPU6AUNZ2BQ4WWFEIE3USCIHMXQDAMA';
const SOROBAN_RPC_URL = process.env.SOROBAN_RPC_URL || 'https://soroban-testnet.stellar.org';

app.use(
  '/test',
  stellarPaywall({
    priceStroops: 1000,
    recipientAddress: operatorPublic,
    usdcContractId: `stellar:${USDC_CONTRACT}`,
    rpcUrl: SOROBAN_RPC_URL
  })
);

app.get('/test', (req, res) => {

    res.json({
        message: "Payment successful!",
        timestamp: Date.now(),
        txHash: (req as any).stellarTxHash,
        explorerUrl: `https://stellar.expert/explorer/testnet/tx/${(req as any).stellarTxHash}`
    });
});

app.get('/health', (_req, res) => {
    res.json({ status: 'ok', payTo: operatorPublic });
});

const port = process.env.TEST_SERVICE_PORT || 3001;

const keepAlive = setInterval(() => {}, 1000 * 60 * 60);

const server = app.listen(port, () => {
    console.log(`[Stellar Paywall Test Service] Listening on port ${port}`);
    console.log(`[Stellar Paywall Test Service] Pay-to Address: ${operatorPublic}`);
    console.log(`[Stellar Paywall Test Service] Asset: ${USDC_CONTRACT}`);
    console.log(`[Stellar Paywall Test Service] Soroban RPC: ${SOROBAN_RPC_URL}`);
});

server.on('error', (err: any) => {
    if (err.code === 'EADDRINUSE') {
        console.error(`Error: Port ${port} is already in use.`);
    } else {
        console.error('Server error:', err.message);
    }
    clearInterval(keepAlive);
    process.exit(1);
});
