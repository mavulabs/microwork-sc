// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract JobInfo {
    IERC20 cusdToken;
    IERC20 mavuToken;
    IERC20 scoreToken;
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
        uint256 cusdRewardAmount;
        uint256 mavuRewardAmount;
        uint256 scoreRewardAmount;
    }
    mapping(uint256 => TaskInfo) taskIdToInfo;

    event AssigneeChanged(address newAssignedTo);
    event DeadlineUpdated(uint256 newDeadline);
    event TaskCreated(uint256 indexed taskId, address indexed assignee);
    event TaskAssigned(uint256 indexed taskId, address indexed assignee);

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
        bytes memory _jobDescription,
        bytes32 _typeOfJob,
        uint256 _deadline,
        address _cusdAddress,
        address _mavuCoinAddress,
        address _scoreAddress
    ) {
        jobDescription = _jobDescription;
        typeOfJob = _typeOfJob;
        deadline = _deadline;
        jobStatus = true; // By default, job is set to InProgress
        cusdToken = IERC20(_cusdAddress);
        mavuToken = IERC20(_mavuCoinAddress);
        scoreToken = IERC20(_scoreAddress);
    }

    function getJobInfo()
        public
        view
        returns (bytes memory, bool, bytes32, uint256)
    {
        return (jobDescription, jobStatus, typeOfJob, deadline);
    }

    function createTask(
        address _assignedTo,
        uint256 _deadline,
        uint256 _taskStatus,
        uint256 _cusdRewardAmount,
        uint256 _mavuRewardAmount,
        uint256 _scoreRewardAmount
    ) public {
        uint256 _taskId = tasks.length;
        tasks.push(_taskId);
        TaskInfo memory newTaskInfo = TaskInfo(
            _assignedTo,
            _deadline,
            _taskStatus,
            _cusdRewardAmount,
            _mavuRewardAmount,
            _scoreRewardAmount
        );
        taskIdToInfo[_taskId] = newTaskInfo;
        emit TaskCreated(_taskId, _assignedTo);
    }

    function getTaskInfo(
        uint256 _taskId
    ) public view returns (TaskInfo memory) {
        return taskIdToInfo[_taskId];
    }

    /** 0 = Not assigned, 1 = Assigned, 2 = In progress , 3 = Completed, 4 = In review process,
     *  5 = Reviewed & Successful, 6 = Reviewed & Require modification, 7 = Reviewed & Failed */
    function updateTaskStatus(uint256 _taskId, uint256 _statusNo) external {
        TaskInfo storage _taskInfo = taskIdToInfo[_taskId];
        _taskInfo.taskStatus = _statusNo;
    }

    function sendRewards(address _userAddress, uint256 _taskId) external {
        TaskInfo memory task = taskIdToInfo[_taskId];
        cusdToken.transferFrom(msg.sender, _userAddress, task.cusdRewardAmount);
        mavuToken.transferFrom(msg.sender, _userAddress, task.mavuRewardAmount);
        scoreToken.transferFrom(
            msg.sender,
            _userAddress,
            task.scoreRewardAmount
        );
    }
}
