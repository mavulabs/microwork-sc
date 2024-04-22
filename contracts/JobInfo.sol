// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract JobInfo {
    bytes public jobDescription;
    bytes32 public typeOfJob;
    uint256 public deadline;
    // address[] public assignedTo;
    uint256[] public tasks;
    bool public jobStatus; // InProgress: true, Done: false
    mapping(uint256 => address) taskIdToAssignee;

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
        uint256 _deadline
    ) {
        jobDescription = _jobDescription;
        typeOfJob = _typeOfJob;
        deadline = _deadline;
        jobStatus = true; // By default, job is set to InProgress
    }

    function getJobInfo()
        public
        view
        returns (bytes memory, bool, bytes32, uint256)
    {
        return (jobDescription, jobStatus, typeOfJob, deadline);
    }

    function createTask(address _assignedTo) public {
        uint256 _taskId = tasks.length;
        tasks.push(_taskId);
        taskIdToAssignee[_taskId] = _assignedTo;
        emit TaskCreated(_taskId, _assignedTo);
    }
}
