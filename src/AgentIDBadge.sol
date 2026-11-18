// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/// @notice Minimal interface of the Agent ID contract (ERC-721, non-transferable).
/// @dev Only balanceOf is needed: an address holds an Agent ID iff balanceOf > 0.
interface IAgentID {
    function balanceOf(address account) external view returns (uint256);
}

/// @title Agent ID Badge
/// @notice Free, non-transferable-by-design (standard ERC-721) achievement badge.
///         One badge per wallet, mintable ONLY by addresses that hold an Agent ID.
///         The contract NEVER accepts or holds user funds: mint() is free and
///         rejects any attached value, and direct BNB transfers are rejected.
/// @dev Metadata is fully on-chain: tokenURI returns a base64 data URI with
///      JSON + an inline SVG image. No IPFS, no external URLs.
contract AgentIDBadge is ERC721, Ownable {
    using Strings for uint256;

    /// @notice The Agent ID contract on BNB Chain mainnet.
    ///         0x60b9262456de011f7d15a54cdd8c48baaa8b022f
    IAgentID public immutable agentId;

    /// @notice Next token id to mint. Token ids start at 1.
    uint256 public nextTokenId;

    /// @notice True if an address has already minted its (single) badge.
    mapping(address => bool) public hasMinted;

    /// @notice Badge name shown in the metadata (owner-updatable, see below).
    string public badgeName = "Agent ID Badge";

    /// @notice Badge description shown in the metadata (owner-updatable).
    string public badgeDescription =
        "A free achievement badge for Agent ID holders. One badge per wallet. "
        "This badge proves its holder owns an Agent ID on BNB Chain. "
        "It has no monetary value and grants no financial return.";

    /// @notice Emitted when a badge is minted.
    event BadgeMinted(address indexed minter, uint256 indexed tokenId);

    /// @notice Emitted when the owner updates the badge name.
    event BadgeNameUpdated(string newName);

    /// @notice Emitted when the owner updates the badge description.
    event BadgeDescriptionUpdated(string newDescription);

    error NotAgentIDHolder();
    error AlreadyMinted();
    error PaymentNotAccepted();
    error NonexistentToken();

    /// @param _agentId Address of the Agent ID contract.
    /// @param initialOwner Address that deploys / owns the contract.
    constructor(address _agentId, address initialOwner)
        ERC721("Agent ID Badge", "AIDB")
        Ownable(initialOwner)
    {
        require(_agentId != address(0), "AgentIDBadge: zero Agent ID address");
        agentId = IAgentID(_agentId);
    }

    /// @notice Mint the caller's one free badge.
    /// @dev Requirements:
    ///      - msg.value must be 0 (mint is free; payments are rejected).
    ///      - caller must hold an Agent ID (balanceOf > 0 on the Agent ID contract).
    ///      - caller must not have minted before (one badge per wallet).
    function mint() external payable returns (uint256 tokenId) {
        if (msg.value > 0) revert PaymentNotAccepted();
        if (hasMinted[msg.sender]) revert AlreadyMinted();
        if (agentId.balanceOf(msg.sender) == 0) revert NotAgentIDHolder();

        tokenId = ++nextTokenId;
        hasMinted[msg.sender] = true;
        _safeMint(msg.sender, tokenId);
        emit BadgeMinted(msg.sender, tokenId);
    }

    /// @notice Total number of badges minted so far.
    function totalMinted() external view returns (uint256) {
        return nextTokenId;
    }

    /// @notice Fully on-chain metadata: base64 JSON with an inline SVG image.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (_ownerOf(tokenId) == address(0)) revert NonexistentToken();

        string memory svg = _buildSvg(tokenId);
        string memory json = string(
            abi.encodePacked(
                '{"name":"',
                badgeName,
                " #",
                tokenId.toString(),
                '","description":"',
                badgeDescription,
                '","image":"data:image/svg+xml;base64,',
                Base64.encode(bytes(svg)),
                '","attributes":[{"trait_type":"Badge","value":"Agent ID Holder"},'
                '{"trait_type":"Token ID","value":',
                tokenId.toString(),
                "}]}"
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    /// @dev Builds the badge SVG for a token id.
    function _buildSvg(uint256 tokenId) internal view returns (string memory) {
        return string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" width="400" height="400" viewBox="0 0 400 400">',
                "<defs><linearGradient id=\"g\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\">",
                '<stop offset="0%" stop-color="#f0b90b"/><stop offset="100%" stop-color="#8a6d00"/>',
                "</linearGradient></defs>",
                '<rect width="400" height="400" rx="24" fill="url(#g)"/>',
                '<rect x="14" y="14" width="372" height="372" rx="18" fill="none" stroke="#ffffff" stroke-opacity="0.55" stroke-width="2"/>',
                '<circle cx="200" cy="150" r="62" fill="#1e2026"/>',
                '<text x="200" y="172" font-family="sans-serif" font-size="64" font-weight="bold" fill="#f0b90b" text-anchor="middle">ID</text>',
                '<text x="200" y="268" font-family="sans-serif" font-size="30" font-weight="bold" fill="#ffffff" text-anchor="middle">',
                badgeName,
                "</text>",
                '<text x="200" y="306" font-family="sans-serif" font-size="20" fill="#f5f5f5" text-anchor="middle">Agent ID Holder</text>',
                '<text x="200" y="344" font-family="sans-serif" font-size="18" fill="#f5f5f5" text-anchor="middle">#',
                tokenId.toString(),
                "</text>",
                "</svg>"
            )
        );
    }

    // ------------------------------------------------------------------------
    // Owner powers (MINIMAL — see README.md "Owner permissions").
    // The owner may ONLY update the badge name/description shown in metadata.
    // The owner CANNOT: mint to arbitrary addresses, withdraw funds (the
    // contract holds none and rejects payments), pause, freeze, or change
    // any fee (there are no fees). Ownership can be renounced.
    // ------------------------------------------------------------------------

    /// @notice Update the badge name used in token metadata. Owner only.
    function setBadgeName(string calldata newName) external onlyOwner {
        badgeName = newName;
        emit BadgeNameUpdated(newName);
    }

    /// @notice Update the badge description used in token metadata. Owner only.
    function setBadgeDescription(string calldata newDescription) external onlyOwner {
        badgeDescription = newDescription;
        emit BadgeDescriptionUpdated(newDescription);
    }

    // ------------------------------------------------------------------------
    // Reject all incoming funds. This contract never accepts or stores BNB.
    // ------------------------------------------------------------------------

    receive() external payable {
        revert PaymentNotAccepted();
    }

    fallback() external payable {
        revert PaymentNotAccepted();
    }
}
