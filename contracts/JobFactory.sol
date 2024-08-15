// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "./JobInfo.sol";

contract JobFactory {
    address[] public jobContracts;
    struct JobDetails {
        bytes jobDescription;
        bytes32 typeOfJob;
        uint256 deadline;
        address _cusdAddress;
        address _mavuCoinAddress;
        address _scoreAddress;
        uint256 _cusdRewardAmount;
        uint256 _mavuRewardAmount;
        uint256 _scoreRewardAmount;
    }

    event JobRegistered(address indexed jobContract);

    function registerJob(JobDetails calldata _jobInfo) public {
        JobInfo newJob = new JobInfo(
            _jobInfo.jobDescription,
            _jobInfo.typeOfJob,
            _jobInfo.deadline,
            _jobInfo._cusdAddress,
            _jobInfo._mavuCoinAddress,
            _jobInfo._scoreAddress,
            _jobInfo._cusdRewardAmount,
            _jobInfo._mavuRewardAmount,
            _jobInfo._scoreRewardAmount
        );
        jobContracts.push(address(newJob));
        emit JobRegistered(address(newJob));
    }

    function batchRegisterJob(JobDetails[] calldata _jobInfos) public {
        for (uint256 i = 0; i < _jobInfos.length; i++) {
            registerJob(_jobInfos[i]);
        }
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
