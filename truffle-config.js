var HDWalletProvider = require("@truffle/hdwallet-provider");
var mnemonic = process.env.TRUFFLE_WALLET_MNEMONIC;
if (mnemonic == null) mnemonic = "xxxxxxxx"

module.exports = {
  contracts_build_directory: "./src/contracts",
  compilers: {
    solc: {
      version: "0.8.1",
      settings: {
        optimizer: {
          enabled: true,
          runs: 5
        },
        evmVersion: "constantinople"
      }
    }
  },
  mocha: {
    useColors: true,
    reporter: 'eth-gas-reporter',
    reporterOptions: {
      currency: 'USD',
      gasPrice: 5
    }
  },
  plugins: ["truffle-contract-size"],
  networks: {
    development: {
      host: "localhost",
      port: 7545,
      network_id: "*",      //Any Network
      gas: 7400000,         //7M Gas Limit
      gasPrice: 5000000000, //5GWei gas price
      skipDryRun: true
    },
    debug: {
      host: "localhost",
      port: 9545,
      network_id: "*",      //Any Network
      gas: 7400000,         //7M Gas Limit
      gasPrice: 5000000000, //5GWei gas price
      skipDryRun: true
    },
  }
};