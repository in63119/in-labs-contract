import fs from "fs";
import path from "path";
import type * as ethers from "ethers";
import {network} from "hardhat";

const basePath = __dirname;

let base = path.join(basePath, "../");

const makeFile = async (
  contract: string,
  location: string,
  destination: string,
  address: string | ethers.Addressable,
) => {
  const destPath = path.join(base, destination);
  console.log("다음 경로에 타입스크립트 abi 파일을 생성합니다: ", destPath);

  fs.mkdirSync(path.dirname(destPath), {recursive: true});

  const json = fs.readFileSync(path.join(base, location), {
    encoding: "utf-8",
  });

  fs.writeFileSync(destPath, makeData(contract, destPath, json, address), "utf-8");

  copyTypechainArtifacts(contract, path.dirname(destPath));
};

const makeData = (
  contract: string,
  destination: string,
  json: string,
  address: string | ethers.Addressable,
) => {
  const parsedJson = JSON.parse(json);
  const abi = parsedJson.abi;
  const normalizedAddress =
    typeof address === "string" ? address : address.toString();
  const localTypechainRoot = path.join(path.dirname(destination), "typechain");
  const typechainRoot = normalizeImportPath(
    path.relative(path.dirname(destination), localTypechainRoot),
  );
  const contractImportPath = `${typechainRoot}/contracts/${contract}`;
  const factoryImportPath = `${typechainRoot}/factories/${contract}__factory`;

  return `import type { ContractRunner } from "ethers";
import type { ${contract} } from "${contractImportPath}";
import { ${contract}__factory } from "${factoryImportPath}";

export const address = ${JSON.stringify(normalizedAddress)} as const;
export const abi = ${JSON.stringify(abi, null, 2)} as const;
export type { ${contract} };

export const bytecode = ${contract}__factory.bytecode;
export const createInterface = ${contract}__factory.createInterface;
export const connect = (
  runner?: ContractRunner | null,
): ${contract} => ${contract}__factory.connect(address, runner);
`;
};

export const makeAbi = async (
  contract: string,
  address: string | ethers.Addressable,
  departure: string,
  env?: "local" | "prod",
) => {
  const {network, chainEnv} = getNetwork();
  const destination = env
    ? `/abis/${network}/${chainEnv}/${env}/${contract}.ts`
    : `/abis/${network}/${chainEnv}/${contract}.ts`;

  await makeFile(contract, departure, destination, address);
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

const normalizeImportPath = (relativePath: string) => {
  const normalized = relativePath.replace(/\\/g, "/");
  if (!normalized) {
    return ".";
  }

  return normalized.startsWith(".") ? normalized : `./${normalized}`;
};

const copyTypechainArtifacts = (contract: string, destinationDir: string) => {
  const sourceRoot = path.join(base, "typechain-types");
  const artifacts = [
    {
      from: path.join(sourceRoot, "common.ts"),
      to: path.join(destinationDir, "typechain", "common.ts"),
    },
    {
      from: path.join(sourceRoot, "contracts", `${contract}.ts`),
      to: path.join(destinationDir, "typechain", "contracts", `${contract}.ts`),
    },
    {
      from: path.join(
        sourceRoot,
        "factories",
        `${contract}__factory.ts`,
      ),
      to: path.join(
        destinationDir,
        "typechain",
        "factories",
        `${contract}__factory.ts`,
      ),
    },
  ];

  artifacts.forEach(({from, to}) => {
    fs.mkdirSync(path.dirname(to), {recursive: true});
    fs.copyFileSync(from, to);
  });
};
