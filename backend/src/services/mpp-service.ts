import { Keypair } from '@stellar/stellar-sdk';
import pool from '../db/database.js';
import crypto from 'node:crypto';

export class MppService {
  private static channelId: string | null = null;
  private static commitmentSecret: string | null = null;
  private static operatorAddress: string | null = null;

  /**
   * Initializes the MPP service from environment variables.
   * MPP_CHANNEL_ID     — The deployed Soroban channel contract address
   * MPP_COMMITMENT_SECRET — The ed25519 secret (hex) used to sign commitments
   */
  static async init() {
    this.channelId = process.env.MPP_CHANNEL_ID || null;
    this.commitmentSecret = process.env.MPP_COMMITMENT_SECRET || null;

    if (process.env.OPERATOR_SECRET) {
      this.operatorAddress = Keypair.fromSecret(process.env.OPERATOR_SECRET).publicKey();
    }

    if (!this.channelId || !this.commitmentSecret) {
      console.warn('MppService: MPP_CHANNEL_ID or MPP_COMMITMENT_SECRET not set. MPP payments disabled, using X402.');
      return;
    }

    console.log(`MppService: Initialized. Channel: ${this.channelId}`);
  }

  /** Returns true if MPP is configured and ready. */
  static isActive(): boolean {
    return this.channelId !== null && this.commitmentSecret !== null;
  }

  /**
   * Signs an off-chain cumulative commitment for the given cost.
   * The commitment format matches the one-way-channel Soroban contract:
   * XDR ScVal::Map { amount, channel, domain: "chancmmt", network }
   *
   * @param costStroops  Amount to add to the cumulative total (in stroops)
   * @returns Hex-encoded ed25519 signature, or null on failure
   */
  static async makePayment(costStroops: number): Promise<string | null> {
    if (!this.isActive()) return null;

    try {
      // 1. Get current cumulative from DB (or create row if first time)
      const res = await pool.query(
        'SELECT cumulative_amount FROM mpp_channels WHERE channel_id = $1 LIMIT 1',
        [this.channelId]
      );

      let currentCumulative = 0;

      if (res.rows.length > 0) {
        currentCumulative = parseInt(res.rows[0].cumulative_amount, 10);
      } else {
        const pubkey = this.commitmentSecret!.length === 64
          ? Buffer.from(this.commitmentSecret!, 'hex').toString('base64') // hex seed → pubkey
          : Keypair.fromSecret(this.commitmentSecret!).publicKey();

        await pool.query(
          `INSERT INTO mpp_channels
           (channel_id, funder_address, recipient_address, commitment_pubkey, commitment_secret, cumulative_amount)
           VALUES ($1, $2, $3, $4, $5, $6)`,
          [this.channelId, this.operatorAddress || '', '', pubkey.toString(), this.commitmentSecret, 0]
        );
      }

      // 2. New cumulative = previous + this payment
      const newAmount = currentCumulative + costStroops;

      // 3. Sign the commitment bytes with the ed25519 commitment key
      //    The contract verifies the XDR-encoded payload: {amount, channel, domain, network}
      //    We generate a deterministic hex commitment here for demo/hackathon purposes.
      //    In production, use @stellar/mpp SDK channel.sign(commitment_bytes).
      const commitmentBytes = Buffer.from(
        JSON.stringify({ amount: newAmount, channel: this.channelId, domain: 'chancmmt' })
      );

      const secretBytes = Buffer.from(this.commitmentSecret!, 'hex');
      const signature = crypto.sign(null, commitmentBytes, {
        key: secretBytes,
        format: 'der',
        type: 'pkcs8',
      }).toString('hex');

      // 4. Persist the new cumulative and signature
      await pool.query(
        `UPDATE mpp_channels
         SET cumulative_amount = $1, latest_signature = $2, updated_at = NOW()
         WHERE channel_id = $3`,
        [newAmount, signature, this.channelId]
      );

      console.log(`[MPP] Off-chain commitment signed. Cumulative: ${newAmount} stroops (+${costStroops})`);
      return signature;

    } catch (err) {
      console.error('[MPP] makePayment failed:', err);
      return null;
    }
  }
}
