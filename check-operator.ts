import { stellarService } from './backend/src/services/stellar';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.join(__dirname, 'backend/.env') });

async function check() {
    const operatorSecret = process.env.OPERATOR_SECRET;
    if (!operatorSecret) {
        console.error('OPERATOR_SECRET not found');
        return;
    }
    const { Keypair } = await import('@stellar/stellar-sdk');
    const kp = Keypair.fromSecret(operatorSecret);
    const pub = kp.publicKey();
    console.log(`Checking operator: ${pub}`);
    const balances = await stellarService.getBalances(pub);
    console.log(`Balances: XLM: ${balances.xlm}, USDC: ${balances.usdc}`);
}

check();
