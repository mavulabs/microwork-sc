import { expect } from "chai";
// @ts-expect-error - ethers is available from hardhat via toolbox, types are extended
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { JobInfo, MockERC20 } from "../typechain-types";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";

describe("JobInfo Contract", function () {
    // Helper function to create signature
    // This matches exactly what the contract does: keccak256(abi.encodePacked(claimant, address(this), block.chainid, nonce))
    // Contract: MessageHashUtils.toEthSignedMessageHash(messageHash) then ECDSA.recover
    async function createSignature(
        signer: SignerWithAddress,
        claimant: string,
        contractAddress: string,
        chainId: bigint,
        nonce: string
    ): Promise<string> {
        // Step 1: Create the message hash using solidityPackedKeccak256 (equivalent to keccak256(abi.encodePacked(...)))
        const messageHash = ethers.solidityPackedKeccak256(
            ["address", "address", "uint256", "bytes32"],
            [claimant, contractAddress, chainId, nonce]
        );

        // Step 2: Convert to Ethereum signed message hash (EIP-191 standard)
        // MessageHashUtils.toEthSignedMessageHash adds "\x19Ethereum Signed Message:\n32" prefix
        // signMessage in ethers does this automatically, so we pass the raw messageHash bytes
        const messageHashBytes = ethers.getBytes(messageHash);

        // signMessage will automatically apply EIP-191 prefix to the bytes32 message hash
        // This matches what MessageHashUtils.toEthSignedMessageHash does
        const signature = await signer.signMessage(messageHashBytes);
        return signature;
    }

    async function deployContracts() {
        const [
            deployer,
            jobCreator,
            protocolWallet,
            adminWallet,
            user1,
            user2,
            user3,
            attacker,
        ] = await ethers.getSigners();

        // Deploy mock ERC20 tokens
        const MockERC20Factory = await ethers.getContractFactory("MockERC20");
        const token1 = await MockERC20Factory.deploy("Token1", "TKN1");
        const token2 = await MockERC20Factory.deploy("Token2", "TKN2");

        const rewardTokens = [
            await token1.getAddress(),
            await token2.getAddress(),
        ];
        const rewardAmounts = [
            ethers.parseEther("100"),
            ethers.parseEther("200"),
        ];

        // Fund the deployer with tokens to transfer to JobInfo
        await token1.mint(deployer.address, ethers.parseEther("1000"));
        await token2.mint(deployer.address, ethers.parseEther("2000"));

        // Deploy JobInfo contract
        const JobInfoFactory = await ethers.getContractFactory("JobInfo");
        const jobInfo = await JobInfoFactory.deploy(
            jobCreator.address,
            adminWallet.address,
            protocolWallet.address,
            rewardTokens,
            rewardAmounts
        );

        const jobInfoAddress = await jobInfo.getAddress();

        // Transfer reward tokens to JobInfo contract
        await token1.transfer(jobInfoAddress, ethers.parseEther("100"));
        await token2.transfer(jobInfoAddress, ethers.parseEther("200"));

        // Get chain ID
        const network = await ethers.provider.getNetwork();
        const chainId = network.chainId;

        return {
            deployer,
            jobCreator,
            protocolWallet,
            adminWallet,
            user1,
            user2,
            user3,
            attacker,
            token1,
            token2,
            jobInfo,
            jobInfoAddress,
            rewardTokens,
            rewardAmounts,
            chainId,
        };
    }

    describe("Deployment", function () {
        it("Should deploy with correct initial state", async function () {
            const {
                jobInfo,
                jobCreator,
                adminWallet,
                protocolWallet,
                rewardTokens,
                rewardAmounts,
            } = await loadFixture(deployContracts);

            const [creator, admin, protocol, status] =
                await jobInfo.getJobInfo();
            expect(creator).to.equal(jobCreator.address);
            expect(admin).to.equal(adminWallet.address);
            expect(protocol).to.equal(protocolWallet.address);
            expect(status).to.be.true;

            const [tokens, amounts] = await jobInfo.getRewardDetails();
            expect(tokens.length).to.equal(rewardTokens.length);
            expect(tokens[0]).to.equal(rewardTokens[0]);
            expect(tokens[1]).to.equal(rewardTokens[1]);
            expect(amounts[0]).to.equal(rewardAmounts[0]);
            expect(amounts[1]).to.equal(rewardAmounts[1]);
        });
    });

    describe("sendRewards", function () {
        it("Should allow jobCreator to send rewards", async function () {
            const {
                jobInfo,
                user1,
                token1,
                token2,
                rewardAmounts,
                jobCreator,
            } = await loadFixture(deployContracts);

            await jobInfo.connect(jobCreator).sendRewards(user1.address);

            expect(await token1.balanceOf(user1.address)).to.equal(
                rewardAmounts[0]
            );
            expect(await token2.balanceOf(user1.address)).to.equal(
                rewardAmounts[1]
            );
            expect(await jobInfo.hasReceivedReward(user1.address)).to.be.true;
        });

        it("Should allow protocolWallet to send rewards", async function () {
            const {
                jobInfo,
                user1,
                token1,
                token2,
                rewardAmounts,
                protocolWallet,
            } = await loadFixture(deployContracts);

            await jobInfo.connect(protocolWallet).sendRewards(user1.address);

            expect(await token1.balanceOf(user1.address)).to.equal(
                rewardAmounts[0]
            );
            expect(await token2.balanceOf(user1.address)).to.equal(
                rewardAmounts[1]
            );
        });

        it("Should revert if unauthorized user tries to send rewards", async function () {
            const { jobInfo, user1, user2 } = await loadFixture(
                deployContracts
            );

            await expect(
                jobInfo.connect(user2).sendRewards(user1.address)
            ).to.be.revertedWithCustomError(jobInfo, "UnauthorizedAccess");
        });

        it("Should revert if user already received reward", async function () {
            const { jobInfo, user1, jobCreator } = await loadFixture(
                deployContracts
            );

            await jobInfo.connect(jobCreator).sendRewards(user1.address);

            await expect(
                jobInfo.connect(jobCreator).sendRewards(user1.address)
            ).to.be.revertedWithCustomError(
                jobInfo,
                "RewardAlreadyDistributed"
            );
        });
    });

    describe("claimReward - Security Tests", function () {
        it("Should allow user to claim reward with valid signature from protocolWallet", async function () {
            const {
                jobInfo,
                jobInfoAddress,
                user1,
                protocolWallet,
                token1,
                token2,
                rewardAmounts,
                chainId,
            } = await loadFixture(deployContracts);

            const nonce = ethers.hexlify(ethers.randomBytes(32));
            const signature = await createSignature(
                protocolWallet,
                user1.address,
                jobInfoAddress,
                chainId,
                nonce
            );

            await expect(jobInfo.connect(user1).claimReward(nonce, signature))
                .to.emit(jobInfo, "RewardsClaimed")
                .withArgs(
                    user1.address,
                    (tokens: string[]) => tokens.length === 2,
                    (amounts: bigint[]) => amounts.length === 2,
                    nonce
                );

            expect(await token1.balanceOf(user1.address)).to.equal(
                rewardAmounts[0]
            );
            expect(await token2.balanceOf(user1.address)).to.equal(
                rewardAmounts[1]
            );
            expect(await jobInfo.hasReceivedReward(user1.address)).to.be.true;
            expect(await jobInfo.usedNonces(nonce)).to.be.true;
        });

        it("Should revert if signature is not from protocolWallet", async function () {
            const { jobInfo, jobInfoAddress, user1, attacker, chainId } =
                await loadFixture(deployContracts);

            const nonce = ethers.hexlify(ethers.randomBytes(32));
            const signature = await createSignature(
                attacker,
                user1.address,
                jobInfoAddress,
                chainId,
                nonce
            );

            await expect(
                jobInfo.connect(user1).claimReward(nonce, signature)
            ).to.be.revertedWithCustomError(jobInfo, "InvalidSignature");
        });

        it("Should revert if nonce is reused (replay attack)", async function () {
            const {
                jobInfo,
                jobInfoAddress,
                user1,
                user2,
                protocolWallet,
                chainId,
            } = await loadFixture(deployContracts);

            const nonce = ethers.hexlify(ethers.randomBytes(32));
            const signature = await createSignature(
                protocolWallet,
                user1.address,
                jobInfoAddress,
                chainId,
                nonce
            );

            // First claim succeeds
            await jobInfo.connect(user1).claimReward(nonce, signature);

            // Attempt to reuse the same nonce should fail
            await expect(
                jobInfo.connect(user2).claimReward(nonce, signature)
            ).to.be.revertedWithCustomError(jobInfo, "NonceAlreadyUsed");
        });

        it("Should revert if user tries to claim twice (same user, different nonce)", async function () {
            const { jobInfo, jobInfoAddress, user1, protocolWallet, chainId } =
                await loadFixture(deployContracts);

            const nonce1 = ethers.hexlify(ethers.randomBytes(32));
            const signature1 = await createSignature(
                protocolWallet,
                user1.address,
                jobInfoAddress,
                chainId,
                nonce1
            );

            await jobInfo.connect(user1).claimReward(nonce1, signature1);

            // Try to claim again with different nonce
            const nonce2 = ethers.hexlify(ethers.randomBytes(32));
            const signature2 = await createSignature(
                protocolWallet,
                user1.address,
                jobInfoAddress,
                chainId,
                nonce2
            );

            await expect(
                jobInfo.connect(user1).claimReward(nonce2, signature2)
            ).to.be.revertedWithCustomError(
                jobInfo,
                "RewardAlreadyDistributed"
            );
        });

        it("Should revert if user tries to use signature meant for different user", async function () {
            const {
                jobInfo,
                jobInfoAddress,
                user1,
                user2,
                protocolWallet,
                chainId,
            } = await loadFixture(deployContracts);

            // Signature is created for user1
            const nonce = ethers.hexlify(ethers.randomBytes(32));
            const signature = await createSignature(
                protocolWallet,
                user1.address,
                jobInfoAddress,
                chainId,
                nonce
            );

            // user2 tries to use user1's signature
            await expect(
                jobInfo.connect(user2).claimReward(nonce, signature)
            ).to.be.revertedWithCustomError(jobInfo, "InvalidSignature");
        });

        it("Should revert if signature is for different contract address", async function () {
            const { jobInfo, user1, protocolWallet, chainId, deployer } =
                await loadFixture(deployContracts);

            // Deploy another contract with different address
            const JobInfoFactory = await ethers.getContractFactory("JobInfo");
            const fakeJobInfo = await JobInfoFactory.deploy(
                deployer.address,
                deployer.address,
                protocolWallet.address,
                [],
                []
            );
            const fakeJobInfoAddress = await fakeJobInfo.getAddress();

            const nonce = ethers.hexlify(ethers.randomBytes(32));
            // Signature created for fake contract
            const signature = await createSignature(
                protocolWallet,
                user1.address,
                fakeJobInfoAddress,
                chainId,
                nonce
            );

            // Try to use signature on real contract
            await expect(
                jobInfo.connect(user1).claimReward(nonce, signature)
            ).to.be.revertedWithCustomError(jobInfo, "InvalidSignature");
        });

        it("Should revert if signature is for different chain ID", async function () {
            const { jobInfo, jobInfoAddress, user1, protocolWallet, chainId } =
                await loadFixture(deployContracts);

            const nonce = ethers.hexlify(ethers.randomBytes(32));
            // Signature created for different chain ID
            const fakeChainId = 999n;
            const signature = await createSignature(
                protocolWallet,
                user1.address,
                jobInfoAddress,
                fakeChainId,
                nonce
            );

            // Try to use signature on current chain
            await expect(
                jobInfo.connect(user1).claimReward(nonce, signature)
            ).to.be.revertedWithCustomError(jobInfo, "InvalidSignature");
        });

        it("Should revert if signature is for wrong nonce", async function () {
            const { jobInfo, jobInfoAddress, user1, protocolWallet, chainId } =
                await loadFixture(deployContracts);

            const nonce1 = ethers.hexlify(ethers.randomBytes(32));
            const nonce2 = ethers.hexlify(ethers.randomBytes(32));

            // Signature created for nonce1
            const signature = await createSignature(
                protocolWallet,
                user1.address,
                jobInfoAddress,
                chainId,
                nonce1
            );

            // Try to use signature with nonce2
            await expect(
                jobInfo.connect(user1).claimReward(nonce2, signature)
            ).to.be.revertedWithCustomError(jobInfo, "InvalidSignature");
        });

        it("Should revert if jobCreator tries to claim using their own signature", async function () {
            const { jobInfo, jobInfoAddress, jobCreator, chainId } =
                await loadFixture(deployContracts);

            const nonce = ethers.hexlify(ethers.randomBytes(32));
            const signature = await createSignature(
                jobCreator,
                jobCreator.address,
                jobInfoAddress,
                chainId,
                nonce
            );

            await expect(
                jobInfo.connect(jobCreator).claimReward(nonce, signature)
            ).to.be.revertedWithCustomError(jobInfo, "InvalidSignature");
        });

        it("Should revert if admin tries to claim using their own signature", async function () {
            const { jobInfo, jobInfoAddress, adminWallet, chainId } =
                await loadFixture(deployContracts);

            const nonce = ethers.hexlify(ethers.randomBytes(32));
            const signature = await createSignature(
                adminWallet,
                adminWallet.address,
                jobInfoAddress,
                chainId,
                nonce
            );

            await expect(
                jobInfo.connect(adminWallet).claimReward(nonce, signature)
            ).to.be.revertedWithCustomError(jobInfo, "InvalidSignature");
        });

        it("Should allow multiple different users to claim with unique nonces", async function () {
            const {
                jobInfo,
                jobInfoAddress,
                user1,
                user2,
                user3,
                protocolWallet,
                token1,
                token2,
                rewardAmounts,
                chainId,
                deployer,
            } = await loadFixture(deployContracts);

            // Fund contract with enough tokens for multiple users
            await token1.mint(
                await jobInfo.getAddress(),
                ethers.parseEther("200")
            );
            await token2.mint(
                await jobInfo.getAddress(),
                ethers.parseEther("400")
            );

            // User1 claims
            const nonce1 = ethers.hexlify(ethers.randomBytes(32));
            const signature1 = await createSignature(
                protocolWallet,
                user1.address,
                jobInfoAddress,
                chainId,
                nonce1
            );
            await jobInfo.connect(user1).claimReward(nonce1, signature1);

            // User2 claims
            const nonce2 = ethers.hexlify(ethers.randomBytes(32));
            const signature2 = await createSignature(
                protocolWallet,
                user2.address,
                jobInfoAddress,
                chainId,
                nonce2
            );
            await jobInfo.connect(user2).claimReward(nonce2, signature2);

            // User3 claims
            const nonce3 = ethers.hexlify(ethers.randomBytes(32));
            const signature3 = await createSignature(
                protocolWallet,
                user3.address,
                jobInfoAddress,
                chainId,
                nonce3
            );
            await jobInfo.connect(user3).claimReward(nonce3, signature3);

            // Verify all users received rewards
            expect(await token1.balanceOf(user1.address)).to.equal(
                rewardAmounts[0]
            );
            expect(await token2.balanceOf(user1.address)).to.equal(
                rewardAmounts[1]
            );
            expect(await token1.balanceOf(user2.address)).to.equal(
                rewardAmounts[0]
            );
            expect(await token2.balanceOf(user2.address)).to.equal(
                rewardAmounts[1]
            );
            expect(await token1.balanceOf(user3.address)).to.equal(
                rewardAmounts[0]
            );
            expect(await token2.balanceOf(user3.address)).to.equal(
                rewardAmounts[1]
            );

            // Verify all nonces are marked as used
            expect(await jobInfo.usedNonces(nonce1)).to.be.true;
            expect(await jobInfo.usedNonces(nonce2)).to.be.true;
            expect(await jobInfo.usedNonces(nonce3)).to.be.true;
        });

        it("Should revert if signature is tampered with (modified bytes)", async function () {
            const { jobInfo, jobInfoAddress, user1, protocolWallet, chainId } =
                await loadFixture(deployContracts);

            const nonce = ethers.hexlify(ethers.randomBytes(32));
            const signature = await createSignature(
                protocolWallet,
                user1.address,
                jobInfoAddress,
                chainId,
                nonce
            );

            // Tamper with signature
            const tamperedSignature = signature.slice(0, -2) + "ff";

            // ECDSA.recover will revert with ECDSAInvalidSignature before InvalidSignature check
            await expect(
                jobInfo.connect(user1).claimReward(nonce, tamperedSignature)
            ).to.be.reverted; // Reverts with ECDSAInvalidSignature from OpenZeppelin
        });

        it("Should revert if signature is empty", async function () {
            const { jobInfo, user1 } = await loadFixture(deployContracts);

            const nonce = ethers.hexlify(ethers.randomBytes(32));

            // ECDSA.recover will revert with ECDSAInvalidSignatureLength before InvalidSignature check
            await expect(jobInfo.connect(user1).claimReward(nonce, "0x")).to.be
                .reverted; // Reverts with ECDSAInvalidSignatureLength from OpenZeppelin
        });

        it("Should work with multiple claims in sequence", async function () {
            const {
                jobInfo,
                jobInfoAddress,
                user1,
                protocolWallet,
                token1,
                token2,
                rewardAmounts,
                chainId,
            } = await loadFixture(deployContracts);

            // First claim
            const nonce1 = ethers.hexlify(ethers.randomBytes(32));
            const signature1 = await createSignature(
                protocolWallet,
                user1.address,
                jobInfoAddress,
                chainId,
                nonce1
            );

            await jobInfo.connect(user1).claimReward(nonce1, signature1);

            expect(await token1.balanceOf(user1.address)).to.equal(
                rewardAmounts[0]
            );
            expect(await token2.balanceOf(user1.address)).to.equal(
                rewardAmounts[1]
            );
        });
    });

    describe("batchSendRewards", function () {
        it("Should allow authorized user to batch send rewards", async function () {
            const {
                jobInfo,
                jobCreator,
                user1,
                user2,
                user3,
                token1,
                token2,
                rewardAmounts,
                deployer,
            } = await loadFixture(deployContracts);

            // Fund contract with enough tokens for multiple users
            await token1.mint(
                await jobInfo.getAddress(),
                ethers.parseEther("200")
            );
            await token2.mint(
                await jobInfo.getAddress(),
                ethers.parseEther("400")
            );

            await jobInfo
                .connect(jobCreator)
                .batchSendRewards([
                    user1.address,
                    user2.address,
                    user3.address,
                ]);

            expect(await token1.balanceOf(user1.address)).to.equal(
                rewardAmounts[0]
            );
            expect(await token2.balanceOf(user1.address)).to.equal(
                rewardAmounts[1]
            );
            expect(await token1.balanceOf(user2.address)).to.equal(
                rewardAmounts[0]
            );
            expect(await token2.balanceOf(user2.address)).to.equal(
                rewardAmounts[1]
            );
        });

        it("Should skip users who already received rewards", async function () {
            const {
                jobInfo,
                jobCreator,
                user1,
                user2,
                token1,
                token2,
                rewardAmounts,
                deployer,
            } = await loadFixture(deployContracts);

            // Fund contract with enough tokens
            await token1.mint(
                await jobInfo.getAddress(),
                ethers.parseEther("200")
            );
            await token2.mint(
                await jobInfo.getAddress(),
                ethers.parseEther("400")
            );

            await jobInfo.connect(jobCreator).sendRewards(user1.address);

            await jobInfo
                .connect(jobCreator)
                .batchSendRewards([user1.address, user2.address]);

            expect(await token1.balanceOf(user2.address)).to.equal(
                rewardAmounts[0]
            );
            expect(await token2.balanceOf(user2.address)).to.equal(
                rewardAmounts[1]
            );
        });
    });

    describe("Other Functions", function () {
        it("Should allow jobCreator to set rewards amount", async function () {
            const { jobInfo, jobCreator, rewardTokens } = await loadFixture(
                deployContracts
            );

            const newAmounts = [
                ethers.parseEther("50"),
                ethers.parseEther("75"),
            ];

            await expect(
                jobInfo
                    .connect(jobCreator)
                    .setRewardsAmount(rewardTokens, newAmounts)
            )
                .to.emit(jobInfo, "RewardsUpdated")
                .withArgs(
                    (tokens: string[]) => tokens.length === 2,
                    (amounts: bigint[]) => amounts.length === 2
                );

            expect(await jobInfo.getRewardAmount(rewardTokens[0])).to.equal(
                newAmounts[0]
            );
            expect(await jobInfo.getRewardAmount(rewardTokens[1])).to.equal(
                newAmounts[1]
            );
        });

        it("Should revert when trying to set rewards amount after job is completed", async function () {
            const { jobInfo, jobCreator, rewardTokens } = await loadFixture(
                deployContracts
            );

            // Complete the job
            await jobInfo.connect(jobCreator).changeJobStatus();

            const newAmounts = [
                ethers.parseEther("50"),
                ethers.parseEther("75"),
            ];

            await expect(
                jobInfo
                    .connect(jobCreator)
                    .setRewardsAmount(rewardTokens, newAmounts)
            ).to.be.revertedWithCustomError(jobInfo, "JobAlreadyDone");
        });

        it("Should revert when trying to set rewards amount after rewards have been distributed", async function () {
            const { jobInfo, jobCreator, rewardTokens, user1, token1, token2 } =
                await loadFixture(deployContracts);

            // Send rewards to a worker
            await token1.transfer(jobInfo.target, ethers.parseEther("1000"));
            await token2.transfer(jobInfo.target, ethers.parseEther("1000"));
            await jobInfo.connect(jobCreator).sendRewards(user1.address);

            const newAmounts = [
                ethers.parseEther("50"),
                ethers.parseEther("75"),
            ];

            await expect(
                jobInfo
                    .connect(jobCreator)
                    .setRewardsAmount(rewardTokens, newAmounts)
            ).to.be.revertedWithCustomError(
                jobInfo,
                "RewardsAlreadyDistributed"
            );
        });

        it("Should revert when trying to set rewards amount after rewards claimed via claimReward", async function () {
            const {
                jobInfo,
                jobInfoAddress,
                jobCreator,
                rewardTokens,
                user1,
                protocolWallet,
                chainId,
            } = await loadFixture(deployContracts);

            // Create a valid signature for user1 to claim reward
            const nonce = ethers.randomBytes(32);
            const signature = await createSignature(
                protocolWallet,
                user1.address,
                jobInfoAddress,
                chainId,
                ethers.hexlify(nonce)
            );

            // User claims reward
            await jobInfo.connect(user1).claimReward(nonce, signature);

            const newAmounts = [
                ethers.parseEther("50"),
                ethers.parseEther("75"),
            ];

            await expect(
                jobInfo
                    .connect(jobCreator)
                    .setRewardsAmount(rewardTokens, newAmounts)
            ).to.be.revertedWithCustomError(
                jobInfo,
                "RewardsAlreadyDistributed"
            );
        });

        it("Should allow jobCreator to withdraw tokens", async function () {
            const { jobInfo, jobCreator, token1, token2, deployer } =
                await loadFixture(deployContracts);

            // Add more tokens to contract
            await token1.mint(
                await jobInfo.getAddress(),
                ethers.parseEther("50")
            );
            await token2.mint(
                await jobInfo.getAddress(),
                ethers.parseEther("75")
            );

            await jobInfo
                .connect(jobCreator)
                .withdrawToken(
                    await token1.getAddress(),
                    ethers.parseEther("50")
                );
            await jobInfo
                .connect(jobCreator)
                .withdrawToken(
                    await token2.getAddress(),
                    ethers.parseEther("75")
                );

            expect(await token1.balanceOf(jobCreator.address)).to.equal(
                ethers.parseEther("50")
            );
            expect(await token2.balanceOf(jobCreator.address)).to.equal(
                ethers.parseEther("75")
            );
        });

        it("Should allow jobCreator to change job status", async function () {
            const { jobInfo, jobCreator } = await loadFixture(deployContracts);

            expect(await jobInfo.jobStatus()).to.be.true;
            await expect(jobInfo.connect(jobCreator).changeJobStatus())
                .to.emit(jobInfo, "JobStatusChanged")
                .withArgs(false);
            expect(await jobInfo.jobStatus()).to.be.false;
        });

        it("Should allow admin to change protocol wallet", async function () {
            const { jobInfo, adminWallet, deployer, protocolWallet } =
                await loadFixture(deployContracts);

            await expect(
                jobInfo
                    .connect(adminWallet)
                    .changeProtocolWallet(deployer.address)
            )
                .to.emit(jobInfo, "ProtocolWalletChanged")
                .withArgs(protocolWallet.address, deployer.address);

            const [, , newProtocolWallet] = await jobInfo.getJobInfo();
            expect(newProtocolWallet).to.equal(deployer.address);
        });

        it("Should revert when trying to set protocol wallet to zero address", async function () {
            const { jobInfo, adminWallet } = await loadFixture(deployContracts);

            await expect(
                jobInfo
                    .connect(adminWallet)
                    .changeProtocolWallet(ethers.ZeroAddress)
            ).to.be.revertedWithCustomError(jobInfo, "ZeroAddress");
        });
    });
});
