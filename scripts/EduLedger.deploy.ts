import {ethers} from "hardhat";
import {makeAbi} from "../utils/abi.util";
import {getNetwork, getEnv} from "../utils/deploy.util";

async function main() {
  const [proxyOwner, authOwner, attendanceOwner, ledgerOwner, relayer] =
    await ethers.getSigners();

  const network = getNetwork();
  const env = getEnv();

  const eduLedgerName = "EduLedger";
  const proxyContractName = "EduLedgerProxy";
  const instructorLedgerName = "InstructorLedger";
  const inAuthenticatorName = "InAuthenticator";
  const viewEduName = "ViewEdu";

  const eduLedgerDeparture = `/artifacts/contracts/edu-ledger/${eduLedgerName}.sol/${eduLedgerName}.json`;
  const proxyContractDeparture = `/artifacts/contracts/edu-ledger/${proxyContractName}.sol/${proxyContractName}.json`;
  const inAuthenticatorDeparture = `/artifacts/contracts/auth/${inAuthenticatorName}.sol/${inAuthenticatorName}.json`;
  const instructorLedgerDeparture = `/artifacts/contracts/instructor-ledger/${instructorLedgerName}.sol/${instructorLedgerName}.json`;
  const viewEduDeparture = `/artifacts/contracts/edu-ledger/${viewEduName}.sol/${viewEduName}.json`;

  console.log(`\nDeploying to ${network}`);

  console.log(
    `\nDeploying ${eduLedgerName} with the account: ${ledgerOwner.address}`,
  );
  const eduLedgerFactory = await ethers.getContractFactory(
    eduLedgerName,
    ledgerOwner,
  );
  const EduLedger = await eduLedgerFactory.deploy();
  await EduLedger.waitForDeployment();

  console.log(
    `\nDeploying ${inAuthenticatorName} with the account: ${authOwner.address}`,
  );
  const authFactory = await ethers.getContractFactory(
    inAuthenticatorName,
    authOwner,
  );
  const InAuthenticator = await authFactory.deploy();
  await InAuthenticator.waitForDeployment();

  console.log(
    `\nDeploying ${instructorLedgerName} with the account: ${ledgerOwner.address}`,
  );
  const instructorLedgerFactory = await ethers.getContractFactory(
    instructorLedgerName,
    ledgerOwner,
  );
  const InstructorLedger = await instructorLedgerFactory.deploy(
    InAuthenticator.target,
  );
  await InstructorLedger.waitForDeployment();

  console.log(
    `\nDeploying ${proxyContractName} with the account: ${ledgerOwner.address}`,
  );
  const proxyFactory = await ethers.getContractFactory(
    proxyContractName,
    proxyOwner,
  );
  const EduLedgerProxy = await proxyFactory.deploy(EduLedger.target);
  await EduLedgerProxy.waitForDeployment();

  const proxyAsEduLedger = eduLedgerFactory.attach(
    EduLedgerProxy.target,
  ) as unknown as {
    initialize: (
      authenticator: string,
      instructorLedgerAddr: string,
    ) => Promise<any>;
  };
  const initialize = await proxyAsEduLedger.initialize(
    await InAuthenticator.getAddress(),
    await InstructorLedger.getAddress(),
  );
  await initialize.wait();

  console.log(
    `\nDeploying ${viewEduName} with the account: ${ledgerOwner.address}`,
  );
  const viewFactory = await ethers.getContractFactory(viewEduName, ledgerOwner);
  const ViewEdu = await viewFactory.deploy(EduLedgerProxy.target);
  await ViewEdu.waitForDeployment();

  console.log(`\nEdu roles setting...`);
  await InAuthenticator.grantManager(relayer.address);
  await InAuthenticator.grantSystem(EduLedgerProxy.target);
  await InAuthenticator.grantSystem(InstructorLedger.target);

  /* Abi files make */
  await makeAbi(eduLedgerName, EduLedgerProxy.target, eduLedgerDeparture, env);
  console.log(
    `\n${eduLedgerName} contract deployed at: ${EduLedgerProxy.target}`,
  );
  await makeAbi(
    proxyContractName,
    EduLedgerProxy.target,
    proxyContractDeparture,
    env,
  );
  console.log(
    `\n${proxyContractName} contract deployed at: ${EduLedgerProxy.target}`,
  );
  await makeAbi(
    inAuthenticatorName,
    InAuthenticator.target,
    inAuthenticatorDeparture,
    env,
  );
  console.log(
    `\n${inAuthenticatorName} contract deployed at: ${InAuthenticator.target}`,
  );
  await makeAbi(
    instructorLedgerName,
    InstructorLedger.target,
    instructorLedgerDeparture,
    env,
  );
  console.log(
    `\n${instructorLedgerName} contract deployed at: ${InstructorLedger.target}`,
  );
  await makeAbi(viewEduName, ViewEdu.target, viewEduDeparture, env);
  console.log(`\n${viewEduName} contract deployed at: ${ViewEdu.target}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
