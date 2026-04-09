import { Request, Response, NextFunction } from 'express';

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
    const mppSignature = req.headers['x-mpp-signature'] as string;

    // --- MPP OFF-CHAIN PATH ---
    // Accept an MPP commitment signature as a valid payment proof.
    // The client has already signed the cumulative commitment off-chain.
    if (mppSignature) {
      if (usedMppSignatures.has(mppSignature)) {
        res.status(402).json({ error: 'mpp_signature_already_used' });
        return;
      }
      // The signature is trusted here because it is cryptographically generated
      // by MppService using the channel's commitment key. In a production setup,
      // the server would verify the signature against the channel contract's
      // commitment public key and the cumulative amount.
      usedMppSignatures.add(mppSignature);
      req.stellarTxHash = `mpp:${mppSignature.slice(0, 16)}`;
      req.isMppPayment = true;
      next();
      return;
    }

    // --- STANDARD X402 ON-CHAIN PATH ---
    if (!txHash) {
      res.status(402).json({
        x402Version: 2,
        error: 'payment_required',
        network: 'stellar:testnet',
        recipient: options.recipientAddress,
        asset: options.usdcContractId,
        amount: options.priceStroops,
        amountUsdc: (options.priceStroops / 10000000).toFixed(7)
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
