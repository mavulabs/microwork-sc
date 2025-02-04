// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJobInfo {
    function updateTaskStatus(uint256 _taskId, uint256 _statusNo) external;
}
