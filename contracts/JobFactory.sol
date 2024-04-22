// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "./JobInfo.sol";

contract JobFactory {
    address[] public jobContracts;

    event JobRegistered(address indexed jobContract);

    function registerJob(
        bytes memory jobDescription,
        bytes32 typeOfJob,
        uint256 deadline
    ) public {
        JobInfo newJob = new JobInfo(jobDescription, typeOfJob, deadline);
        jobContracts.push(address(newJob));
        emit JobRegistered(address(newJob));
    }

    function getCompletedJobs() public view returns (address[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < jobContracts.length; i++) {
            if (!JobInfo(jobContracts[i]).jobStatus()) {
                count++;
            }
        }
        address[] memory completedJobs = new address[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < jobContracts.length; i++) {
            if (!JobInfo(jobContracts[i]).jobStatus()) {
                completedJobs[index] = jobContracts[i];
                index++;
            }
        }
        return completedJobs;
    }

    function getInProgressJobs() public view returns (address[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < jobContracts.length; i++) {
            if (JobInfo(jobContracts[i]).jobStatus()) {
                count++;
            }
        }
        address[] memory inProgressJobs = new address[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < jobContracts.length; i++) {
            if (JobInfo(jobContracts[i]).jobStatus()) {
                inProgressJobs[index] = jobContracts[i];
                index++;
            }
        }
        return inProgressJobs;
    }
}
