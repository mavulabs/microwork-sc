// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract CeloOptimisticOracle is ReentrancyGuard {
    IERC20 public immutable cUSD;
    uint256 public constant LOCKUP_PERIOD = 3 days;

    struct Bond {
        bytes32 answer;
        uint256 amount;
        address placer;
        uint256 placedAt;
    }

    Bond public currentBond;
    bool public resolved;
    uint256 public expirationDate;

    event QuestionSet(uint256 expirationDate);
    event BondPlaced(bytes32 answer, uint256 amount, address placer);
    event QuestionResolved(bytes32 winningAnswer);
    event BondClaimed(address claimer, uint256 amount);

    constructor(address _cUSD) {
        cUSD = IERC20(_cUSD);
    }

    function setQuestion(uint256 _expirationDate) external {
        require(expirationDate == 0, "Question already set");
        require(
            _expirationDate > block.timestamp,
            "Expiration date must be in the future"
        );

        expirationDate = _expirationDate;
        emit QuestionSet(_expirationDate);
    }

    function placeBond(bytes32 answer) external nonReentrant {
        require(block.timestamp > expirationDate, "Question not expired yet");
        require(!resolved, "Question already resolved");
        require(
            currentBond.amount == 0 || msg.sender != currentBond.placer,
            "Cannot challenge your own bond"
        );

        uint256 bondAmount;
        if (currentBond.amount == 0) {
            // First bond can be any amount
            bondAmount = 1; // Minimum bond of 1 cUSD
        } else {
            // Challenging bond must be at least twice the current bond
            bondAmount = currentBond.amount * 2;
        }

        require(
            cUSD.transferFrom(msg.sender, address(this), bondAmount),
            "cUSD transfer failed"
        );

        currentBond = Bond({
            answer: answer,
            amount: bondAmount,
            placer: msg.sender,
            placedAt: block.timestamp
        });

        emit BondPlaced(answer, bondAmount, msg.sender);
    }

    function resolveQuestion() external nonReentrant {
        require(!resolved, "Question already resolved");
        require(
            block.timestamp > currentBond.placedAt + LOCKUP_PERIOD,
            "Lockup period not over"
        );

        resolved = true;
        emit QuestionResolved(currentBond.answer);
    }

    function claimBond() external nonReentrant {
        require(resolved, "Question not resolved yet");

        uint256 claimAmount = currentBond.amount;
        address claimer = currentBond.placer;

        // Reset the bond to prevent double claiming
        currentBond = Bond(0, 0, address(0), 0);

        require(cUSD.transfer(claimer, claimAmount), "cUSD transfer failed");

        emit BondClaimed(claimer, claimAmount);
    }

    function getCurrentBond()
        external
        view
        returns (
            bytes32 answer,
            uint256 amount,
            address placer,
            uint256 placedAt
        )
    {
        return (
            currentBond.answer,
            currentBond.amount,
            currentBond.placer,
            currentBond.placedAt
        );
    }
}
