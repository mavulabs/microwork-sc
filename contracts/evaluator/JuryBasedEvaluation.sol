// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interface/IJobInfo.sol";

contract JuryBasedEvaluation is ReentrancyGuard {
    error AlreadyJoined();
    error JoiningPeriodEnded();
    error StakingFailed();
    error NotEvaluator();
    error AlreadyVoted();
    error VotingPeriodEnded();
    error VotingPeriodNotEnded();
    error ResultAlreadyDeclared();
    error NoVotesCast();
    error ResultNotDeclared();
    error DidNotVote();
    error NotAWinner();
    error AlreadyClaimed();
    error RewardTransferFailed();
    error NotAdmin();
    error InvalidJuryJoinTimeRange();
    error InvalidVotingTimeRange();
    error JuryJoinMustEndBeforeVoting();
    error InsufficientStakedEvaluators();
    error InvalidNumberOfEvaluators();

    IERC20 public cUSD;
    uint256 public stakingAmount;
    uint256 public votingDeadline;
    uint256 public totalStaked;
    uint256 public juryJoinStartTime;
    uint256 public juryJoinEndTime;
    uint256 public votingStartTime;
    uint256 public votingEndTime;

    address public admin;

    struct Evaluator {
        bool hasVoted;
        bool vote;
        bool hasStaked;
        bool hasClaimedReward;
    }

    mapping(address => Evaluator) public evaluators;
    address[] public evaluatorAddresses;
    address[] public selectedEvaluators;
    uint256 public yesVotes;
    uint256 public noVotes;
    bool public resultDeclared;
    bool public winningVote;
    IJobInfo public jobInfoContract;

    event EvaluatorJoined(address indexed evaluator);
    event VoteSubmitted(address indexed evaluator, bool vote);
    event ResultDeclared(bool winningVote, uint256 yesVotes, uint256 noVotes);
    event RewardClaimed(address indexed evaluator, uint256 amount);
    event TimeRangeSet(
        uint256 joinStart,
        uint256 joinEnd,
        uint256 voteStart,
        uint256 voteEnd
    );
    event EvaluatorsSelected(address[] evaluators);

    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAdmin();
        _;
    }

    constructor(address _cUSDAddress, uint256 _stakingAmount) {
        cUSD = IERC20(_cUSDAddress);
        stakingAmount = _stakingAmount;
        admin = msg.sender;
    }

    function joinAsEvaluator() external nonReentrant {
        if (evaluators[msg.sender].hasStaked) revert AlreadyJoined();
        if (block.timestamp >= votingDeadline) revert JoiningPeriodEnded();

        if (!cUSD.transferFrom(msg.sender, address(this), stakingAmount)) {
            revert StakingFailed();
        }

        evaluators[msg.sender].hasStaked = true;
        evaluatorAddresses.push(msg.sender);
        totalStaked += stakingAmount;

        emit EvaluatorJoined(msg.sender);
    }

    function submitVote(bool _vote) external nonReentrant {
        if (!evaluators[msg.sender].hasStaked) revert NotEvaluator();
        if (evaluators[msg.sender].hasVoted) revert AlreadyVoted();
        if (block.timestamp >= votingDeadline) revert VotingPeriodEnded();

        evaluators[msg.sender].hasVoted = true;
        evaluators[msg.sender].vote = _vote;

        if (_vote) {
            yesVotes++;
        } else {
            noVotes++;
        }

        emit VoteSubmitted(msg.sender, _vote);
    }

    function declareResult() external nonReentrant {
        if (block.timestamp < votingDeadline) revert VotingPeriodNotEnded();
        if (resultDeclared) revert ResultAlreadyDeclared();
        if (yesVotes + noVotes == 0) revert NoVotesCast();

        winningVote = yesVotes > noVotes;
        resultDeclared = true;

        emit ResultDeclared(winningVote, yesVotes, noVotes);
    }

    function claimReward() external nonReentrant {
        if (!resultDeclared) revert ResultNotDeclared();
        if (!evaluators[msg.sender].hasVoted) revert DidNotVote();
        if (evaluators[msg.sender].vote != winningVote) revert NotAWinner();
        if (evaluators[msg.sender].hasClaimedReward) revert AlreadyClaimed();

        uint256 winningVoteCount = winningVote ? yesVotes : noVotes;
        uint256 rewardAmount = totalStaked / winningVoteCount;

        evaluators[msg.sender].hasClaimedReward = true;
        if (!cUSD.transfer(msg.sender, rewardAmount)) {
            revert RewardTransferFailed();
        }

        emit RewardClaimed(msg.sender, rewardAmount);
    }

    function getVotingStatus()
        external
        view
        returns (
            uint256 totalYes,
            uint256 totalNo,
            uint256 deadline,
            bool isResultDeclared,
            uint256 potentialReward
        )
    {
        uint256 _rewardAmount = 0;
        if (resultDeclared && evaluators[msg.sender].vote == winningVote) {
            uint256 winningVoteCount = winningVote ? yesVotes : noVotes;
            _rewardAmount = totalStaked / winningVoteCount;
        }
        return (
            yesVotes,
            noVotes,
            votingDeadline,
            resultDeclared,
            _rewardAmount
        );
    }

    function setTimeRanges(
        uint256 _juryJoinStartTime,
        uint256 _juryJoinEndTime,
        uint256 _votingStartTime,
        uint256 _votingEndTime
    ) external onlyAdmin {
        if (_juryJoinStartTime >= _juryJoinEndTime)
            revert InvalidJuryJoinTimeRange();
        if (_votingStartTime >= _votingEndTime) revert InvalidVotingTimeRange();
        if (_juryJoinEndTime > _votingStartTime)
            revert JuryJoinMustEndBeforeVoting();

        juryJoinStartTime = _juryJoinStartTime;
        juryJoinEndTime = _juryJoinEndTime;
        votingStartTime = _votingStartTime;
        votingEndTime = _votingEndTime;

        emit TimeRangeSet(
            juryJoinStartTime,
            juryJoinEndTime,
            votingStartTime,
            votingEndTime
        );
    }

    function selectRandomEvaluators(uint256 _numEvaluators) external {
        if (_numEvaluators == 0 || _numEvaluators > getStakedEvaluatorsCount())
            revert InvalidNumberOfEvaluators();

        uint256 randomness = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    msg.sender,
                    blockhash(block.number - 1)
                )
            )
        );

        uint256 stakedCount = getStakedEvaluatorsCount();
        delete selectedEvaluators;

        address[] memory poolOfStaked = getStakedEvaluatorPool();

        // Fisher-Yates shuffle
        for (uint256 i = stakedCount - 1; i > 0; i--) {
            uint256 j = uint256(keccak256(abi.encode(randomness, i))) % (i + 1);
            (poolOfStaked[i], poolOfStaked[j]) = (
                poolOfStaked[j],
                poolOfStaked[i]
            );
        }

        // Select first n evaluators
        for (uint256 i = 0; i < _numEvaluators; i++) {
            selectedEvaluators.push(poolOfStaked[i]);
        }

        emit EvaluatorsSelected(selectedEvaluators);
    }

    function isJuryJoinActive() public view returns (bool) {
        return
            block.timestamp >= juryJoinStartTime &&
            block.timestamp <= juryJoinEndTime;
    }

    function isVotingActive() public view returns (bool) {
        return
            block.timestamp >= votingStartTime &&
            block.timestamp <= votingEndTime;
    }

    function getStakedEvaluatorsCount() public view returns (uint256 count) {
        for (uint256 i = 0; i < evaluatorAddresses.length; i++) {
            if (evaluators[evaluatorAddresses[i]].hasStaked) {
                count++;
            }
        }
    }

    function getStakedEvaluatorPool() internal view returns (address[] memory) {
        address[] memory stakedPool = new address[](getStakedEvaluatorsCount());
        uint256 index = 0;

        for (uint256 i = 0; i < evaluatorAddresses.length; i++) {
            if (evaluators[evaluatorAddresses[i]].hasStaked) {
                stakedPool[index] = evaluatorAddresses[i];
                index++;
            }
        }

        return stakedPool;
    }

    //timerange to join in the jury //function --> who will do , will be decided later
    //set timerange for voting
    //randomly select a predefined number of evaluators
    //withdraw
    //task status change by this contract
}
