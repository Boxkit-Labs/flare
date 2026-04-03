import { Asset, Networks } from "@stellar/stellar-sdk";

const a = new Asset("USDC", "GAHJ3JTTQGBK4FLCGOPBUZJCPCUBK5SUPOA5VQNLAZE3VIDVF6TKLF42");
console.log(a.getContractId(Networks.TESTNET));
