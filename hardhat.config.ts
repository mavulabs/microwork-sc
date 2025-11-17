require("@nomicfoundation/hardhat-toolbox");
// require("@nomiclabs/hardhat-ethers");
require("dotenv").config();
require("@openzeppelin/hardhat-upgrades");
/** @type import('hardhat/config').HardhatUserConfig */
const ALFAJORES_PRIVATE_KEY = process.env.ALFAJORES_PRIVATE_KEY;
module.exports = {
    solidity: "0.8.24",
    paths: {
        tests: "./test",
    },
    mocha: {
        timeout: 40000,
    },
    networks: {
        alfajores: {
            url: `https://alfajores-forno.celo-testnet.org`,
            accounts: [ALFAJORES_PRIVATE_KEY],
            chainId: 44787,
        },
        alfajores2: {
            url: `https://celo-alfajores.infura.io/v3/` + process.env.API_KEY,
            accounts: [ALFAJORES_PRIVATE_KEY],
        },
        goerli: {
            url: `https://goerli.infura.io/v3/` + process.env.API_KEY,
            accounts: [ALFAJORES_PRIVATE_KEY],
        },
        celo: {
            url: "https://forno.celo.org",
            accounts: [ALFAJORES_PRIVATE_KEY],
            chainId: 42220,
        },
    },
    etherscan: {
        apiKey: {
            celo: process.env.CELOSCAN_API_KEY,
            alfajores: process.env.CELOSCAN_API_KEY,
        },
        customChains: [
            {
                network: "celo",
                chainId: 42220,
                urls: {
                    apiURL: "https://api.celoscan.io/api",
                    browserURL: "https://celoscan.io",
                },
            },
            // {
            //     network: "alfajores",
            //     chainId: 44787,
            //     urls: {
            //         apiURL: "https://api-alfajores.celoscan.io/api",
            //         browserURL: "https://alfajores.celoscan.io",
            //     },
            // },
        ],
    },
};
