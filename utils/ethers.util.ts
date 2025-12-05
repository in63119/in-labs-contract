import {
  toUtf8Bytes,
  Wallet,
  keccak256,
  JsonRpcProvider,
  Contract,
  FeeData,
  encodeBytes32String,
  Interface,
} from "ethers";
import dotenv from "dotenv";

dotenv.config();

export const getProvider = () => {
  return new JsonRpcProvider("https://public-en-kairos.node.kaia.io");
};

export const accounts = () => {
  const provider = getProvider();
  return {
    owner: new Wallet(process.env.CONTRACTS_OWNER_PRIVATE_KEY || "", provider),
    relayer1: new Wallet(process.env.RELAYER1_PRIVATE_KEY || "", provider),
    relayer2: new Wallet(process.env.RELAYER2_PRIVATE_KEY || "", provider),
    relayer3: new Wallet(process.env.RELAYER3_PRIVATE_KEY || "", provider),
  };
};

export const getContract = (address: string, abi: any) => {
  return new Contract(address, abi, getProvider());
};
