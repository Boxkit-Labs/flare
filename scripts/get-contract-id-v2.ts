import { Asset, Networks } from "@stellar/stellar-sdk";

const code = "USDC";
const issuer = "GAHJ3JTTQGBK4FLCGOPBUZJCPCUBK5SUPOA5VQNLAZE3VIDVF6TKLF42";
const asset = new Asset(code, issuer);
const contractId = asset.contractId(Networks.TESTNET);
console.log(contractId);
