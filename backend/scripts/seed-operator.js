const { Keypair, Horizon, Networks, TransactionBuilder, Asset, Operation } = require('@stellar/stellar-sdk');

(async () => {
    try {
        const server = new Horizon.Server('https://horizon-testnet.stellar.org');
        const sourceKp = Keypair.fromSecret('SDZBFB2LFPFTVBPDQSFAA7HEKTBPE7QLP4GRT3QVDMTHCRX7JVLRCFHA');
        const usdc = new Asset('USDC', 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5');

        console.log(`Loading account: ${sourceKp.publicKey()}`);
        const account = await server.loadAccount(sourceKp.publicKey());
        
        console.log(`Current XLM: ${account.balances.find(b => b.asset_type === 'native').balance}`);

        const tx = new TransactionBuilder(account, {
            fee: await server.fetchBaseFee(),
            networkPassphrase: Networks.TESTNET
        })
        .addOperation(Operation.pathPaymentStrictSend({
            sendAsset: Asset.native(),
            sendAmount: '500',
            destination: sourceKp.publicKey(),
            destAsset: usdc,
            destMin: '10'
        }))
        .setTimeout(30)
        .build();

        tx.sign(sourceKp);
        console.log('Submitting swap transaction...');
        const response = await server.submitTransaction(tx);
        console.log('Successfully swapped XLM for USDC. Hash:', response.hash);

    } catch (e) {
        console.error('Swap failed:', e.response?.data?.extras?.result_codes || e.message);
        if (e.response?.data?.extras?.result_codes) {
             console.error('Full result codes:', JSON.stringify(e.response.data.extras.result_codes, null, 2));
        }
    }
})();
