import hre from "hardhat";
// import { Contract } from "ethers";

async function main() {
    const [signer] = await hre.ethers.getSigners();
    const JobFactory = await hre.ethers.getContractFactory("JobFactory");
    const JobFactoryContract = JobFactory.attach(
        "0x253a70a219965daC78361725a6c91ccf6Aa0C70d"
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
    // const txHash =
    //     "0xfdad4b68d8aeb5199cfa7792dae8ba9f20c40e0249b0fbb6b75039f5efa898a0";
    const txHash = tx.hash;

    const provider = await hre.ethers.provider;
    const txReceipt = await provider.getTransactionReceipt(txHash);
    // const contractInterface = new hre.ethers.Interface(jobFactoryAbi);
    console.log({ txReceipt });
    console.log(txReceipt.logs);
    const contractInterface = JobFactory.interface;
    for (const log of txReceipt.logs) {
        try {
            const event = contractInterface.parseLog(log);
            console.log("Event:", event);
            const JobInfoAddress = event.args[0];
            console.log({ JobInfoAddress });
        } catch (error) {
            // Ignore events that don't match the expected signature
            console.log({ error });
        }
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
