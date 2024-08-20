import hre from "hardhat";
// import { Contract } from "ethers";

async function main() {
    const [signer] = await hre.ethers.getSigners();
    const JobFactory = await hre.ethers.getContractFactory("JobFactory");
    const JobFactoryContract = JobFactory.attach(
        "0xaC205731222eD82084a3f063d603D4851A82dE4C"
    ).connect(signer);

    const jobDetails = [
        "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4",
        "0x68656c6c6f",
        "0x68656c6c6f000000000000000000000000000000000000000000000000000000",
        123,
        "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1", //cusd
        "0x2BBB0196EA19065E9BB7E7eDc36cF7105852D818", //mavu
        "0x8f32A73a56B9be59BB459174CDD3630C040c2002", //score
        1,
        12,
        12,
    ];

    const tx = await JobFactoryContract.registerJob(jobDetails);
    await tx.wait();
    console.log(`Tx Hash: ${tx.hash}`);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
