require("@nomicfoundation/hardhat-toolbox");
require("hardhat-gas-reporter");

module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200, // Enable 200-run Solidity optimizer for minimal gas
      },
    },
  },
  gasReporter: {
    enabled: true,
    currency: "USD",
    outputFile: "benchmarks/gas_report.txt",
    noColors: true,
  },
};