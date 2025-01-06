require("@openzeppelin/hardhat-upgrades");
require("@nomicfoundation/hardhat-verify");
require("dotenv").config();

const {_RPC_URL_,PRIVATE_KEY,ETHERSCAN_API_KEY} = process.env;
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  networks: {
    holesky: {
      url: _RPC_URL_,
      accounts: [`0x${PRIVATE_KEY}`],
    },
  },
  sourcify:{
    enabled: true
  },
  etherscan:{
    apiKey:{
      holesky: ETHERSCAN_API_KEY
    },
  }
};