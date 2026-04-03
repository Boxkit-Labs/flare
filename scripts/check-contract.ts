import { Contract, Networks, SorobanRpc } from "@stellar/stellar-sdk";

const rpc = new SorobanRpc.Server("https://soroban-testnet.stellar.org");
const contractId = "CBIELTK6YBZJU5UP2WWQEUCYKLPU6AUNZ2BQ4WWFEIE3USCIHMXQDAMA";

async function check() {
    // Actually, I'll just check if it's a native or classic asset wrap
    // By checking the name or symbol
    try {
        const c = new Contract(contractId);
        // We can't easily get the issuer from the contract ID without simulation or ledger data
        // But we can check if it's the one in .env
        console.log("Contract ID:", contractId);
    } catch(e) {}
}
check();
