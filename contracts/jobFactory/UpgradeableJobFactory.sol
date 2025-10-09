// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./BaseJobFactory.sol";

abstract contract UpgradeableJobFactory is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    BaseJobFactory
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function __UpgradeableJobFactory_init() internal onlyInitializing {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __BaseJobFactory_init();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
