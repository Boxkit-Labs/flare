import { stellarService } from '../src/services/stellar';

async function run() {
    console.log("1. Generating Keypair...");
    const keypair = stellarService.generateKeypair();
    console.log("Public Key:", keypair.publicKey);
    console.log("Secret Key:", keypair.secretKey);

    console.log("\n2. Funding with Friendbot...");
    const funded = await stellarService.fundWithFriendbot(keypair.publicKey);
    if (!funded) {
        console.error("Failed to fund with friendbot. Exiting.");
        return;
    }
    console.log("Success! XLM received.");

    console.log("\n3. Adding USDC Trustline...");
    try {
      const trustlineHash = await stellarService.addUsdcTrustline(keypair.secretKey);
      console.log("Trustline tx hash:", trustlineHash);
    } catch (e: any) {
        console.error("Failed to add trustline:", e?.response?.data || e.message);
        return;
    }

    if (!process.env.OPERATOR_SECRET) {
         console.warn("\nSkipping USDC funding step (OPERATOR_SECRET not set in env).");
    } else {
        console.log("\n4. Funding with USDC from Operator...");
        try {
            const fundHash = await stellarService.fundNewUserWithUsdc(keypair.publicKey, "10.0");
            console.log("USDC funding tx hash:", fundHash);
        } catch(e: any) {
             console.error("Failed to fund USDC:", e?.response?.data || e.message);
             return;
        }
    }

    console.log("\n5. Checking final balances...");
    const balances = await stellarService.getBalances(keypair.publicKey);
    console.log("Balances:", balances);
    
    console.log(`\nView on Explorer: https://stellar.expert/explorer/testnet/account/${keypair.publicKey}`);
}

run().catch(console.error);
