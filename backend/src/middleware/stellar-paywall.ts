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

  return async (req: any, res: any, next: NextFunction) => {
    const txHash = req.headers['x-stellar-tx'] as string;
    
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
