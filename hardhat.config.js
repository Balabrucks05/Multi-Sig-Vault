require("@openzeppelin/hardhat-upgrades");
require("@nomicfoundation/hardhat-ethers");
require("@nomicfoundation/hardhat-verify");
require("dotenv").config();

const {_RPC_URL_,BSC_RPC_URL_,PRIVATE_KEY,ETHERSCAN_API_KEY,BSCTESTNET_API_KEY} = process.env;
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  networks: {
    // holesky: {
    //   url: _RPC_URL_,
    //   accounts: [`0x${PRIVATE_KEY}`],
    // },
    bscTestnet: {
      url: BSC_RPC_URL_,
      accounts: [`0x${PRIVATE_KEY}`],
    }
  },
  sourcify:{
    enabled: true
  },
  etherscan:{
    apiKey:{
      bscTestnet: BSCTESTNET_API_KEY,
      holesky: ETHERSCAN_API_KEY
    },
  }
};