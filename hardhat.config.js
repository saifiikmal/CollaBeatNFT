require('dotenv').config();
require("@nomicfoundation/hardhat-toolbox");

require('./tasks/deploy')

const { ALCHEMY_API_KEY_GOERLI, ALCHEMY_API_KEY_MUMBAI, PRIVATE_KEY } = process.env 
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  defaultNetwork: "localhost",
  networks: {
    localhost: {
      chainId: 31337,
    },
    goerli: {
      chainId: 5,
      url: `https://eth-goerli.g.alchemy.com/v2/${ALCHEMY_API_KEY_GOERLI}`,
      accounts: [PRIVATE_KEY],
      gas: 5000000,
      // gasPrice: 50000000000
    },
    mumbai: {
      chainId: 80001,
      url: `https://polygon-mumbai.g.alchemy.com/v2/${ALCHEMY_API_KEY_MUMBAI}`,
      accounts: [PRIVATE_KEY],
      gas: 5000000,
      // gasPrice: 50000000000
    },
  }
};
