import {HardhatUserConfig} from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from "dotenv";
dotenv.config();

const accounts = [process.env.RELAYER_PRIVATE_KEY || ""];

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
