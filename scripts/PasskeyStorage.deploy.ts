import {ethers} from "hardhat";
import {makeAbi} from "../utils/abi.util";
import {getNetwork, getEnv} from "../utils/deploy.util";

async function main() {
  const [relayer] = await ethers.getSigners();

  const network = getNetwork();
  const env = getEnv();

  const passkeyStorageName = "PasskeyStorage";
  const passkeyStorageDeparture = `/artifacts/contracts/${passkeyStorageName}.sol/${passkeyStorageName}.json`;

  console.log(`\nDeploying to ${network}`);

  console.log(`\nDeploying ${passkeyStorageName} with the account: ${relayer.address}`);
  const passkeyStorageFactory = await ethers.getContractFactory(passkeyStorageName, relayer);
  const passkeyStorage = await passkeyStorageFactory.deploy();
  await passkeyStorage.waitForDeployment();

  /* Abi files make */
  await makeAbi(passkeyStorageName, passkeyStorage.target, passkeyStorageDeparture, env);
  console.log(`\n${passkeyStorageName} contract deployed at: ${passkeyStorage.target}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
