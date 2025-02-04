// scripts/deploy.ts
import hre from "hardhat";
import { ethers, upgrades } from "hardhat";
// import { upgrades } from "@openzeppelin/hardhat-upgrades";

const deployJobFactory = async function () {
    console.log("Deploying JobFactory contract...");
    const JobFactory = await ethers.getContractFactory("JobFactory");
    console.log("hello");

    const jobFactoryProxy = await upgrades.deployProxy(JobFactory, [], {
        initializer: "initialize",
        kind: "uups",
    });
    console.log("hello2");
    await jobFactoryProxy.waitForDeployment();
    const jobFactoryAddress = await jobFactoryProxy.getAddress();

    console.log("JobFactory deployed to:", jobFactoryAddress);

    // Verify contract on Etherscan if not on localhost
    // if (hre.network.name !== "hardhat" && hre.network.name !== "localhost") {
    //   console.log("Verifying contract on Etherscan...");
    //   try {
    //     await hre.run("verify:verify", {
    //       address: jobFactoryAddress,
    //       constructorArguments: [],
    //     });
    //     console.log("Contract verified successfully");
    //   } catch (error) {
    //     console.log("Error verifying contract:", error);
    //   }
    // }

    return true;
};

async function main() {
    await deployJobFactory();
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
