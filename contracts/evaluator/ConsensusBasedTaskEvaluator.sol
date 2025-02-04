// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interface/IJobInfo.sol";

contract ConsensusBasedTaskEvaluator {
    struct Task {
        uint256 positiveVotes;
        uint256 negativeVotes;
        uint256 totalVotes;
        bool isComplete;
        mapping(address => bool) hasVoted;
    }

    mapping(uint256 => Task) public tasks;
    mapping(address => bool) public registeredReviewers;
    uint256 public requiredReviews;
    address public owner;
    IJobInfo public jobInfoContract;

    event TaskSubmitted(uint256 taskId);
    event ReviewerRegistered(address reviewer);
    event EvaluationSubmitted(uint256 taskId, address reviewer, bool vote);
    event TaskReviewCompleted(uint256 taskId, uint256 finalStatus);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyRegisteredReviewer() {
        require(
            registeredReviewers[msg.sender],
            "Only registered reviewers can call this function"
        );
        _;
    }

    constructor(address _jobInfoContract, uint256 _requiredReviews) {
        owner = msg.sender;
        jobInfoContract = IJobInfo(_jobInfoContract);
        requiredReviews = _requiredReviews;
    }

    function submitTask(uint256 _taskId) external {
        require(tasks[_taskId].totalVotes == 0, "Task already submitted");
        tasks[_taskId].isComplete = false;
        emit TaskSubmitted(_taskId);

        // Update status to "Submitted & In review process"
        jobInfoContract.updateTaskStatus(_taskId, 3);
    }

    function registerReviewer(address _reviewer) external onlyOwner {
        require(!registeredReviewers[_reviewer], "Reviewer already registered");
        registeredReviewers[_reviewer] = true;
        emit ReviewerRegistered(_reviewer);
    }

    function submitEvaluation(
        uint256 _taskId,
        bool _vote
    ) external onlyRegisteredReviewer {
        Task storage task = tasks[_taskId];
        require(!task.isComplete, "Task review is already complete");
        require(
            !task.hasVoted[msg.sender],
            "You have already voted for this task"
        );

        task.hasVoted[msg.sender] = true;
        task.totalVotes++;

        if (_vote) {
            task.positiveVotes++;
        } else {
            task.negativeVotes++;
        }

        emit EvaluationSubmitted(_taskId, msg.sender, _vote);

        if (task.totalVotes == requiredReviews) {
            task.isComplete = true;
            uint256 finalStatus = determineFinalStatus(
                task.positiveVotes,
                task.negativeVotes
            );
            jobInfoContract.updateTaskStatus(_taskId, finalStatus);
            emit TaskReviewCompleted(_taskId, finalStatus);
        }
    }

    function determineFinalStatus(
        uint256 positiveVotes,
        uint256 negativeVotes
    ) private pure returns (uint256) {
        if (positiveVotes > negativeVotes) {
            return 5; // Reviewed & Successful
        } else if (positiveVotes < negativeVotes) {
            return 7; // Reviewed & Failed
        } else {
            return 6; // Reviewed & Require modification
        }
    }

    function getTaskVotes(
        uint256 _taskId
    )
        public
        view
        returns (
            uint256 positiveVotes,
            uint256 negativeVotes,
            uint256 totalVotes
        )
    {
        Task storage task = tasks[_taskId];
        return (task.positiveVotes, task.negativeVotes, task.totalVotes);
    }

    function setRequiredReviews(uint256 _requiredReviews) external onlyOwner {
        requiredReviews = _requiredReviews;
    }

    function setJobInfoContract(address _jobInfoContract) external onlyOwner {
        jobInfoContract = IJobInfo(_jobInfoContract);
    }
}
