import { Request, Response, NextFunction } from 'express';
import { mppChannelManager } from '../services/mpp-channel-manager.js';


export interface PaywallOptions {
  priceStroops: number;
  recipientAddress: string;
  usdcContractId: string;
  rpcUrl: string;
}

/**
 * Helper to fetch transaction status directly from JSON-RPC to avoid SDK deserialization bugs.
 */
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

export function stellarPaywall(options: PaywallOptions) {
  const usedTxHashes = new Set<string>();
  const usedMppSignatures = new Set<string>();

  return async (req: any, res: any, next: NextFunction) => {
    const txHash = req.headers['x-stellar-tx'] as string;
    const mppProof = req.headers['x-mpp-proof'] as string;

    // --- MPP OFF-CHAIN PATH ---
    if (mppProof) {
      if (usedMppSignatures.has(mppProof)) {
        res.status(402).json({ error: 'mpp_signature_already_used' });
        return;
      }
      
      try {
          const parsedProof = JSON.parse(mppProof);
          const channelId = parsedProof.channelId;
          const proofData = parsedProof.proof; // { amount, signature }
          if(!channelId || !proofData) throw new Error("Invalid proof format");
          
          const isValid = await mppChannelManager.verifyPaymentProof(channelId, JSON.stringify(proofData), options.priceStroops);
          
          if (!isValid) {
             res.status(402).json({ error: 'mpp_proof_invalid' });
             return;
          }
          
          usedMppSignatures.add(mppProof);
          req.stellarTxHash = `mpp:${channelId.substring(0,8)}:${proofData.signature.substring(0,8)}`;
          req.isMppPayment = true;
          req.channelId = channelId;
          next();
          return;
      } catch (e: any) {
          res.status(402).json({ error: 'mpp_proof_invalid', message: e.message });
          return;
      }
    }

    // --- STANDARD X402 ON-CHAIN PATH ---
    if (!txHash) {
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
      return;
    }

    // Prevent replay
    if (usedTxHashes.has(txHash)) {
      res.status(402).json({ error: 'tx_already_used' });
      return;
    }

    try {
      // Verify status directly from Soroban RPC
      const result = await getTransactionStatus(options.rpcUrl, txHash);
      
      if (!result || result.status !== 'SUCCESS') {
        res.status(402).json({ error: 'tx_not_successful', status: result?.status || 'NOT_FOUND' });
        return;
      }

      // Payment verified - mark as used and proceed
      usedTxHashes.add(txHash);
      req.stellarTxHash = txHash;
      next();
    } catch (err: any) {
      res.status(402).json({ error: 'tx_verification_failed', message: err.message });
      return;
    }
  };
}
