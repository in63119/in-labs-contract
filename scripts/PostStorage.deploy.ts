import {ethers} from "hardhat";
import {makeAbi} from "../utils/abi.util";
import {getNetwork, getEnv} from "../utils/deploy.util";

async function main() {
  const [relayer] = await ethers.getSigners();

  const network = getNetwork();
  const env = getEnv();

  const postForwarderContractName = "PostForwarder";
  const postForwarderDeparture = `/artifacts/contracts/post/${postForwarderContractName}.sol/${postForwarderContractName}.json`;

  const postStorageName = "PostStorage";
  const postStorageDeparture = `/artifacts/contracts/post/${postStorageName}.sol/${postStorageName}.json`;

  console.log(`\nDeploying to ${network}`);

  console.log(`\nDeploying ${postForwarderContractName} with the account: ${relayer.address}`);
  const postForwarderFactory = await ethers.getContractFactory(postForwarderContractName, relayer);
  const postForwarder = await postForwarderFactory.deploy(postForwarderContractName);
  await postForwarder.waitForDeployment();

  const postForwarderAddress = await postForwarder.getAddress();

  console.log(`\nDeploying ${postStorageName} with the account: ${relayer.address}`);
  const postStorageFactory = await ethers.getContractFactory(postStorageName, relayer);
  const postStorage = await postStorageFactory.deploy(postForwarderAddress);
  await postStorage.waitForDeployment();

  const postStorageAddress = await postStorage.getAddress();

  /* Abi files make */
  await makeAbi(postStorageName, postStorageAddress, postStorageDeparture, env);
  console.log(`\n${postStorageName} contract deployed at: ${postStorageAddress}`);

  await makeAbi(postForwarderContractName, postForwarderAddress, postForwarderDeparture, env);
  console.log(`\n${postStorageName} contract deployed at: ${postForwarderAddress}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
