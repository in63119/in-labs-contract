import {ethers} from "hardhat";
import {makeAbi} from "../utils/abi.util";
import {getNetwork, getEnv} from "../utils/deploy.util";

async function main() {
  const [relayer] = await ethers.getSigners();

  const network = getNetwork();
  const env = getEnv();

  const contractName = "VisitorStorage"; // 배포할 컨트랙트 이름
  const contractDeparture = `/artifacts/contracts/${contractName}.sol/${contractName}.json`; // ABI 참조 파일

  console.log(`\nDeploying to ${network}`);

  console.log(`\nDeploying ${contractName} with the account: ${relayer.address}`);
  const factory = await ethers.getContractFactory(contractName, relayer);
  const contract = await factory.deploy();
  await contract.waitForDeployment();

  /* Abi files make */
  await makeAbi(contractName, contract.target, contractDeparture, env);
  console.log(`\n${contractName} contract deployed at: ${contract.target}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
