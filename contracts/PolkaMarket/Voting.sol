// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdvancedVoting {
    struct Proposal {
        string description;
        uint256 voteCount;
        bool exists;
    }

    struct UserVote {
        bool hasVoted;
        uint256 proposalId;
        uint256 amount;
    }

    address public owner;
    uint256 public fixedStakeAmount;
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => UserVote) public userVotes;
    uint256 public totalVotes;

    event ProposalCreated(uint256 indexed proposalId, string description);
    event Voted(
        address indexed voter,
        uint256 indexed proposalId,
        uint256 amount
    );
    event FixedStakeAmountChanged(uint256 newAmount);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    constructor(uint256 _initialStakeAmount) {
        owner = msg.sender;
        fixedStakeAmount = _initialStakeAmount;
    }

    function createProposal(string memory _description) public onlyOwner {
        proposalCount++;
        proposals[proposalCount] = Proposal(_description, 0, true);
        emit ProposalCreated(proposalCount, _description);
    }

    function vote(uint256 _proposalId) public payable {
        require(proposals[_proposalId].exists, "Proposal does not exist");
        require(
            msg.value == fixedStakeAmount,
            "Must send exactly the fixed stake amount"
        );
        require(!userVotes[msg.sender].hasVoted, "User has already voted");

        proposals[_proposalId].voteCount++;
        userVotes[msg.sender] = UserVote(true, _proposalId, msg.value);
        totalVotes++;

        emit Voted(msg.sender, _proposalId, msg.value);
    }

    function changeFixedStakeAmount(uint256 _newAmount) public onlyOwner {
        fixedStakeAmount = _newAmount;
        emit FixedStakeAmountChanged(_newAmount);
    }

    function checkWinner()
        public
        view
        returns (uint256 winningProposalId, string memory winningProposal)
    {
        uint256 winningVoteCount = 0;
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                winningProposalId = i;
            }
        }
        winningProposal = proposals[winningProposalId].description;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        require(
            _newOwner != address(0),
            "New owner cannot be the zero address"
        );
        address oldOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }

    function withdrawStake() public {
        require(userVotes[msg.sender].hasVoted, "No stake to withdraw");
        uint256 amount = userVotes[msg.sender].amount;
        delete userVotes[msg.sender];
        payable(msg.sender).transfer(amount);
    }

    // Allow the contract to receive ETH
    receive() external payable {}
}
