// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./UpgradeableJobInfo.sol";

contract JobInfo is BaseJobInfo {
    constructor(
        address _jobCreator,
        bytes32 _typeOfJob,
        address[] memory _rewardTokens,
        uint256[] memory _rewardAmount
    ) {
        __BaseJobInfo_init(
            _jobCreator,
            _typeOfJob,
            _rewardTokens,
            _rewardAmount
        );
    }

    function startTask(
        address _assignedTo,
        uint256 _deadline,
        // uint256 _taskStatus
        address _evaluator
    ) public {
        if (!jobStatus) revert JobAlreadyDone();
        if (_assignedTo == address(0)) revert ZeroAddress();
        // if (userToTaskId[_assignedTo] != 0) revert TaskAlreadyExists(_assignedTo);
        if (!canStartTask()) revert NotEnoughRewardBalanceToStartTask();

        tasksLength++;
        uint256 _taskId = tasksLength;

        taskIdToInfo[_taskId] = TaskInfo({
            taskAssignee: _assignedTo,
            assignmentEndTime: _deadline,
            taskStatus: 1,
            evaluator: _evaluator
        });

        userToTaskId[_assignedTo] = _taskId;

        emit TaskCreated(_taskId, _assignedTo, _deadline);
    }

    function updateTaskStatus(
        uint256 _taskId,
        uint256 _statusNo
    ) public taskExists(_taskId) {
        if (_statusNo > 7) revert InvalidTaskStatus(_statusNo);
        TaskInfo storage _taskInfo = taskIdToInfo[_taskId];
        if (
            (_statusNo == 1 || _statusNo == 2) &&
            msg.sender != _taskInfo.taskAssignee
        ) revert OnlyTaskAssigneeCanChange(_taskId, _statusNo);
        if (
            (_statusNo == 5 || _statusNo == 6 || _statusNo == 7) &&
            msg.sender != _taskInfo.evaluator
        ) revert OnlyEvaluatorCanChange(_taskId, _statusNo);

        uint256 oldStatus = _taskInfo.taskStatus;
        _taskInfo.taskStatus = _statusNo;

        emit TaskStatusUpdated(_taskId, oldStatus, _statusNo);

        if (_statusNo == 5) {
            _sendRewards(_taskInfo.taskAssignee);
        }
    }

    function _sendRewards(address _userAddress) internal {
        if (_userAddress == address(0)) revert ZeroAddress();

        for (uint256 i = 0; i < rewardTokens.length; i++) {
            bool success = IERC20(rewardTokens[i]).transfer(
                _userAddress,
                rewardTokensToAmount[rewardTokens[i]]
            );
            if (!success) revert TransferFailed();
        }
        emit RewardsSent(_userAddress);
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
        // if (jobStatus) revert JobInProgress();
        if (getUsableReward(tokenAddress) < amount) {
            revert InsufficientBalance();
        }

        emit WithdrawalRequested(jobCreator, amount, tokenAddress);

        bool success = IERC20(tokenAddress).transfer(jobCreator, amount);
        if (!success) revert TransferFailed();

        emit WithdrawalCompleted(jobCreator, amount, tokenAddress);
    }

    function chnageJobStatus() external nonReentrant onlyJobCreator {
        if (!jobStatus) revert JobAlreadyDone();

        jobStatus = false;
    }

    function setEvaluatorType(
        uint256 _evaluatorTypeNo
    ) external onlyJobCreator {
        evaluatorType = _evaluatorTypeNo;
    }

    function setEvaluatorAddress(
        uint256 _taskId,
        address _evaluatorAddress
    ) external onlyJobCreator {
        TaskInfo storage _taskInfo = taskIdToInfo[_taskId];
        _taskInfo.evaluator = _evaluatorAddress;
    }

    function stakeReward(uint256 noOfTasks, address tokenAddress) external {
        uint256 rewardTokenAmount = rewardTokensToAmount[tokenAddress];
        if (rewardTokenAmount == 0) {
            revert NotARewardToken(tokenAddress);
        }
        uint256 totalAmountToStake = noOfTasks * rewardTokenAmount;
        bool success = IERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            totalAmountToStake
        );
        if (!success) revert TransferFailed();
    }

    function isAReward(address tokenAddress) public view returns (bool) {
        if (rewardTokensToAmount[tokenAddress] > 0) {
            return true;
        } else {
            return false;
        }
    }

    function getTotalInProgressTasks() public view returns (uint256) {
        uint256 _totalInProgressTasks;
        for (uint256 i = 1; i <= tasksLength; i++) {
            TaskInfo memory _taskInfo = taskIdToInfo[i];
            if (_taskInfo.taskStatus == 1) {
                _totalInProgressTasks++;
            }
        }
        return _totalInProgressTasks;
    }

    function getUsableReward(
        address tokenAddress
    ) public view returns (uint256) {
        uint256 _rewardTokenAmount = rewardTokensToAmount[tokenAddress];
        uint256 _notUsableAmount = _rewardTokenAmount *
            getTotalInProgressTasks();
        uint256 _totalStakedAmount = IERC20(tokenAddress).balanceOf(
            address(this)
        );
        uint256 _usableAmount = _totalStakedAmount - _notUsableAmount;
        return _usableAmount;
    }

    function canStartTask() public view returns (bool) {
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            uint256 _usableReward = getUsableReward(rewardTokens[i]);
            uint256 _rewardAmount = getRewardAmount(rewardTokens[i]);
            uint256 _startableTasks = _usableReward / _rewardAmount;
            if (_startableTasks <= 0) {
                return false;
            }
        }
        return true;
    }

    function getRewardAmount(
        address tokenAddress
    ) public view returns (uint256) {
        return rewardTokensToAmount[tokenAddress];
    }

    function getJobInfo() external view returns (bool, bytes32) {
        return (jobStatus, typeOfJob);
    }

    function getTaskIdOfUser(
        address _userAddress
    ) external view returns (uint256) {
        return userToTaskId[_userAddress];
    }

    function getTaskStatusOfUser(
        address userAddress
    ) external view returns (uint256) {
        uint256 taskId = userToTaskId[userAddress];
        if (taskId == 0) revert TaskNotFound(0);
        return taskIdToInfo[taskId].taskStatus;
    }

    function getTaskInfo(
        uint256 _taskId
    ) public view returns (TaskInfo memory) {
        return taskIdToInfo[_taskId];
    }

    function getTaskAssignee(uint256 _taskId) public view returns (address) {
        return taskIdToInfo[_taskId].taskAssignee;
    }
}
