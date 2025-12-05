import {network} from "hardhat";
import * as dotenv from "dotenv";
import {resolve} from "path";

import InForwarderDev from "../abis/kaia/test/development/InForwarder.json";
import InForwarderProd from "../abis/kaia/test/production/InForwarder.json";

dotenv.config({path: resolve(process.cwd(), ".env")});

type Env = "development" | "production";

const inForwarderAddress = {
  development: InForwarderDev.address,
  production: InForwarderProd.address,
};

export const getNetwork = () => {
  if (network.name === "hardhat") {
    return "localhost";
  } else {
    return network.name;
  }
};

export const getEnv = (): Env => (process.env.ENV === "production" ? "production" : "development");

export const getForwarderAddress = () => {
  const env = getEnv();
  return inForwarderAddress[env];
};
