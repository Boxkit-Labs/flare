import { Keypair, Networks, Asset, Operation, TransactionBuilder, Horizon } from "@stellar/stellar-sdk";

const HORIZON_URL = "https://horizon-testnet.stellar.org";
const horizon = new Horizon.Server(HORIZON_URL);

const OPERATOR_SECRET = "SAGQKX7WQAT7DN4H7Z7EJLOQ77YE5ALF6WD3CCJAQR3F23LQPJG6NIKE";
const CUSTOM_USDC_ISSUER = "GAHJ3JTTQGBK4FLCGOPBUZJCPCUBK5SUPOA5VQNLAZE3VIDVF6TKLF42";
const CUSTOM_USDC = new Asset("USDC", CUSTOM_USDC_ISSUER);

async function main() {
  const kp = Keypair.fromSecret(OPERATOR_SECRET);
  console.log(`Updating Operator Trustline: ${kp.publicKey()}`);

  const account = await horizon.loadAccount(kp.publicKey());
  
  console.log(`  Adding trustline for custom USDC: ${CUSTOM_USDC_ISSUER}`);
  const tx = new TransactionBuilder(account, {
    fee: "100",
    networkPassphrase: Networks.TESTNET,
  })
  .addOperation(Operation.changeTrust({ asset: CUSTOM_USDC }))
  .setTimeout(30)
  .build();
  tx.sign(kp);
  await horizon.submitTransaction(tx);
  console.log(`  Trustline added to Operator.`);
}

main().catch(console.error);
