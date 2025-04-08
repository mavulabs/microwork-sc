// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

/**
 * @title BaseJobFactory
 * @dev Base contract for job factory functionality
 */
abstract contract BaseJobFactory is ReentrancyGuardUpgradeable {
    address[] internal jobContracts;
    mapping(address => bool) public isJobContract;

    struct JobDetails {
        address jobCreator;
        address protocolWallet;
        address[] rewardTokens;
        uint256[] rewardAmount;
    }

    event JobRegistered(address indexed jobContract, address indexed creator);
    event JobBatchRegistered(address[] jobContracts, address indexed creator);

    error InvalidJobDetails();
    error InvalidDeadline();
    error ZeroAddress();
    error BatchLimitExceeded();
    error EmptyBatch();

    function __BaseJobFactory_init() internal onlyInitializing {
        __ReentrancyGuard_init();
    }

    function _validateJobDetails(
        JobDetails calldata details
    ) internal view virtual {
        if (details.jobCreator == address(0)) {
            revert ZeroAddress();
        }
        for (uint256 i = 0; i < details.rewardTokens.length; i++) {
            if (details.rewardTokens[i] == address(0)) {
                revert ZeroAddress();
            }
        }
    }

    function _addJobContract(
        address jobContract,
        address creator
    ) internal virtual {
        jobContracts.push(jobContract);
        isJobContract[jobContract] = true;
        emit JobRegistered(jobContract, creator);
    }
}
