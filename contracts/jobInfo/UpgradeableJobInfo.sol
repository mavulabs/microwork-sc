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
        bytes memory _jobDescription,
        bytes32 _typeOfJob,
        uint256 _deadline,
        address _cusdAddress,
        address _mavuCoinAddress,
        address _scoreAddress,
        uint256 _cusdRewardAmount,
        uint256 _mavuRewardAmount,
        uint256 _scoreRewardAmount
    ) internal onlyInitializing {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __BaseJobInfo_init(
            _jobCreator,
            _jobDescription,
            _typeOfJob,
            _deadline,
            _cusdAddress,
            _mavuCoinAddress,
            _scoreAddress,
            _cusdRewardAmount,
            _mavuRewardAmount,
            _scoreRewardAmount
        );
    }
}
