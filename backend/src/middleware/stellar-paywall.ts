import { Request, Response, NextFunction } from 'express';
import { mppChannelManager } from '../services/mpp-channel-manager.js';
import { Address, Networks, xdr, nativeToScVal } from '@stellar/stellar-sdk';
import crypto from 'node:crypto';

export interface PaywallOptions {
  priceStroops: number;
  recipientAddress: string;
  usdcContractId: string;
  rpcUrl: string;
}

async function getTransactionStatus(rpcUrl: string, txHash: string): Promise<any> {
    try {
        const response = await fetch(rpcUrl, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                jsonrpc: '2.0',
                id: 1,
                method: 'getTransaction',
                params: { hash: txHash }
            })
        });
        const json = await response.json() as any;
        if (json.error) throw new Error(json.error.message);
        return json.result;
    } catch (err: any) {
        throw new Error(`RPC Connection Error: ${err.message}`);
    }
}

const channelCache = new Map<string, { publicKey: string, lastAmount: number }>();
const usedTxHashes = new Set<string>();

export function stellarPaywall(options: PaywallOptions) {
  const usedTxHashes = new Set<string>();

  return async (req: any, res: any, next: NextFunction) => {

    const mppProof = req.headers['x-mpp-proof'] as string;
    if (mppProof) {
      try {
        const proof = JSON.parse(mppProof);

        if (proof.signature && proof.cumulativeAmount !== undefined && proof.channelId) {
          console.log('[Paywall] MPP proof accepted. Channel:', proof.channelId, 'Amount:', proof.cumulativeAmount);
          req.stellarTxHash = 'mpp-offchain-' + proof.channelId;
          req.paymentMethod = 'mpp';
          req.channelId = proof.channelId;
          return next();
        }
      } catch (e) {
        console.warn('[Paywall] Invalid MPP proof format received');
      }
    }

    const txHash = req.headers['x-stellar-tx'] as string;

    if (txHash) {
      if (usedTxHashes.has(txHash)) {
        res.status(402).json({ error: 'tx_already_used' });
        return;
      }
      try {
        const result = await getTransactionStatus(options.rpcUrl, txHash);
        if (!result || result.status !== 'SUCCESS') {
          res.status(402).json({ error: 'tx_not_successful', status: result?.status || 'NOT_FOUND' });
          return;
        }
        usedTxHashes.add(txHash);
        req.stellarTxHash = txHash;
        next();
        return;
      } catch (err: any) {
        res.status(402).json({ error: 'tx_verification_failed', message: err.message });
        return;
      }
    }

    res.status(402).json({
      x402Version: 2,
      mppVersion: 1,
      error: 'payment_required',
      network: 'stellar:testnet',
      recipient: options.recipientAddress,
      asset: options.usdcContractId,
      amount: options.priceStroops,
      amountUsdc: (options.priceStroops / 10000000).toFixed(7),
      payment_methods: [
        { method: "x402", header: "x-stellar-tx", description: "Direct Stellar transaction" },
        { method: "mpp", header: "x-mpp-proof", description: "MPP session channel proof" }
      ]
    });
  };
}

