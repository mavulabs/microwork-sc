require("@nomicfoundation/hardhat-toolbox");
// require("@nomiclabs/hardhat-ethers");
require("dotenv").config();
require("solidity-docgen");

const ALFAJORES_PRIVATE_KEY =
    "42591bb3181d8e60d88b9e50eea9d872ef6f2a3fc6205d4c0b10862bbb6d0530";

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
    solidity: "0.8.24",
    networks: {
        alfajores: {
            url: `https://alfajores-forno.celo-testnet.org`,
            accounts: [ALFAJORES_PRIVATE_KEY],
        },
        alfajores2: {
            url: `https://celo-alfajores.infura.io/v3/` + process.env.API_KEY,
            accounts: [ALFAJORES_PRIVATE_KEY],
        },
        goerli: {
            url: `https://goerli.infura.io/v3/` + process.env.API_KEY,
            accounts: [ALFAJORES_PRIVATE_KEY],
        },
        // goerli1: {
        //     url: `https://goerli.infura.io/v3/` + process.env.API_KEY,
        //     accounts: [process.env.PRIVATE_KEY_goerli_1],
        // },
        // goerli2: {
        //     url: `https://goerli.infura.io/v3/` + process.env.API_KEY,
        //     accounts: [process.env.PRIVATE_KEY_goerli_2],
        // },
    },
};
