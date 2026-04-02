import { SorobanRpc } from '@stellar/stellar-sdk';
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
}

export function stellarPaywall(options: PaywallOptions) {
  const usedTxHashes = new Set<string>();

  return async (req: any, res: Response, next: NextFunction) => {
    const txHash = req.headers['x-stellar-tx'] as string;
    
    if (!txHash) {
      return res.status(402).json({
        x402Version: 2,
        error: 'payment_required',
        network: 'stellar:testnet',
        recipient: options.recipientAddress,
        asset: options.usdcContractId,
        amount: options.priceStroops,
        amountUsdc: (options.priceStroops / 10000000).toFixed(7)
      });
    }

    // Prevent replay
    if (usedTxHashes.has(txHash)) {
      return res.status(402).json({ error: 'tx_already_used' });
    }

    try {
      // Verify status directly from Soroban RPC
      const result = await getTransactionStatus(options.rpcUrl, txHash);
      
      if (result.status !== 'SUCCESS') {
        return res.status(402).json({ error: 'tx_not_successful', status: result.status });
      }

      // Payment verified - mark as used and proceed
      usedTxHashes.add(txHash);
      req.stellarTxHash = txHash;
      next();
    } catch (err: any) {
      return res.status(402).json({ error: 'tx_verification_failed', message: err.message });
    }
  };
}
