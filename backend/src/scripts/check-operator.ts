import { Keypair, Horizon, Asset } from '@stellar/stellar-sdk';
import 'dotenv/config';

async function checkOperator() {
    const operatorSecret = process.env.OPERATOR_SECRET;
    if (!operatorSecret) {
        console.error("No OPERATOR_SECRET in .env");
        process.exit(1);
    }

    const kp = Keypair.fromSecret(operatorSecret);
    const pk = kp.publicKey();
    console.log(`Operator Public Key: ${pk}`);

    const server = new Horizon.Server('https://horizon-testnet.stellar.org');
    try {
        const account = await server.loadAccount(pk);
        console.log("Balances:");
        account.balances.forEach(b => {
             const asset = b.asset_type === 'native' ? 'XLM' : (b as any).asset_code;
             console.log(` - ${asset}: ${b.balance}`);
        });

        const usdcIssuer = process.env.USDC_ISSUER || 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5';
        const hasUsdc = account.balances.some(b => (b as any).asset_code === 'USDC' && (b as any).asset_issuer === usdcIssuer);
        if (!hasUsdc) {
            console.warn("!! Operator lacks USDC trustline or issuer is different.");
        }
    } catch (e: any) {
        console.error("Error loading account:", e.message);
    }
}

checkOperator();
