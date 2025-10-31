import {ethers} from "hardhat";
import {makeAbi} from "../utils/abi.util";
import {getNetwork, getEnv} from "../utils/deploy.util";

async function main() {
  const [relayer] = await ethers.getSigners();

  const network = getNetwork();
  const env = getEnv();

  const authStorageName = "AuthStorage";
  const authStorageDeparture = `/artifacts/contracts/${authStorageName}.sol/${authStorageName}.json`;

  console.log(`\nDeploying to ${network}`);

  console.log(`\nDeploying ${authStorageName} with the account: ${relayer.address}`);
  const authStorageFactory = await ethers.getContractFactory(authStorageName, relayer);
  const authStorage = await authStorageFactory.deploy();
  await authStorage.waitForDeployment();

  /* Abi files make */
  await makeAbi(authStorageName, authStorage.target, authStorageDeparture, env);
  console.log(`\n${authStorageName} contract deployed at: ${authStorage.target}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
