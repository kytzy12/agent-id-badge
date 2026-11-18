// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @notice Minimal mock of the Agent ID contract, for local tests only.
/// @dev The real Agent ID contract (0x60b9262456de011f7d15a54cdd8c48baaa8b022f)
///      is a non-transferable ERC-721. This mock lets tests grant / revoke
///      Agent ID "holdings" for arbitrary addresses. NEVER deploy this mock
///      to mainnet — the badge contract must point at the real Agent ID.
contract MockAgentID is ERC721 {
    uint256 private _nextId;

    constructor() ERC721("Mock Agent ID", "MAID") {}

    /// @notice Grant a mock Agent ID to `to`. Returns the mock token id.
    function grant(address to) external returns (uint256 tokenId) {
        tokenId = ++_nextId;
        _mint(to, tokenId);
    }

    /// @notice Revoke (burn) a mock Agent ID by token id.
    function revoke(uint256 tokenId) external {
        _burn(tokenId);
    }
}
