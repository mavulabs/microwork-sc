// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
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
    error TransferFailed();
    error NotAdmin();
    error InvalidJuryJoinTimeRange();
    error InvalidVotingTimeRange();
    error JuryJoinMustEndBeforeVoting();
    error InsufficientStakedEvaluators();
    error InvalidNumberOfEvaluators();
    error JoiningPeriodStarted();
    error JoiningPeriodNotEnded();
    error NotASelectedEvaluator(address sender);
    error SelectedEvaluator(address withdrawRequester);
    error EvaluationProcessCancelled();
    error EvaluatorsSelectionDone();
    error InvalidTimeInput();
    error EvaluationProcessOnGoing();
    error VotingPeriodStarted();

    IERC20 public cUSD;
    uint256 taskId;
    uint256 public stakingAmount;
    uint256 public totalStaked;
    uint256 public juryJoinStartTime;
    uint256 public juryJoinEndTime;
    uint256 public votingStartTime;
    uint256 public votingEndTime;
    uint256 public jurySize;
    uint256 public juryCombinedAmount;
    bool public status;

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
    bool public areVotesEqual;
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
    event EqualVotes(uint256 numberOfVotes);

    modifier onlySelectedEvaluator() {
        bool isEvaluator;
        for (uint i; i < selectedEvaluators.length; i++) {
            if (selectedEvaluators[i] == msg.sender) {
                isEvaluator = true;
                break;
            }
        }
        if (!isEvaluator) revert NotASelectedEvaluator(msg.sender);
        _;
    }

    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAdmin();
        _;
    }

    constructor(
        address _cUSDAddress,
        uint256 _jurySize,
        uint256 _juryCombinedAmount,
        address _jobInfoContract,
        uint256 _taskId
    ) {
        cUSD = IERC20(_cUSDAddress);
        jurySize = _jurySize;
        juryCombinedAmount = _juryCombinedAmount;
        stakingAmount = _juryCombinedAmount / _jurySize;
        admin = msg.sender;
        status = true;
        jobInfoContract = IJobInfo(_jobInfoContract);
        taskId = _taskId;
        if (!cUSD.transferFrom(msg.sender, address(this), stakingAmount)) {
            revert StakingFailed();
        }
    }

    function joinAsEvaluator() external nonReentrant {
        if (!status) revert EvaluationProcessCancelled();
        if (evaluators[msg.sender].hasStaked) revert AlreadyJoined();
        if (
            block.timestamp < juryJoinStartTime ||
            block.timestamp > juryJoinEndTime
        ) revert JoiningPeriodEnded();

        if (!cUSD.transferFrom(msg.sender, address(this), stakingAmount)) {
            revert StakingFailed();
        }

        evaluators[msg.sender].hasStaked = true;
        evaluatorAddresses.push(msg.sender);
        totalStaked += stakingAmount;

        emit EvaluatorJoined(msg.sender);
    }

    function submitVote(
        bool _vote
    ) external nonReentrant onlySelectedEvaluator {
        if (!status) revert EvaluationProcessCancelled();
        if (msg.sender != admin && !areVotesEqual) {
            if (!evaluators[msg.sender].hasStaked) revert NotEvaluator();
            if (evaluators[msg.sender].hasVoted) revert AlreadyVoted();
            if (
                block.timestamp < votingStartTime ||
                block.timestamp > votingEndTime
            ) revert VotingPeriodEnded();
        }

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
        if (!status) revert EvaluationProcessCancelled();
        if (block.timestamp <= votingEndTime) revert VotingPeriodNotEnded();
        if (resultDeclared) revert ResultAlreadyDeclared();
        if (yesVotes + noVotes == 0) revert NoVotesCast();

        if (yesVotes == noVotes) {
            areVotesEqual = true;
            emit EqualVotes(yesVotes);
        } else {
            winningVote = yesVotes > noVotes;
            if (winningVote) {
                jobInfoContract.updateTaskStatus(taskId, 5);
            } else {
                jobInfoContract.updateTaskStatus(taskId, 7);
            }
            resultDeclared = true;
            emit ResultDeclared(winningVote, yesVotes, noVotes);
        }
    }

    function claimReward() external nonReentrant onlySelectedEvaluator {
        if (!status) revert EvaluationProcessCancelled();
        if (!resultDeclared) revert ResultNotDeclared();
        if (!evaluators[msg.sender].hasVoted) revert DidNotVote();
        if (evaluators[msg.sender].vote != winningVote) revert NotAWinner();
        if (evaluators[msg.sender].hasClaimedReward) revert AlreadyClaimed();

        uint256 winningVoteCount = winningVote ? yesVotes : noVotes;
        uint256 rewardAmount = (juryCombinedAmount +
            (stakingAmount * jurySize)) / winningVoteCount;

        evaluators[msg.sender].hasClaimedReward = true;
        if (!cUSD.transfer(msg.sender, rewardAmount)) {
            revert TransferFailed();
        }

        emit RewardClaimed(msg.sender, rewardAmount);
    }

    function setTimeRanges(
        uint256 _juryJoinStartTime,
        uint256 _juryJoinEndTime,
        uint256 _votingStartTime,
        uint256 _votingEndTime
    ) public onlyAdmin {
        if (!status) revert EvaluationProcessCancelled();
        if (_juryJoinStartTime > _juryJoinEndTime)
            revert InvalidJuryJoinTimeRange();
        if (_votingStartTime > _votingEndTime) revert InvalidVotingTimeRange();
        if (_juryJoinEndTime >= _votingStartTime)
            revert JuryJoinMustEndBeforeVoting();

        uint256 currentTime = block.timestamp;
        if (
            _juryJoinStartTime < currentTime ||
            _juryJoinEndTime < currentTime ||
            _votingStartTime < currentTime ||
            _votingEndTime < currentTime
        ) revert InvalidTimeInput();

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

    function selectRandomEvaluators() external {
        if (selectedEvaluators.length > 0) revert EvaluatorsSelectionDone();
        if (!status) revert EvaluationProcessCancelled();
        if (jurySize == 0 || jurySize > getStakedEvaluatorsCount())
            revert InvalidNumberOfEvaluators();
        if (block.timestamp <= juryJoinEndTime) revert JoiningPeriodNotEnded();

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
        for (uint256 i = 0; i < jurySize; i++) {
            selectedEvaluators.push(poolOfStaked[i]);
        }

        emit EvaluatorsSelected(selectedEvaluators);
    }

    function resetJurySize(uint256 _jurySize) external onlyAdmin {
        if (!status) revert EvaluationProcessCancelled();
        if (block.timestamp >= juryJoinStartTime) revert JoiningPeriodStarted();
        jurySize = _jurySize;
        stakingAmount = juryCombinedAmount / _jurySize;
    }

    function resetJuryCombinedAmount(
        uint256 _juryCombinedAmount
    ) external onlyAdmin {
        if (!status) revert EvaluationProcessCancelled();
        if (block.timestamp >= juryJoinStartTime) revert JoiningPeriodStarted();
        juryCombinedAmount = _juryCombinedAmount;
        stakingAmount = _juryCombinedAmount / jurySize;
    }

    function withdraw() external {
        if (!status) revert EvaluationProcessCancelled();
        if (evaluators[msg.sender].hasClaimedReward) revert AlreadyClaimed();

        bool isEvaluator;
        bool isSelected;

        for (uint i; i < evaluatorAddresses.length; i++) {
            if (evaluatorAddresses[i] == msg.sender) {
                isEvaluator = true;
                break;
            }
        }
        if (!isEvaluator) revert NotEvaluator();

        for (uint i; i < selectedEvaluators.length; i++) {
            if (selectedEvaluators[i] == msg.sender) {
                isSelected = true;
                break;
            }
        }
        if (isSelected) revert SelectedEvaluator(msg.sender);

        evaluators[msg.sender].hasClaimedReward = true;
        if (!cUSD.transfer(msg.sender, stakingAmount)) {
            revert TransferFailed();
        }
    }

    function cancel() external onlyAdmin {
        if (!status) revert EvaluationProcessCancelled();
        if (block.timestamp > votingStartTime) revert VotingPeriodStarted();
        status = false;
        for (uint256 i = 0; i < evaluatorAddresses.length; i++) {
            if (!cUSD.transfer(evaluatorAddresses[i], stakingAmount)) {
                revert TransferFailed();
            }
        }
    }

    function restartAfterCancellation(
        uint256 _juryJoinStartTime,
        uint256 _juryJoinEndTime,
        uint256 _votingStartTime,
        uint256 _votingEndTime
    ) external onlyAdmin {
        if (status) revert EvaluationProcessOnGoing();
        status = true;
        setTimeRanges(
            _juryJoinStartTime,
            _juryJoinEndTime,
            _votingStartTime,
            _votingEndTime
        );
        for (uint256 i = 0; i < evaluatorAddresses.length; i++) {
            delete evaluators[evaluatorAddresses[i]];
        }
        evaluatorAddresses = new address[](0);
        selectedEvaluators = new address[](0);
    }

    function getVotingStatus()
        external
        view
        returns (
            uint256 totalYes,
            uint256 totalNo,
            uint256 startTime,
            uint256 endTime,
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
            votingStartTime,
            votingEndTime,
            resultDeclared,
            _rewardAmount
        );
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
    //supplier koto dite chai sheita nite hobe and jury size
}
