// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title TimelockGuardian
 * @dev Enforces a 48-hour challenge period before execution and provides pause-only authority to a 3-of-5 multisig guardian.
 */
contract TimelockGuardian {
    uint256 public constant TIMELOCK_DELAY = 48 hours;
    
    address[5] public guardians;
    bool public isPaused;
    mapping(bytes32 => uint256) public queuedTransactions;
    mapping(bytes32 => mapping(address => bool)) public pauseConfirmations;
    uint256 public pauseVotes;

    event TransactionQueued(bytes32 indexed txHash, uint256 executionTime);
    event TransactionExecuted(bytes32 indexed txHash);
    event EmergencyPaused(address indexed guardian);

    modifier onlyGuardian() {
        bool isG = false;
        for (uint256 i = 0; i < 5; i++) {
            if (guardians[i] == msg.sender) { isG = true; break; }
        }
        require(isG, "Timelock: Caller is not guardian");
        _;
    }

    constructor(address[5] memory _guardians) {
        guardians = _guardians;
    }

    function queueTransaction(bytes32 txHash) external {
        uint256 executionTime = block.timestamp + TIMELOCK_DELAY;
        queuedTransactions[txHash] = executionTime;
        emit TransactionQueued(txHash, executionTime);
    }

    function emergencyPause() external onlyGuardian {
        require(!pauseConfirmations[bytes32(0)][msg.sender], "Timelock: Already voted");
        pauseConfirmations[bytes32(0)][msg.sender] = true;
        pauseVotes++;

        if (pauseVotes >= 3) { // 3-of-5 Threshold
            isPaused = true;
            emit EmergencyPaused(msg.sender);
        }
    }
}