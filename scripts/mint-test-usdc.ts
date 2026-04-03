import { Keypair, Networks, Asset, Operation, TransactionBuilder, Horizon } from "@stellar/stellar-sdk";

const HORIZON_URL = "https://horizon-testnet.stellar.org";
const horizon = new Horizon.Server(HORIZON_URL);

// My own local issuer for this test
const ISSUER_SECRET = "SBV46U3Y6JQZ6S723223222222222222222222222222222222222222"; // Random? No.
const issuerKp = Keypair.random();
const buyerPublic = "GBSLVTRUWZPSP6YFVBJJNQTNHRECYSEGGINGLBOYJFN36A2YXQWMHJRF";

async function main() {
    console.log(`Creating test issuer: ${issuerKp.publicKey()}`);
    
    // 1. Fund issuer
    await fetch(`https://friendbot.stellar.org?addr=${issuerKp.publicKey()}`);
    console.log("Issuer funded with XLM.");

    // 2. Add trustline for Buyer to THIS issuer's USDC
    const buyerSecret = "SAFIYIKN2LHEASCATRDY2BSZOB43C6BYHBX5OTZLZ5S3NITOS2C3HWWW";
    const buyerKp = Keypair.fromSecret(buyerSecret);
    const buyerAccount = await horizon.loadAccount(buyerKp.publicKey());
    
    const CUSTOM_USDC = new Asset("USDC", issuerKp.publicKey());
    
    console.log("Adding trustline for custom USDC to Buyer...");
    const trustTx = new TransactionBuilder(buyerAccount, {
        fee: "100",
        networkPassphrase: Networks.TESTNET
    })
    .addOperation(Operation.changeTrust({ asset: CUSTOM_USDC }))
    .setTimeout(30)
    .build();
    trustTx.sign(buyerKp);
    await horizon.submitTransaction(trustTx);

    // 3. Issue USDC
    console.log("Issuing 1000 USDC to Buyer...");
    const issuerAccount = await horizon.loadAccount(issuerKp.publicKey());
    const issueTx = new TransactionBuilder(issuerAccount, {
        fee: "100",
        networkPassphrase: Networks.TESTNET
    })
    .addOperation(Operation.payment({
        destination: buyerKp.publicKey(),
        asset: CUSTOM_USDC,
        amount: "1000"
    }))
    .setTimeout(30)
    .build();
    issueTx.sign(issuerKp);
    await horizon.submitTransaction(issueTx);

    console.log("SUCCESS! Buyer now has 1000 custom USDC.");
    console.log(`USDC Asset Code: USDC`);
    console.log(`USDC Issuer: ${issuerKp.publicKey()}`);
    
    // 4. Also fund the operator with this USDC trustline? 
    // No, the operator just needs to be the target.
}

main().catch(console.error);
