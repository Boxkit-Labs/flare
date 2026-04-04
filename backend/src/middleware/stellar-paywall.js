/**
 * Helper to fetch transaction status directly from JSON-RPC to avoid SDK deserialization bugs.
 */
async function getTransactionStatus(rpcUrl, txHash) {
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
    const json = await response.json();
    if (json.error)
        throw new Error(json.error.message);
    return json.result;
}
export function stellarPaywall(options) {
    const usedTxHashes = new Set();
    return async (req, res, next) => {
        const txHash = req.headers['x-stellar-tx'];
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
            if (result.status !== 'SUCCESS') {
                res.status(402).json({ error: 'tx_not_successful', status: result.status });
                return;
            }
            // Payment verified - mark as used and proceed
            usedTxHashes.add(txHash);
            req.stellarTxHash = txHash;
            next();
        }
        catch (err) {
            res.status(402).json({ error: 'tx_verification_failed', message: err.message });
            return;
        }
    };
}
