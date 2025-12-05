import {getEnv} from "../utils/deploy.util";
import {accounts, getContract} from "../utils/ethers.util";

import AuthStorageDev from "../abis/kaia/test/development/AuthStorage.json";
import AuthStorageProd from "../abis/kaia/test/production/AuthStorage.json";

import prevPostStorageDev from "../archive/abis/development/PostStorage.json";
import prevPostStorageProd from "../archive/abis/production/PostStorage.json";
import nextPostStorageDev from "../abis/kaia/test/development/PostStorage.json";
import nextPostStorageProd from "../abis/kaia/test/production/PostStorage.json";

const authStorageABI = getEnv() === "development" ? AuthStorageDev : AuthStorageProd;
const prevPostStorageABI = getEnv() === "development" ? prevPostStorageDev : prevPostStorageProd;
const nextPostStorageABI = getEnv() === "development" ? nextPostStorageDev : nextPostStorageProd;

async function migrate() {
  const owner = accounts().owner;
  const relayer = accounts().relayer1;

  const authStorage = getContract(authStorageABI.address, authStorageABI.abi).connect(
    relayer,
  ) as any;
  const prevPostStorage = getContract(prevPostStorageABI.address, prevPostStorageABI.abi);
  const nextPostStorage = getContract(nextPostStorageABI.address, nextPostStorageABI.abi).connect(
    owner,
  ) as any;

  const users = await authStorage.getUserAddresses();
  const posts: Record<string, {recipient: string; uri: string}[]> = {};

  for (const user of users) {
    const userPosts = await prevPostStorage.getPosts(user);
    posts[user] = userPosts.map((p: any) => ({
      recipient: user,
      uri: p.uri,
    }));
  }

  for (const post in posts) {
    const migrate = await nextPostStorage.migrate(posts[post]);
    await migrate.wait();
  }

  const nextPosts: Record<string, {recipient: string; uri: string}[]> = {};
  for (const user of users) {
    const userPosts = await nextPostStorage.getPosts(user);
    nextPosts[user] = userPosts.map((p: any) => ({
      recipient: user,
      uri: p.uri,
    }));
  }

  console.log("Migration done!");
  console.log(nextPosts);
}

migrate().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
