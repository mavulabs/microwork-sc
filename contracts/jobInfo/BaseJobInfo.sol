// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

abstract contract BaseJobInfo is ReentrancyGuardUpgradeable {
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

    event JobInitialized(
        address indexed creator,
        bytes32 indexed jobType,
        uint256 deadline
    );
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
    event RewardsUpdated(
        uint256 cusdAmount,
        uint256 mavuAmount,
        uint256 scoreAmount
    );
    event RewardsSent(
        address indexed recipient,
        uint256 cusdAmount,
        uint256 mavuAmount,
        uint256 scoreAmount
    );
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

    address public cusdTokenAddress;
    address public mavuTokenAddress;
    address public scoreTokenAddress;
    address public jobCreator;
    uint256 public cusdRewardAmount;
    uint256 public mavuRewardAmount;
    uint256 public scoreRewardAmount;
    bytes public jobDescription;
    bytes32 public typeOfJob;
    uint256[] public tasks;
    bool public jobStatus; // InProgress: true, Done: false
    uint256 evaluatorType;
    address evaluator;

    struct TaskInfo {
        address taskAssignee;
        uint256 assignmentEndTime;
        uint256 taskStatus;
    }

    mapping(uint256 => TaskInfo) public taskIdToInfo;
    mapping(address => uint256) public userToTaskId;

    modifier onlyJobCreator() {
        if (msg.sender != jobCreator) revert UnauthorizedAccess(msg.sender);
        _;
    }

    modifier taskExists(uint256 taskId) {
        if (taskId >= tasks.length) revert TaskNotFound(taskId);
        _;
    }

    modifier validToken(address tokenAddress) {
        if (
            tokenAddress != cusdTokenAddress &&
            tokenAddress != mavuTokenAddress &&
            tokenAddress != scoreTokenAddress
        ) {
            revert InvalidToken(tokenAddress);
        }
        _;
    }

    // Initialize function to be implemented by derived contracts
    function __BaseJobInfo_init(
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
    ) internal onlyInitializing {
        if (_jobCreator == address(0)) revert ZeroAddress();
        if (_deadline <= block.timestamp) revert InvalidDeadline(_deadline);
        if (
            _cusdAddress == address(0) ||
            _mavuCoinAddress == address(0) ||
            _scoreAddress == address(0)
        ) revert ZeroAddress();

        jobCreator = _jobCreator;
        jobDescription = _jobDescription;
        typeOfJob = _typeOfJob;
        jobStatus = true;

        cusdTokenAddress = _cusdAddress;
        mavuTokenAddress = _mavuCoinAddress;
        scoreTokenAddress = _scoreAddress;

        _updateRewards(
            _cusdRewardAmount,
            _mavuRewardAmount,
            _scoreRewardAmount
        );

        emit JobInitialized(_jobCreator, _typeOfJob, _deadline);
    }

    function _updateRewards(
        uint256 _cusdRewardAmount,
        uint256 _mavuRewardAmount,
        uint256 _scoreRewardAmount
    ) internal onlyJobCreator {
        cusdRewardAmount = _cusdRewardAmount;
        mavuRewardAmount = _mavuRewardAmount;
        scoreRewardAmount = _scoreRewardAmount;

        emit RewardsUpdated(
            _cusdRewardAmount,
            _mavuRewardAmount,
            _scoreRewardAmount
        );
    }
}
