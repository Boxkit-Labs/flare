import { Keypair, Horizon, Networks, Asset, TransactionBuilder, Operation } from '@stellar/stellar-sdk';
import pool from '../db/database.js';
import { decrypt } from '../utils/crypto.js';
import 'dotenv/config';

async function sweep() {
  const server = new Horizon.Server(process.env.HORIZON_URL || 'https://horizon-testnet.stellar.org');
  const opSecret = process.env.OPERATOR_SECRET;
  if (!opSecret) throw new Error("OPERATOR_SECRET not found");
  const opKp = Keypair.fromSecret(opSecret);
  const operatorPk = opKp.publicKey();

  const usdcAsset = new Asset('USDC', process.env.USDC_ISSUER || 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5');

  console.log(`Operator: ${operatorPk}`);

  const res = await pool.query('SELECT * FROM users');
  const users = res.rows;
  console.log(`Found ${users.length} users in DB.`);

  let totalSwept = 0;

  for (const user of users) {
    if (user.stellar_public_key === operatorPk) continue;

    try {
      const acc = await server.loadAccount(user.stellar_public_key);
      const usdcBalance = acc.balances.find(b => b.asset_type === 'credit_alphanum4' && b.asset_code === 'USDC' && b.asset_issuer === usdcAsset.issuer);

      if (usdcBalance && parseFloat(usdcBalance.balance) > 0) {
        console.log(`User ${user.user_id} (${user.stellar_public_key}) has ${usdcBalance.balance} USDC.`);

        let amount = usdcBalance.balance;

        const encryptionKey = process.env.ENCRYPTION_KEY!;
        const decryptedSecret = decrypt(user.stellar_secret_key_encrypted, encryptionKey);
        const userKp = Keypair.fromSecret(decryptedSecret);

        const fee = await server.fetchBaseFee();
        const tx = new TransactionBuilder(acc, { fee: fee.toString(), networkPassphrase: Networks.TESTNET })
          .addOperation(Operation.payment({
            destination: operatorPk,
            asset: usdcAsset,
            amount: amount,
          }))
          .setTimeout(30)
          .build();

        tx.sign(userKp);
        await server.submitTransaction(tx);
        console.log(`  -> Swept ${amount} USDC to Operator.`);
        totalSwept += parseFloat(amount);
      }
    } catch (e: any) {
      if (e.response && e.response.status === 404) {

      } else {
        console.error(`Error sweeping ${user.stellar_public_key}:`, e.response?.data?.extras?.result_codes || e.message);
      }
    }
  }

  console.log(`Sweeping complete. Total swept: ${totalSwept} USDC.`);
}

sweep().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
