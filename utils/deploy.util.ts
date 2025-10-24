import {network} from "hardhat";
import * as dotenv from "dotenv";
import {resolve} from "path";

dotenv.config({path: resolve(process.cwd(), ".env")});

type Env = "local" | "prod";

export const getNetwork = () => {
  if (network.name === "hardhat") {
    return "localhost";
  } else {
    return network.name;
  }
};

export const getEnv = (): Env => (process.env.ENV === "prod" ? "prod" : "local");
