// scripts/deploy.ts
import hre from "hardhat";


async function main() {
    const JobFactory = await hre.ethers.getContractFactory("JobFactory");
    const JobFactoryContract = await JobFactory.deploy();

    await JobFactoryContract.waitForDeployment();

    console.log("JobFactory deployed to:", JobFactoryContract.target);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
