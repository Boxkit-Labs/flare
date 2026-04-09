import { payForService, PayParams } from './stellar-pay-client.js';
import { mppChannelManager } from './mpp-channel-manager.js';
import dotenv from 'dotenv';

dotenv.config();

const SOROBAN_RPC_URL = process.env.SOROBAN_RPC_URL || 'https://soroban-testnet.stellar.org';

// Threshold: if check_interval < 360 min (6 hours), use MPP session channel
const MPP_THRESHOLD_MINUTES = 360;

// Low-balance threshold: if < 10% of deposit remains, reopen channel
const LOW_BALANCE_THRESHOLD = 0.10;

export interface PayForCheckParams {
  userId: string;
  watcherId: string;
  watcherType: string;
  checkIntervalMinutes: number;
  serviceId: string;
  serviceUrl: string;
  requestBody: any;
  method: 'GET' | 'POST';
  userSecretKey: string;
  receiverAddress: string;
  priceStroops: number;
  weeklyBudgetUsdc?: number;
}

export interface PayForCheckResult {
  data: any;
  txHash: string;
  costPaid: number;
  paymentMethod: 'x402' | 'mpp';
}

export class PaymentRouter {
  async payForCheck(params: PayForCheckParams): Promise<PayForCheckResult> {
    const {
      userId, checkIntervalMinutes, serviceId, serviceUrl,
      requestBody, method, userSecretKey, receiverAddress,
      priceStroops, weeklyBudgetUsdc,
    } = params;

    // ─── X402 path: low frequency watchers ───────────────────────────────────
    if (checkIntervalMinutes >= MPP_THRESHOLD_MINUTES) {
      const result = await payForService({
        serviceUrl,
        method,
        body: requestBody,
        payerSecretKey: userSecretKey,
        rpcUrl: SOROBAN_RPC_URL,
      });
      return { ...result, paymentMethod: 'x402' };
    }

    // ─── MPP path: high frequency watchers ───────────────────────────────────
    const amountUsdc = priceStroops / 10_000_000;

    // Check if channel exists and is healthy
    let channelState = await mppChannelManager.getChannelStatus(userId, serviceId);
    let openTxHash: string | null = null;

    const needsNewChannel = !channelState
      || channelState.spent / channelState.deposit > (1 - LOW_BALANCE_THRESHOLD)
      || channelState.expiresAt < new Date(Date.now() + 10 * 60 * 1000);

    if (needsNewChannel) {
      if (channelState) {
        // Close the old channel before opening a new one
        console.log(`[PaymentRouter] Channel low/expiring. Closing for ${userId}:${serviceId}`);
        try {
          await mppChannelManager.closeChannel({ userId, serviceId });
        } catch (err) {
          console.warn('[PaymentRouter] Failed to close old channel, proceeding to open new one:', err);
        }
      }

      // Calculate deposit: weekly budget * 1.2 (20% buffer), fallback to $1
      const deposit = weeklyBudgetUsdc
        ? (weeklyBudgetUsdc * 1.2).toFixed(7)
        : '1.0000000';

      console.log(`[PaymentRouter] Opening MPP channel for ${userId}:${serviceId}. Deposit: ${deposit} USDC`);

      const { channelId, txHash } = await mppChannelManager.openChannel({
        userId,
        serviceId,
        userSecretKey,
        receiverAddress,
        depositAmount: deposit,
        durationSeconds: 7 * 24 * 60 * 60, // 1 week
      });

      openTxHash = txHash;
      console.log(`[PaymentRouter] ✅ MPP channel opened: ${channelId} | TX: ${txHash}`);

      channelState = await mppChannelManager.getChannelStatus(userId, serviceId);
    }

    // Make off-chain payment
    const { proof, totalSpent } = await mppChannelManager.makePayment({
      userId,
      serviceId,
      amount: amountUsdc.toFixed(7),
    });

    // Fetch the data from the service with the MPP proof header
    const fetchOptions: RequestInit = {
      method,
      headers: {
        'Content-Type': 'application/json',
        'X-MPP-PROOF': proof,
      },
    };
    if (requestBody && method === 'POST') {
      fetchOptions.body = JSON.stringify(requestBody);
    }

    let data: any;
    try {
      // First try: some services accept the proof directly
      const res = await fetch(serviceUrl, fetchOptions);
      if (res.ok) {
        data = await res.json();
      } else if (res.status === 402) {
        // Service doesn't support MPP proof, fall back gracefully to X402
        console.warn('[PaymentRouter] Service rejected MPP proof, falling back to X402');
        const x402Result = await payForService({
          serviceUrl,
          method,
          body: requestBody,
          payerSecretKey: userSecretKey,
          rpcUrl: SOROBAN_RPC_URL,
        });
        return { ...x402Result, paymentMethod: 'x402' };
      } else {
        throw new Error(`Service request failed (${res.status}): ${await res.text()}`);
      }
    } catch (fetchErr: any) {
      // Network error or other — fallback to X402
      console.warn('[PaymentRouter] MPP fetch failed, falling back to X402:', fetchErr?.message);
      const x402Result = await payForService({
        serviceUrl,
        method,
        body: requestBody,
        payerSecretKey: userSecretKey,
        rpcUrl: SOROBAN_RPC_URL,
      });
      return { ...x402Result, paymentMethod: 'x402' };
    }

    const txHash = openTxHash ?? 'mpp-offchain';
    console.log(`[PaymentRouter] 💳 MPP payment complete. Total spent: ${totalSpent} USDC | TX: ${txHash}`);

    return {
      data,
      txHash,
      costPaid: priceStroops,
      paymentMethod: 'mpp',
    };
  }
}

export const paymentRouter = new PaymentRouter();
