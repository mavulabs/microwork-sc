// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./BaseJobInfo.sol";

contract JobInfo is BaseJobInfo {
    constructor(
        address _jobCreator,
        address[] memory _rewardTokens,
        uint256[] memory _rewardAmount,
        bytes32 _jobUniqueIdentifier
    ) {
        __BaseJobInfo_init(
            _jobCreator,
            _rewardTokens,
            _rewardAmount,
            _jobUniqueIdentifier
        );
    }

<<<<<<< Updated upstream
    function _sendRewards(
        address _userAddress,
        bytes32 _jobIdentifier
    ) external {
        if (_userAddress == address(0)) revert ZeroAddress();
        bytes32 _jobIdentifierHash = hashStringGeneratorForJob(_jobIdentifier);
        if (_jobIdentifierHash != jobIdentifierHash) revert InvalidJob();

=======
    function sendRewards(bytes32 _jobIdentifier) external nonReentrant {
        if (msg.sender == address(0)) revert ZeroAddress();
        if (hasReceivedReward[msg.sender])
            revert RewardAlreadyDistributed(msg.sender);
        bytes32 _jobIdentifierHash = hashStringGeneratorForJob(_jobIdentifier);
        if (_jobIdentifierHash != jobIdentifierHash) revert InvalidJob();

        hasReceivedReward[msg.sender] = true;
>>>>>>> Stashed changes
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            bool success = IERC20(rewardTokens[i]).transfer(
                msg.sender,
                rewardTokensToAmount[rewardTokens[i]]
            );
            if (!success) revert TransferFailed();
        }
        emit RewardsSent(msg.sender);
    }

    function setRewardsAmount(
        address[] calldata _rewardTokens,
        uint256[] calldata _rewardAmounts
    ) external onlyJobCreator {
        _updateRewards(_rewardTokens, _rewardAmounts);
    }

    function withdrawToken(
        address tokenAddress,
        uint256 amount
    ) external nonReentrant onlyJobCreator validToken(tokenAddress) {
        bool success = IERC20(tokenAddress).transfer(jobCreator, amount);
        if (!success) revert TransferFailed();

        emit WithdrawalCompleted(jobCreator, amount, tokenAddress);
    }

    function chnageJobStatus() external nonReentrant onlyJobCreator {
        if (!jobStatus) revert JobAlreadyDone();

        jobStatus = false;
    }

    function isAReward(address tokenAddress) public view returns (bool) {
        if (rewardTokensToAmount[tokenAddress] > 0) {
            return true;
        } else {
            return false;
        }
    }

    function getRewardAmount(
        address tokenAddress
    ) public view returns (uint256) {
        return rewardTokensToAmount[tokenAddress];
    }

    function getJobInfo() external view returns (address, bool) {
        return (jobCreator, jobStatus);
    }
}
