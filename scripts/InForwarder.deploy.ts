import {ethers} from "hardhat";
import {makeAbi} from "../utils/abi.util";
import {getNetwork, getEnv} from "../utils/deploy.util";
import RelayerManeger from "../abis/kaia/test/production/RelayerManager.json";

async function main() {
  const [owner] = await ethers.getSigners();

  const network = getNetwork();
  const env = getEnv();

  const inForwarderContractName = "InForwarder";
  const inForwarderDeparture = `/artifacts/contracts/${inForwarderContractName}.sol/${inForwarderContractName}.json`;

  const relayerManagerAddress = RelayerManeger.address;

  console.log(`\nDeploying to ${network}`);

  console.log(`\nDeploying ${inForwarderContractName} with the account: ${owner.address}`);
  const inForwarderFactory = await ethers.getContractFactory(inForwarderContractName, owner);
  const inForwarder = await inForwarderFactory.deploy(
    inForwarderContractName,
    relayerManagerAddress,
  );
  await inForwarder.waitForDeployment();

  const inForwarderAddress = await inForwarder.getAddress();

  /* Abi files make */
  await makeAbi(inForwarderContractName, inForwarderAddress, inForwarderDeparture, env);
  console.log(`\n${inForwarderContractName} contract deployed at: ${inForwarderAddress}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
