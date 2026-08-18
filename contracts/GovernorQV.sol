// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ICEToken {
    function balanceOf(address account) external view returns (uint256);
    function isVerifiedIdentity(address account) external view returns (bool);
}

/**
 * @title GovernorQV
 * @dev Quadratic Voting Governor where n votes cost n^2 Voice Credits (VCs).
 */
contract GovernorQV {
    struct Proposal {
        uint256 id;
        address proposer;
        string descriptionHash;
        uint256 votingEnds;
        uint256 netQuadraticVotes;
        bool executed;
        bool canceled;
    }

    ICEToken public immutable ceToken;
    uint256 public proposalCount;
    uint256 public constant PROPOSAL_DEPOSIT = 10 * 10**18; // 10 CET
    uint256 public constant VOTING_DURATION = 7 days;

    mapping(uint256 => Proposal) public proposals;
    // proposalId => voter => quadratic votes cast
    mapping(uint256 => mapping(address => uint256)) public votesCast;

    event ProposalCreated(uint256 indexed id, address indexed proposer, string descriptionHash);
    event VoteCast(uint256 indexed proposalId, address indexed voter, uint256 votes, uint256 vcCost);

    constructor(address _ceToken) {
        ceToken = ICEToken(_ceToken);
    }

    function createProposal(string calldata descriptionHash) external returns (uint256) {
        require(ceToken.balanceOf(msg.sender) >= PROPOSAL_DEPOSIT, "GovernorQV: Insufficient CET deposit");
        
        proposalCount++;
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            descriptionHash: descriptionHash,
            votingEnds: block.timestamp + VOTING_DURATION,
            netQuadraticVotes: 0,
            executed: false,
            canceled: false
        });

        emit ProposalCreated(proposalCount, msg.sender, descriptionHash);
        return proposalCount;
    }

    /**
     * @dev Casts n quadratic votes. Cost in Voice Credits = n^2.
     */
    function castVote(uint256 proposalId, uint256 votes) external {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp < proposal.votingEnds, "GovernorQV: Voting ended");
        require(ceToken.isVerifiedIdentity(msg.sender), "GovernorQV: Unverified voter");

        uint256 vcCost = votes * votes; // Quadratic Cost Formula: Cost = n^2
        require(ceToken.balanceOf(msg.sender) >= vcCost, "GovernorQV: Insufficient Voice Credits");

        votesCast[proposalId][msg.sender] += votes;
        proposal.netQuadraticVotes += votes;

        emit VoteCast(proposalId, msg.sender, votes, vcCost);
    }
}