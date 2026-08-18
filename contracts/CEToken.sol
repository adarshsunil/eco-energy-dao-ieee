// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CEToken (Community Engagement Token)
 * @dev ERC-5192 Minimal Soulbound Token Implementation for Eco Energy Hub.
 * Tokens are non-transferable and represent governance rights earned through energy actions.
 */
contract CEToken {
    string public name = "Community Engagement Token";
    string public symbol = "CET";
    uint8 public decimals = 18;

    address public owner;
    mapping(address => uint256) private _balances;
    mapping(address => bool) public isVerifiedIdentity;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Locked(uint256 tokenId);
    event IdentityVerified(address indexed account);

    modifier onlyOwner() {
        require(msg.sender == owner, "CET: Caller is not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function verifyIdentity(address account) external onlyOwner {
        isVerifiedIdentity[account] = true;
        emit IdentityVerified(account);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        require(isVerifiedIdentity[to], "CET: Account identity not verified");
        _balances[to] += amount;
        emit Transfer(address(0), to, amount);
        emit Locked(amount);
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    // Block all transfers (Soulbound enforcement)
    function transfer(address, uint256) external pure returns (bool) {
        revert("CET: Soulbound token - transfers disabled");
    }

    function transferFrom(address, address, uint256) external pure returns (bool) {
        revert("CET: Soulbound token - transfers disabled");
    }
}