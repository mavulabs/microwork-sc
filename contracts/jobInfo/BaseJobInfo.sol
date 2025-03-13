// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

abstract contract BaseJobInfo is ReentrancyGuard {
    error UnauthorizedAccess(address caller);
    error ZeroAddress();
    error InsufficientBalance();
    error TransferFailed();
    error JobInProgress();
    error JobAlreadyDone();
    error InvalidRewardAmount();
    error InvalidToken(address token);
    error ArrayLengthShouldBeEqual();
    error NotARewardToken(address tokenAddress);
    error InvalidJob();
    error RewardAlreadyDistributed(address worker);

    event JobInitialized(address indexed creator);
    event RewardsUpdated(uint256 cusdAmount);
    event RewardsSent(address indexed recipient);
    event WithdrawalRequested(
        address indexed jobCreator,
        uint256 amount,
        address tokenAddress
    );
    event WithdrawalCompleted(
        address indexed jobCreator,
        uint256 amount,
        address tokenAddress
    );

    address[] rewardTokens;
    mapping(address => uint256) rewardTokensToAmount;
    address jobCreator;
    bytes32 internal jobIdentifierHash;
    bool public jobStatus; // InProgress: true, Done: false
    mapping(address => bool) public hasReceivedReward;

    modifier onlyJobCreator() {
        if (msg.sender != jobCreator) revert UnauthorizedAccess(msg.sender);
        _;
    }

    modifier validToken(address tokenAddress) {
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            if (rewardTokens[i] == tokenAddress) {
                _;
                return;
            }
        }
        revert InvalidToken(tokenAddress);
    }

    function __BaseJobInfo_init(
        address _jobCreator,
        address[] memory _rewardTokens,
        uint256[] memory _rewardAmounts,
        bytes32 _jobUniqueIdentifier
    ) internal {
        if (_jobCreator == address(0)) revert ZeroAddress();

        jobCreator = _jobCreator;
        jobStatus = true;
        jobIdentifierHash = hashStringGeneratorForJob(_jobUniqueIdentifier);

        _updateRewards(_rewardTokens, _rewardAmounts);

        emit JobInitialized(_jobCreator);
    }

    function _updateRewards(
        address[] memory _rewardTokens,
        uint256[] memory _rewardAmounts
    ) internal {
        if (_rewardTokens.length != _rewardAmounts.length) {
            revert ArrayLengthShouldBeEqual();
        }

        rewardTokens = _rewardTokens;
        for (uint256 i = 0; i < _rewardTokens.length; i++) {
            if (_rewardTokens[i] == address(0)) {
                revert ZeroAddress();
            }
            rewardTokensToAmount[_rewardTokens[i]] = _rewardAmounts[i];
        }
    }

    function hashStringGeneratorForJob(
        bytes32 _input
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(_input));
    }
}
