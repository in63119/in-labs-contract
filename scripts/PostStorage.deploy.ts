import {ethers} from "hardhat";
import {makeAbi} from "../utils/abi.util";
import {getNetwork, getEnv, getForwarderAddress} from "../utils/deploy.util";

async function main() {
  const [owner] = await ethers.getSigners();

  const network = getNetwork();
  const env = getEnv();

  const postStorageName = "PostStorage";
  const postStorageDeparture = `/artifacts/contracts/${postStorageName}.sol/${postStorageName}.json`;

  const inForwarderAddress = getForwarderAddress();

  console.log(`\nDeploying to ${network}`);

  console.log(`\nDeploying ${postStorageName} with the account: ${owner.address}`);
  const postStorageFactory = await ethers.getContractFactory(postStorageName, owner);
  const postStorage = await postStorageFactory.deploy(inForwarderAddress);
  await postStorage.waitForDeployment();

  const postStorageAddress = await postStorage.getAddress();

  /* Abi files make */
  await makeAbi(postStorageName, postStorageAddress, postStorageDeparture, env);
  console.log(`\n${postStorageName} contract deployed at: ${postStorageAddress}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
