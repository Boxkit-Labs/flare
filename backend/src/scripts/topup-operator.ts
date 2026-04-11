import { Keypair, Horizon, TransactionBuilder, Networks, Asset, Operation } from '@stellar/stellar-sdk';
import 'dotenv/config';

async function topUpOperator() {
    const operatorSecret = process.env.OPERATOR_SECRET;
    if (!operatorSecret) return;

    const kp = Keypair.fromSecret(operatorSecret);
    const pk = kp.publicKey();
    const server = new Horizon.Server('https://horizon-testnet.stellar.org');

    const usdcCode = process.env.USDC_ASSET_CODE || 'USDC';
    const usdcIssuer = process.env.USDC_ISSUER || 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5';
    const usdcAsset = new Asset(usdcCode, usdcIssuer);

    console.log(`Topping up USDC for Operator: ${pk}`);

    try {
        const account = await server.loadAccount(pk);
        const fee = await server.fetchBaseFee();

        // Path Payment Strict Send: Send 100 XLM to self to get as much USDC as possible (min 50)
        const transaction = new TransactionBuilder(account, {
            fee: fee.toString(),
            networkPassphrase: Networks.TESTNET
        })
        .addOperation(Operation.pathPaymentStrictSend({
            sendAsset: Asset.native(),
            sendAmount: '3000', // 3000 XLM
            destination: pk,
            destAsset: usdcAsset,
            destMin: '250', // Minimum 250 USDC
            path: []
        }))
        .setTimeout(30)
        .build();

        transaction.sign(kp);
        const response = await server.submitTransaction(transaction);
        console.log(`Success! TX: ${response.hash}`);
    } catch (e: any) {
        console.error("Top up failed:", e.response?.data?.extras?.result_codes || e.message);
    }
}

topUpOperator();
