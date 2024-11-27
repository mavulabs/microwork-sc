// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./UpgradeableJobInfo.sol";

contract JobInfo is UpgradeableJobInfo {
    function initialize(
        address _jobCreator,
        bytes calldata _jobDescription,
        bytes32 _typeOfJob,
        uint256 _deadline,
        address[] calldata _rewardTokens,
        uint256[] calldata _rewardAmount
    ) public initializer {
        __UpgradeableJobInfo_init(
            _jobCreator,
            _jobDescription,
            _typeOfJob,
            _deadline,
            _rewardTokens,
            _rewardAmount
        );
    }

    function startTask(
        address _assignedTo,
        uint256 _deadline,
        uint256 _taskStatus
    ) public {
        if (_assignedTo == address(0)) revert ZeroAddress();
        if (userToTaskId[_assignedTo] != 0)
            revert TaskAlreadyExists(_assignedTo);

        uint256 _taskId = tasks.length;
        tasks.push(_taskId);

        taskIdToInfo[_taskId] = TaskInfo({
            taskAssignee: _assignedTo,
            assignmentEndTime: _deadline,
            taskStatus: _taskStatus,
            evaluator: address(0)
        });

        userToTaskId[_assignedTo] = _taskId;

        emit TaskCreated(_taskId, _assignedTo, _deadline);
    }

    function updateTaskStatus(
        uint256 _taskId,
        uint256 _statusNo
    ) public onlyJobCreator taskExists(_taskId) {
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
                cusdRewardAmount
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
        address tokenAddress
    ) external nonReentrant onlyJobCreator validToken(tokenAddress) {
        if (jobStatus) revert JobInProgress();

        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        if (balance == 0) revert InsufficientBalance();

        emit WithdrawalRequested(jobCreator, balance, tokenAddress);

        bool success = IERC20(tokenAddress).transfer(jobCreator, balance);
        if (!success) revert TransferFailed();

        emit WithdrawalCompleted(jobCreator, balance, tokenAddress);
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
    ) external {
        TaskInfo storage _taskInfo = taskIdToInfo[_taskId];
        _taskInfo.evaluator = _evaluatorAddress;
    }

    function getJobInfo()
        external
        view
        returns (bytes memory, bool, bytes32, uint256, uint256, uint256)
    {
        return (
            jobDescription,
            jobStatus,
            typeOfJob,
            cusdRewardAmount,
            mavuRewardAmount,
            scoreRewardAmount
        );
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
