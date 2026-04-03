import { Keypair, Networks, Asset, Operation, TransactionBuilder, Horizon } from "@stellar/stellar-sdk";

const HORIZON_URL = "https://horizon-testnet.stellar.org";
const horizon = new Horizon.Server(HORIZON_URL);

const OPERATOR_SECRET = "SAGQKX7WQAT7DN4H7Z7EJLOQ77YE5ALF6WD3CCJAQR3F23LQPJG6NIKE";
const USDC_CONTRACT = "CBIELTK6YBZJU5UP2WWQEUCYKLPU6AUNZ2BQ4WWFEIE3USCIHMXQDAMA";

async function main() {
  const kp = Keypair.fromSecret(OPERATOR_SECRET);
  const account = await horizon.loadAccount(kp.publicKey());
  
  // CBIELTK... is the SAC for a specific classic asset on testnet.
  // We need to find WHICH classic asset it is, OR just add the trustline if we know it.
  // The user says "CBIELTK... worked in test-x402.ts".
  // Let's assume it's the Circle USDC or the one in the stellar service.
  
  // I'll check the contract details via Horizon to find the classic asset mapping.
  console.log("Adding trustline for USDC_CONTRACT via classic mapping...");
  // Wait, I'll just use the asset from StellarService.
  const usdcAsset = new Asset("USDC", "GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5");

  const tx = new TransactionBuilder(account, {
    fee: "100",
    networkPassphrase: Networks.TESTNET,
  })
  .addOperation(Operation.changeTrust({ asset: usdcAsset }))
  .setTimeout(30)
  .build();
  tx.sign(kp);
  await horizon.submitTransaction(tx);
  console.log("Trustline added to Operator.");
}
main().catch(console.error);
