require("@nomicfoundation/hardhat-toolbox");
// require("@nomiclabs/hardhat-ethers");
require("dotenv").config();
require("@openzeppelin/hardhat-upgrades");
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
        celo: {
            url: "https://forno.celo.org",
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
