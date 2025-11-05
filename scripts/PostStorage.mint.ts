import fs from "fs";
import path from "path";
import {ethers} from "ethers";
import dotenv from "dotenv";

dotenv.config();

const RPC_URL = "https://public-en-kairos.node.kaia.io";
const ENV = "local";
const PRIVATE_KEY = process.env.RELAYER_PRIVATE_KEY;
const URI = "https://example.com";

if (!PRIVATE_KEY) {
  throw new Error("POST_STORAGE_OWNER_KEY is required");
}

const abiPath = path.join(__dirname, `../abis/kaia/test/${ENV}/PostStorage.json`);
if (!fs.existsSync(abiPath)) {
  throw new Error(`ABI file not found at ${abiPath}`);
}

const {abi, address} = JSON.parse(fs.readFileSync(abiPath, "utf-8"));
if (!address) {
  throw new Error("Contract address missing in ABI file");
}

async function main() {
  const provider = new ethers.JsonRpcProvider(RPC_URL);
  const wallet = new ethers.Wallet(PRIVATE_KEY!, provider);
  const contract = new ethers.Contract(address, abi, wallet);

  // const post = await contract.post(await wallet.getAddress(), URI);
  // const tx = await post.wait();
  const posts = await contract.getPosts("0x3E02CfDDc62cBBCC7F51a5cDf584122ef1b4048f");

  // console.log(`Tx hash: ${tx?.hash}`);
  console.log(`Minted postId: ${posts}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
