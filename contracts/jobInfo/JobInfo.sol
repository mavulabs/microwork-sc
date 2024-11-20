// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./UpgradeableJobInfo.sol";

contract JobInfo is UpgradeableJobInfo {
    function initialize(
        address _jobCreator,
        bytes memory _jobDescription,
        bytes32 _typeOfJob,
        uint256 _deadline,
        address _cusdAddress,
        address _mavuCoinAddress,
        address _scoreAddress,
        uint256 _cusdRewardAmount,
        uint256 _mavuRewardAmount,
        uint256 _scoreRewardAmount
    ) public initializer {
        __UpgradeableJobInfo_init(
            _jobCreator,
            _jobDescription,
            _typeOfJob,
            _deadline,
            _cusdAddress,
            _mavuCoinAddress,
            _scoreAddress,
            _cusdRewardAmount,
            _mavuRewardAmount,
            _scoreRewardAmount
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
            taskStatus: _taskStatus
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
        uint256 oldStatus = _taskInfo.taskStatus;
        _taskInfo.taskStatus = _statusNo;

        emit TaskStatusUpdated(_taskId, oldStatus, _statusNo);

        if (_statusNo == 5) {
            _sendRewards(_taskInfo.taskAssignee);
        }
    }

    function _sendRewards(address _userAddress) internal {
        if (_userAddress == address(0)) revert ZeroAddress();

        bool cusdSuccess = IERC20(cusdTokenAddress).transfer(
            _userAddress,
            cusdRewardAmount
        );
        bool mavuSuccess = IERC20(mavuTokenAddress).transfer(
            _userAddress,
            mavuRewardAmount
        );
        bool scoreSuccess = IERC20(scoreTokenAddress).transfer(
            _userAddress,
            scoreRewardAmount
        );

        if (!cusdSuccess || !mavuSuccess || !scoreSuccess)
            revert TransferFailed();

        emit RewardsSent(
            _userAddress,
            cusdRewardAmount,
            mavuRewardAmount,
            scoreRewardAmount
        );
    }

    function setRewardsAmount(
        uint256 _cusdRewardAmount,
        uint256 _mavuRewardAmount,
        uint256 _scoreRewardAmount
    ) external onlyJobCreator {
        _updateRewards(
            _cusdRewardAmount,
            _mavuRewardAmount,
            _scoreRewardAmount
        );
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
        address _evaluatorAddress
    ) external onlyJobCreator {
        evaluator = _evaluatorAddress;
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
}
