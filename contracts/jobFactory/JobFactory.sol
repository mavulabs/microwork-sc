// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./UpgradeableJobFactory.sol";
import "../jobInfo/JobInfo.sol";

contract JobFactory is UpgradeableJobFactory {
    mapping(address => address[]) public creatorToJobs;
    uint256 public totalJobs;

    function initialize() public initializer {
        __UpgradeableJobFactory_init();
        totalJobs = 0;
    }

    function registerJob(JobDetails calldata _jobInfo) public nonReentrant {
        _validateJobDetails(_jobInfo);

        JobInfo newJob = new JobInfo(
            _jobInfo.jobCreator,
            _jobInfo.protocolWallet,
            _jobInfo.rewardTokens,
            _jobInfo.rewardAmount
        );

        address jobAddress = address(newJob);
        _addJobContract(jobAddress, _jobInfo.jobCreator);
        creatorToJobs[_jobInfo.jobCreator].push(jobAddress);
        totalJobs++;
    }

    function getCompletedJobs() public view returns (address[] memory) {
        return _filterJobs(false);
    }

    function getInProgressJobs() public view returns (address[] memory) {
        return _filterJobs(true);
    }

    function getJobsByCreator(
        address creator
    ) public view returns (address[] memory) {
        return creatorToJobs[creator];
    }

    function _filterJobs(
        bool inProgress
    ) internal view returns (address[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < jobContracts.length; i++) {
            if (JobInfo(jobContracts[i]).jobStatus() == inProgress) {
                count++;
            }
        }

        address[] memory filteredJobs = new address[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < jobContracts.length; i++) {
            if (JobInfo(jobContracts[i]).jobStatus() == inProgress) {
                filteredJobs[index] = jobContracts[i];
                index++;
            }
        }

        return filteredJobs;
    }
}
