// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

abstract contract BaseJobInfo is ReentrancyGuard {
    error UnauthorizedAccess(address caller);
    error InvalidDeadline(uint256 deadline);
    error TaskNotFound(uint256 taskId);
    error InvalidTaskStatus(uint256 status);
    error ZeroAddress();
    error InsufficientBalance();
    error TransferFailed();
    error JobInProgress();
    error JobAlreadyDone();
    error InvalidRewardAmount();
    error TaskAlreadyExists(address assignee);
    error InvalidToken(address token);
    error OnlyEvaluatorCanChange(uint256 taskId, uint256 status);
    error OnlyTaskAssigneeCanChange(uint256 taskId, uint256 status);
    error ArrayLengthShouldBeEqual();
    error NotARewardToken(address tokenAddress);
    error NotEnoughRewardBalanceToStartTask();
    error InvalidTaskCompletion(address user);

    event JobInitialized(address indexed creator, bytes32 indexed jobType);
    event TaskCreated(
        uint256 indexed taskId,
        address indexed assignee,
        uint256 deadline
    );
    event TaskStatusUpdated(
        uint256 indexed taskId,
        uint256 oldStatus,
        uint256 newStatus
    );
    event RewardsUpdated(uint256 cusdAmount);
    event RewardsSent(address indexed recipient);
    event WithdrawalRequested(
        address indexed jobCreator,
        uint256 amount,
        address tokenAddress
    );
    event WithdrawalCompleted(
        address indexed jobCreator,
        uint256 amount,
        address tokenAddress
    );

    address[] rewardTokens;
    mapping(address => uint256) rewardTokensToAmount;
    address jobCreator;
    bytes32 public typeOfJob;
    uint256 public tasksLength; //task starts from 1
    bool public jobStatus; // InProgress: true, Done: false
    uint256 public evaluatorType;
    address evaluatorAddress;

    struct TaskInfo {
        address taskAssignee;
        uint256 assignmentEndTime;
        uint256 taskStatus; // 1 : InProgress
        address evaluator;
        bytes32 taskBasedPlatformHash;
    }

    mapping(uint256 => TaskInfo) public taskIdToInfo;
    mapping(address => uint256) public userToTaskId;

    modifier onlyJobCreator() {
        if (msg.sender != jobCreator) revert UnauthorizedAccess(msg.sender);
        _;
    }

    modifier taskExists(uint256 taskId) {
        if (taskId > tasksLength) revert TaskNotFound(taskId);
        _;
    }

    modifier validToken(address tokenAddress) {
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            if (rewardTokens[i] == tokenAddress) {
                _;
                return;
            }
        }
        revert InvalidToken(tokenAddress);
    }

    function __BaseJobInfo_init(
        address _jobCreator,
        bytes32 _typeOfJob,
        uint256 _evaluatorType,
        address _evaluator,
        address[] memory _rewardTokens,
        uint256[] memory _rewardAmounts
    ) internal {
        if (_jobCreator == address(0)) revert ZeroAddress();

        jobCreator = _jobCreator;
        typeOfJob = _typeOfJob;
        jobStatus = true;
        evaluatorType = _evaluatorType;
        evaluatorAddress = _evaluator;

        _updateRewards(_rewardTokens, _rewardAmounts);

        emit JobInitialized(_jobCreator, _typeOfJob);
    }

    function _updateRewards(
        address[] memory _rewardTokens,
        uint256[] memory _rewardAmounts
    ) internal {
        if (_rewardTokens.length != _rewardAmounts.length) {
            revert ArrayLengthShouldBeEqual();
        }

        rewardTokens = _rewardTokens;
        for (uint256 i = 0; i < _rewardTokens.length; i++) {
            if (_rewardTokens[i] == address(0)) {
                revert ZeroAddress();
            }
            rewardTokensToAmount[_rewardTokens[i]] = _rewardAmounts[i];
        }
    }
}
