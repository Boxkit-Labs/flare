import pool from '../db/database.js';
import { stellarService } from '../services/stellar.js';
import { getUsdcBalance } from '../services/stellar-pay-client.js';
import dotenv from 'dotenv';
dotenv.config();

const SOROBAN_RPC_URL = 'https://soroban-testnet.stellar.org';
const OPERATOR_PUBLIC = 'GDKU2DY4TTRRSQ6BBFYTDV2GEWREHCIDUM5FFXLIF66PDOO3HYJ2YZIF';

async function main() {
    console.log("--- Operator Status Report ---");
    
    // 1. Check Balance
    try {
        const balances = await stellarService.getBalances(OPERATOR_PUBLIC);
        console.log(`Current Operator Balances: XLM=${balances.xlm}, USDC=${balances.usdc}`);
        
        const sorobanBalance = await getUsdcBalance(OPERATOR_PUBLIC, SOROBAN_RPC_URL);
        console.log(`Soroban USDC Balance: ${sorobanBalance} USDC`);
    } catch (e: any) {
        console.error("Failed to fetch balance:", e.message);
    }

    // 2. Find refundable channels
    try {
        const { rows } = await pool.query(
            "SELECT channel_id, user_id, deposit_usdc, spent_usdc FROM mpp_channels WHERE status='open' AND deposit_usdc > spent_usdc ORDER BY (deposit_usdc - spent_usdc) DESC LIMIT 10"
        );
        console.log("\nTop 10 Potential Refundable Channels:");
        if (rows.length === 0) {
            console.log("No open channels with remaining balance found.");
        } else {
            rows.forEach((r: any) => {
                const remaining = parseFloat(r.deposit_usdc) - parseFloat(r.spent_usdc);
                console.log(`Channel ${r.channel_id} (User ${r.user_id}): ${remaining.toFixed(7)} USDC remaining`);
            });
        }
    } catch (e: any) {
        console.error("Failed to query DB:", e.message);
    }
    
    process.exit(0);
}

main();
