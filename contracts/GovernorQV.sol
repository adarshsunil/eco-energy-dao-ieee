// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ICEToken {
    function balanceOf(address account) external view returns (uint256);
    function isVerifiedIdentity(address account) external view returns (bool);
}

/**
 * @title GovernorQV
 * @dev On-Chain Quadratic Voting Governor with epoch-level Voice Credit spend tracking.
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
    uint256 public currentEpoch;
    uint256 public constant PROPOSAL_DEPOSIT = 10 * 10**18; // 10 CET
    uint256 public constant VOTING_DURATION = 7 days;

    mapping(uint256 => Proposal) public proposals;
    // proposalId => voter => quadratic votes cast
    mapping(uint256 => mapping(address => uint256)) public votesCast;
    // epoch => voter => cumulative Voice Credits spent in epoch
    mapping(uint256 => mapping(address => uint256)) public spentVoiceCredits;

    event ProposalCreated(uint256 indexed id, address indexed proposer, string descriptionHash);
    event VoteCast(uint256 indexed proposalId, address indexed voter, uint256 votes, uint256 vcCost);
    event EpochAdvanced(uint256 newEpoch);

    constructor(address _ceToken) {
        ceToken = ICEToken(_ceToken);
        currentEpoch = 1;
    }

    function advanceEpoch() external {
        currentEpoch++;
        emit EpochAdvanced(currentEpoch);
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
     * @dev Casts n quadratic votes on a proposal. Enforces sum(v_i^2) <= Total_VC within the current epoch.
     */
    function castVote(uint256 proposalId, uint256 votes) external {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp < proposal.votingEnds, "GovernorQV: Voting ended");
        require(ceToken.isVerifiedIdentity(msg.sender), "GovernorQV: Unverified voter SDP");

        uint256 vcCost = votes * votes; // Cost = n^2
        uint256 totalVC = ceToken.balanceOf(msg.sender);
        uint256 currentSpent = spentVoiceCredits[currentEpoch][msg.sender];

        require(currentSpent + vcCost <= totalVC, "GovernorQV: Exceeds epoch Voice Credit allowance");

        spentVoiceCredits[currentEpoch][msg.sender] += vcCost;
        votesCast[proposalId][msg.sender] += votes;
        proposal.netQuadraticVotes += votes;

        emit VoteCast(proposalId, msg.sender, votes, vcCost);
    }
}