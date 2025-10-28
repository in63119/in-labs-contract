import {ethers} from "hardhat";
import {makeAbi} from "../utils/abi.util";
import {getNetwork, getEnv} from "../utils/deploy.util";

async function main() {
  const [relayer] = await ethers.getSigners();

  const network = getNetwork();
  const env = getEnv();

  const postStorageName = "PostStorage";
  const postStorageDeparture = `/artifacts/contracts/${postStorageName}.sol/${postStorageName}.json`;

  console.log(`\nDeploying to ${network}`);

  console.log(`\nDeploying ${postStorageName} with the account: ${relayer.address}`);
  const postStorageFactory = await ethers.getContractFactory(postStorageName, relayer);
  const postStorage = await postStorageFactory.deploy();
  await postStorage.waitForDeployment();

  /* Abi files make */
  await makeAbi(postStorageName, postStorage.target, postStorageDeparture, env);
  console.log(`\n${postStorageName} contract deployed at: ${postStorage.target}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
