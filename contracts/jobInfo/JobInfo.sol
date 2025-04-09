// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./BaseJobInfo.sol";

contract JobInfo is BaseJobInfo {
    constructor(
        address _jobCreator,
        address _protocolWallet,
        address[] memory _rewardTokens,
        uint256[] memory _rewardAmount
    ) {
        __BaseJobInfo_init(
            _jobCreator,
            _protocolWallet,
            _rewardTokens,
            _rewardAmount
        );
    }

    function sendRewards(
        address _user
    ) external onlyAuthorizedAccess nonReentrant {
        if (_user == address(0)) revert ZeroAddress();
        if (hasReceivedReward[_user]) revert RewardAlreadyDistributed(_user);

        hasReceivedReward[_user] = true;
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            bool success = IERC20(rewardTokens[i]).transfer(
                _user,
                rewardTokensToAmount[rewardTokens[i]]
            );
            if (!success) revert TransferFailed();
        }
        emit RewardsSent(_user);
    }

    function batchSendRewards(
        address[] calldata _users
    )
        external
        onlyAuthorizedAccess
        nonReentrant
        returns (uint256 successCount)
    {
        uint256 userCount = _users.length;

        uint256 tokenCount = rewardTokens.length;
        address[] memory tokens = new address[](tokenCount);
        uint256[] memory amounts = new uint256[](tokenCount);

        for (uint256 i = 0; i < tokenCount; i++) {
            tokens[i] = rewardTokens[i];
            amounts[i] = rewardTokensToAmount[tokens[i]];
        }

        for (uint256 i = 0; i < userCount; i++) {
            address user = _users[i];
            if (user == address(0) || hasReceivedReward[user]) {
                continue;
            }

            hasReceivedReward[user] = true;
            bool allTransfersSuccessful = true;

            for (uint256 j = 0; j < tokenCount; j++) {
                try IERC20(tokens[j]).transfer(user, amounts[j]) {} catch {
                    allTransfersSuccessful = false;
                    break;
                }
            }

            if (allTransfersSuccessful) {
                successCount++;
                emit RewardsSent(user);
            } else {
                hasReceivedReward[user] = false;
            }
        }

        emit BatchRewardsSent(_users, successCount);
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

    function changeJobStatus() external nonReentrant onlyJobCreator {
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
