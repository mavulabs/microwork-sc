// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract JobInfo is ReentrancyGuard {
    IERC20 cusdToken;
    IERC20 mavuToken;
    IERC20 scoreToken;
    address jobCreator;
    uint256 cusdRewardAmount;
    uint256 mavuRewardAmount;
    uint256 scoreRewardAmount;
    bytes public jobDescription;
    bytes32 public typeOfJob;
    uint256 public deadline;
    // address[] public assignedTo;
    uint256[] public tasks;
    bool public jobStatus; // InProgress: true, Done: false
    struct TaskInfo {
        address taskAssignee;
        uint256 assignmentEndTime;
        uint256 taskStatus;
    }
    mapping(uint256 => TaskInfo) taskIdToInfo;
    mapping(address => uint256) userToTaskId;

    event AssigneeChanged(address newAssignedTo);
    event DeadlineUpdated(uint256 newDeadline);
    event TaskCreated(uint256 indexed taskId, address indexed assignee);
    event TaskAssigned(uint256 indexed taskId, address indexed assignee);
    event WithdrawalRequested(address indexed jobCreator, uint256 amount);
    event WithdrawalCompleted(address indexed jobCreator, uint256 amount);
    event InvalidWithdrawRequest(address tokenAddress);

    error ZeroAddress();
    error InsufficientBalance();
    error TransferFailed();

    // modifier onlyAssigned() {
    //     bool found = false;
    //     for (uint256 i = 0; i < assignedTo.length; i++) {
    //         if (assignedTo[i] == msg.sender) {
    //             found = true;
    //             break;
    //         }
    //     }
    //     require(found, "You are not assigned to this job");
    //     _;
    // }

    constructor(
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
    ) {
        jobCreator = _jobCreator;
        jobDescription = _jobDescription;
        typeOfJob = _typeOfJob;
        deadline = _deadline;
        jobStatus = true; // By default, job is set to InProgress
        cusdToken = IERC20(_cusdAddress);
        mavuToken = IERC20(_mavuCoinAddress);
        scoreToken = IERC20(_scoreAddress);
        cusdRewardAmount = _cusdRewardAmount;
        mavuRewardAmount = _mavuRewardAmount;
        scoreRewardAmount = _scoreRewardAmount;
    }

    function getJobInfo()
        public
        view
        returns (
            bytes memory,
            bool,
            bytes32,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            jobDescription,
            jobStatus,
            typeOfJob,
            deadline,
            cusdRewardAmount,
            mavuRewardAmount,
            scoreRewardAmount
        );
    }

    function startTask(
        address _assignedTo,
        uint256 _deadline,
        uint256 _taskStatus
    ) public {
        uint256 _taskId = tasks.length;
        tasks.push(_taskId);
        TaskInfo memory newTaskInfo = TaskInfo(
            _assignedTo,
            _deadline,
            _taskStatus
        );
        taskIdToInfo[_taskId] = newTaskInfo;
        userToTaskId[_assignedTo] = _taskId;
        emit TaskCreated(_taskId, _assignedTo);
    }

    function getTaskIdOfAUser(
        address _userAddress
    ) public view returns (uint256) {
        return userToTaskId[_userAddress];
    }

    function batchStartTasks(TaskInfo[] calldata _taskInfoArray) public {
        for (uint256 i = 0; i < _taskInfoArray.length; i++) {
            startTask(
                _taskInfoArray[i].taskAssignee,
                _taskInfoArray[i].assignmentEndTime,
                _taskInfoArray[i].taskStatus
            );
        }
    }

    function getTaskInfo(
        uint256 _taskId
    ) public view returns (TaskInfo memory) {
        return taskIdToInfo[_taskId];
    }

    /** 0 = Not assigned, 1 = In progress , 3 = Submitted & In review process,
     *  5 = Reviewed & Successful, 6 = Reviewed & Require modification, 7 = Reviewed & Failed */
    // @TODO modifier
    function updateTaskStatus(uint256 _taskId, uint256 _statusNo) public {
        TaskInfo storage _taskInfo = taskIdToInfo[_taskId];
        _taskInfo.taskStatus = _statusNo;
        if (_statusNo == 5) {
            sendRewards(_taskInfo.taskAssignee);
        }
    }

    function getTaskStatusOfAUser(
        address userAddress
    ) public view returns (uint256) {
        uint256 taskId = getTaskIdOfAUser(userAddress);
        TaskInfo memory _taskInfo = getTaskInfo(taskId);
        return _taskInfo.taskStatus;
    }

    function batchUpdateTaskStatus(
        uint256[] calldata _taskIds,
        uint256[] calldata _statusNos
    ) external {
        require(
            _taskIds.length == _statusNos.length,
            "Input arrays must have the same length"
        );

        for (uint256 i = 0; i < _taskIds.length; i++) {
            updateTaskStatus(_taskIds[i], _statusNos[i]);
        }
    }

    function sendRewards(address _userAddress) internal {
        cusdToken.transferFrom(msg.sender, _userAddress, cusdRewardAmount);
        mavuToken.transferFrom(msg.sender, _userAddress, mavuRewardAmount);
        scoreToken.transferFrom(msg.sender, _userAddress, scoreRewardAmount);
    }

    function setRewardsAmount(
        uint256 _cusdRewardAmount,
        uint256 _mavuRewardAmount,
        uint256 _scoreRewardAmount
    ) external {
        cusdRewardAmount = _cusdRewardAmount;
        mavuRewardAmount = _mavuRewardAmount;
        scoreRewardAmount = _scoreRewardAmount;
    }

    function withdrawMavu() external nonReentrant {
        uint256 balanceOfMavu = getTotalMavuStacked();
        if (jobStatus) revert InvalidWithdrawRequest(mavuTokenAddress);
        if (balanceOfMavu == 0) revert InsufficientBalance();
        if (jobCreator == address(0)) revert ZeroAddress();
        emit WithdrawalRequested(jobCreator, balanceOfMavu);
        bool success = mavuToken.transfer(jobCreator, balanceOfMavu);
        if (!success) revert TransferFailed();
        emit WithdrawalCompleted(jobCreator, balanceOfMavu);
    }

    function getTotalMavuStacked() public view returns (uint256) {
        return mavuToken.balanceOf(address(this));
    }

    function getTotalCUSDStacked() public view returns (uint256) {
        return cusdToken.balanceOf(address(this));
    }
}
