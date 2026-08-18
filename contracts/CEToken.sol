// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CEToken (Community Engagement Token)
 * @dev ERC-5192 Minimal Soulbound Token Implementation for Eco Energy Hub.
 * Tokens are non-transferable and represent governance entitlements earned through verified energy actions.
 */
contract CEToken {
    string public name = "Community Engagement Token";
    string public symbol = "CET";
    uint8 public decimals = 18;

    address public admin;
    mapping(address => bool) public isAuthorizedOracle;
    mapping(address => bool) public isVerifiedIdentity;
    mapping(address => string) public sdpIdentifier; // Physical Service Delivery Point binding
    mapping(address => uint256) private _balances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Locked(uint256 tokenId);
    event IdentityVerified(address indexed account, string sdpId);
    event OracleAuthorized(address indexed oracle, bool status);

    modifier onlyAdmin() {
        require(msg.sender == admin, "CET: Caller is not admin");
        _;
    }

    modifier onlyOracle() {
        require(isAuthorizedOracle[msg.sender], "CET: Caller is not an authorized oracle");
        _;
    }

    constructor() {
        admin = msg.sender;
        isAuthorizedOracle[msg.sender] = true; // Temporary bootstrap oracle
    }

    function setOracleAuthorization(address oracle, bool status) external onlyAdmin {
        isAuthorizedOracle[oracle] = status;
        emit OracleAuthorized(oracle, status);
    }

    /**
     * @dev Binds a prosumer address to a unique physical meter Service Delivery Point (SDP).
     */
    function verifyIdentity(address account, string calldata sdpId) external onlyOracle {
        require(bytes(sdpId).length > 0, "CET: Invalid SDP ID");
        isVerifiedIdentity[account] = true;
        sdpIdentifier[account] = sdpId;
        emit IdentityVerified(account, sdpId);
    }

    /**
     * @dev Mints CETs based on threshold-verified telemetry. Restricted to authorized oracles.
     */
    function mint(address to, uint256 amount) external onlyOracle {
        require(isVerifiedIdentity[to], "CET: Account identity not bound to physical SDP");
        _balances[to] += amount;
        emit Transfer(address(0), to, amount);
        emit Locked(amount);
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    // Explicitly block all transfer methods to enforce ERC-5192 Soulbound constraints
    function transfer(address, uint256) external pure returns (bool) {
        revert("CET: Soulbound token - transfers disabled");
    }

    function transferFrom(address, address, uint256) external pure returns (bool) {
        revert("CET: Soulbound token - transfers disabled");
    }
}