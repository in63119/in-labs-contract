import {ethers} from "hardhat";
import {makeAbi} from "../utils/abi.util";
import {getNetwork, getEnv} from "../utils/deploy.util";

async function main() {
  const [owner, relayer1, relayer2, relayer3] = await ethers.getSigners();

  const network = getNetwork();
  const env = getEnv();

  const contractName = "RelayerManager"; // 배포할 컨트랙트 이름
  const contractDeparture = `/artifacts/contracts/${contractName}.sol/${contractName}.json`; // ABI 참조 파일

  console.log(`\nDeploying to ${network}`);

  console.log(`\nDeploying ${contractName} with the account: ${owner.address}`);
  const factory = await ethers.getContractFactory(contractName, owner);
  const contract = await factory.deploy();
  await contract.waitForDeployment();

  /* Add Relayer */
  console.log(`\nAdd Relayer with the account: ${relayer1.address}`);
  const addRelayer1 = await contract.addRelayer(await relayer1.getAddress());
  await addRelayer1.wait();
  console.log(`Add Relayer with the account: ${relayer2.address}`);
  const addRelayer2 = await contract.addRelayer(await relayer2.getAddress());
  await addRelayer2.wait();
  console.log(`Add Relayer with the account: ${relayer3.address}`);
  const addRelayer3 = await contract.addRelayer(await relayer3.getAddress());
  await addRelayer3.wait();

  /* Abi files make */
  await makeAbi(contractName, contract.target, contractDeparture, env);
  console.log(`\n${contractName} contract deployed at: ${contract.target}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
