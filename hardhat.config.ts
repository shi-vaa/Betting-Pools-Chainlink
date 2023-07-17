import * as dotenv from "dotenv";

import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";

dotenv.config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.4",
    settings: {
        optimizer: {
            enabled: true,
            runs: 200,
        },
    },
},
  networks: {
    rinkeby_testnet: {
      url: "https://rinkeby.infura.io/v3/" + process.env.INFURA_ID || "",
      chainId: 4,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    ethereum_mainnet: {
      url: "https://mainnet.infura.io/v3/" + process.env.INFURA_ID || "",
      chainId: 1,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    bsc_testnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545/",
      chainId: 97,
      accounts:
      [process.env.DEPLOYER_PRIVATE_KEY as string],
    },
    bsc_mainnet: {
      url: "https://bsc-dataseed.binance.org/",
      chainId: 56,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    mumbai: {
    url: "https://polygon-mumbai.g.alchemy.com/v2/Wmw4Y8hW2Rio4QCh4nqv_CsnytJIJyMd",
      accounts: [process.env.DEPLOYER_PRIVATE_KEY as string],
      gasPrice: "auto",
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};

export default config;
