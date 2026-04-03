import { Keypair, Networks, Asset, Operation, TransactionBuilder, Horizon } from "@stellar/stellar-sdk";

const NETWORK = "testnet";
const HORIZON_URL = "https://horizon-testnet.stellar.org";
const horizon = new Horizon.Server(HORIZON_URL);

// Use the operator provided by the user
const OPERATOR_SECRET = "SAGQKX7WQAT7DN4H7Z7EJLOQ77YE5ALF6WD3CCJAQR3F23LQPJG6NIKE";
const operatorKp = Keypair.fromSecret(OPERATOR_SECRET);

// Circle Testnet USDC
const USDC_ISSUER = "GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN";
const USDC = new Asset("USDC", USDC_ISSUER);

async function setupAccount(secret: string, name: string) {
  const kp = Keypair.fromSecret(secret);
  console.log(`Setting up ${name}: ${kp.publicKey()}`);

  // 1. Friendbot
  try {
    const res = await fetch(`https://friendbot.stellar.org?addr=${kp.publicKey()}`);
    if (res.ok) console.log(`  [${name}] Funded with XLM`);
  } catch (e) {
    console.log(`  [${name}] Already funded or error:`, e);
  }

  // 2. Trustline
  const account = await horizon.loadAccount(kp.publicKey());
  const hasTrust = account.balances.some(b => (b as any).asset_code === "USDC");
  
  if (!hasTrust) {
      console.log(`  [${name}] Adding USDC trustline...`);
      const tx = new TransactionBuilder(account, {
        fee: "100",
        networkPassphrase: Networks.TESTNET,
      })
      .addOperation(Operation.changeTrust({ asset: USDC }))
      .setTimeout(30)
      .build();
      tx.sign(kp);
      await horizon.submitTransaction(tx);
      console.log(`  [${name}] Trustline added.`);
  } else {
      console.log(`  [${name}] Trustline already exists.`);
  }
}

async function main() {
  await setupAccount(OPERATOR_SECRET, "Operator");
  
  // Create a buyer account
  const buyerKp = Keypair.random();
  const buyerSecret = buyerKp.secret();
  console.log("BUYER_SECRET:", buyerSecret);
  console.log("BUYER_PUBLIC:", buyerKp.publicKey());

  await setupAccount(buyerSecret, "Buyer");

  console.log("\nSetup complete. Use the BUYER_SECRET to run the payment verification script.");
}

main().catch(console.error);
