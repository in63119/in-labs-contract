import {HardhatUserConfig} from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from "dotenv";
dotenv.config();

const accounts = [
  process.env.CONTRACTS_OWNER_PRIVATE_KEY || "",
  process.env.RELAYER1_PRIVATE_KEY || "",
  process.env.RELAYER2_PRIVATE_KEY || "",
  process.env.RELAYER3_PRIVATE_KEY || "",
];

const config: HardhatUserConfig = {
  solidity: "0.8.28",
  networks: {
    kaia_test: {
      url: "https://public-en-kairos.node.kaia.io",
      accounts: accounts,
    },
  },
};

export default config;
