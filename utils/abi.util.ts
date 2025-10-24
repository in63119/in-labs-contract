import fs from "fs";
import path from "path";
import type * as ethers from "ethers";
import {network} from "hardhat";

const basePath = __dirname;

let base = path.join(basePath, "../");

const makeFile = async (
  location: string,
  destination: string,
  address: string | ethers.Addressable,
) => {
  const destPath = path.join(base, destination);
  console.log("다음 경로에 abi파일을 만듭니다. : ", path.join(base, destPath));

  fs.mkdirSync(path.dirname(destPath), {recursive: true});

  const json = fs.readFileSync(path.join(base, location), {
    encoding: "utf-8",
  });

  fs.writeFileSync(destPath, makeData(json, address));
};

const makeData = (json: string, address: string | ethers.Addressable) => {
  const abi = JSON.parse(json).abi;

  return JSON.stringify({
    abi: abi,
    address: address,
  });
};

export const makeAbi = async (
  contract: string,
  address: string | ethers.Addressable,
  departure: string,
  env?: "local" | "prod",
) => {
  const {network, chainEnv} = getNetwork();
  const destination = env
    ? `/abis/${network}/${chainEnv}/${env}/${contract}.json`
    : `/abis/${network}/${chainEnv}/${contract}.json`;

  await makeFile(departure, destination, address);
};

const getNetwork = () => {
  const result = {
    network: "",
    chainEnv: "",
  };

  if (network.name === "hardhat") {
    result.network = "localhost";
    result.chainEnv = "local";
  } else {
    const parts = network.name.split("_");
    result.network = parts[0];
    result.chainEnv = parts[1];
  }

  return result;
};
