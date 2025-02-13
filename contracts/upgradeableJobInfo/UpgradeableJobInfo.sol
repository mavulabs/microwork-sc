// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./BaseJobInfo.sol";

abstract contract UpgradeableJobInfo is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    BaseJobInfo
{
    constructor() {
        _disableInitializers();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function __UpgradeableJobInfo_init(
        address _jobCreator,
        bytes32 _typeOfJob,
        uint256 _evaluatorType,
        address _evaluator,
        address[] calldata _rewardTokens,
        uint256[] calldata _rewardAmount
    ) internal onlyInitializing {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __BaseJobInfo_init(
            _jobCreator,
            _typeOfJob,
            _evaluatorType,
            _evaluator,
            _rewardTokens,
            _rewardAmount
        );
    }
}
