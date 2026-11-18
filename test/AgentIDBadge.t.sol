// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {AgentIDBadge} from "../src/AgentIDBadge.sol";
import {MockAgentID} from "./MockAgentID.sol";

/// @notice Test suite for AgentIDBadge.
/// Required coverage:
///   (1) mint succeeds for an Agent ID holder
///   (2) mint fails for a non-holder
///   (3) a second mint from the same wallet fails
///   (4) tokenURI is a valid base64 data URI (JSON + inline SVG present)
///   (5) the owner cannot mint on behalf of someone else
/// Plus: payment rejection, direct-transfer rejection, metadata updates.
contract AgentIDBadgeTest is Test {
    AgentIDBadge public badge;
    MockAgentID public agentId;

    address public owner = address(0xA11CE);
    address public holder = address(0xB0B);
    address public holder2 = address(0xC0FFEE);
    address public nonHolder = address(0xDEAD);

    string internal constant JSON_PREFIX = "data:application/json;base64,";
    string internal constant SVG_PREFIX = "data:image/svg+xml;base64,";

    function setUp() public {
        agentId = new MockAgentID();
        badge = new AgentIDBadge(address(agentId), owner);
        agentId.grant(holder);
        agentId.grant(holder2);
    }

    // ------------------------------------------------------------------
    // (1) Mint succeeds for an Agent ID holder
    // ------------------------------------------------------------------
    function test_MintSucceedsForHolder() public {
        vm.prank(holder);
        uint256 tokenId = badge.mint();
        assertEq(tokenId, 1);
        assertEq(badge.ownerOf(1), holder);
        assertTrue(badge.hasMinted(holder));
        assertEq(badge.totalMinted(), 1);
    }

    function test_MintIdsAreSequential() public {
        vm.prank(holder);
        assertEq(badge.mint(), 1);
        vm.prank(holder2);
        assertEq(badge.mint(), 2);
        assertEq(badge.totalMinted(), 2);
    }

    // ------------------------------------------------------------------
    // (2) Mint fails for a non-holder
    // ------------------------------------------------------------------
    function test_MintFailsForNonHolder() public {
        vm.prank(nonHolder);
        vm.expectRevert(AgentIDBadge.NotAgentIDHolder.selector);
        badge.mint();
    }

    function test_MintFailsAfterAgentIDRevoked() public {
        // holder loses their Agent ID before minting -> mint must fail
        agentId.revoke(2); // holder2's mock token id is 2
        vm.prank(holder2);
        vm.expectRevert(AgentIDBadge.NotAgentIDHolder.selector);
        badge.mint();
    }

    // ------------------------------------------------------------------
    // (3) A second mint from the same wallet fails
    // ------------------------------------------------------------------
    function test_SecondMintFails() public {
        vm.prank(holder);
        badge.mint();
        vm.prank(holder);
        vm.expectRevert(AgentIDBadge.AlreadyMinted.selector);
        badge.mint();
    }

    // ------------------------------------------------------------------
    // (4) tokenURI is valid: base64 JSON with name/description/image,
    //     image is a base64 SVG containing "<svg"
    // ------------------------------------------------------------------
    function test_TokenURIValid() public {
        vm.prank(holder);
        badge.mint();

        string memory uri = badge.tokenURI(1);
        assertTrue(_startsWith(uri, JSON_PREFIX), "tokenURI must start with data:application/json;base64,");

        string memory json = string(_base64Decode(_slice(uri, bytes(JSON_PREFIX).length)));
        assertTrue(bytes(json).length > 0, "decoded JSON must not be empty");

        string memory name = vm.parseJsonString(json, ".name");
        assertEq(name, "Agent ID Badge #1");

        string memory description = vm.parseJsonString(json, ".description");
        assertTrue(bytes(description).length > 20, "description must be present");

        string memory image = vm.parseJsonString(json, ".image");
        assertTrue(_startsWith(image, SVG_PREFIX), "image must be a data:image/svg+xml;base64 URI");

        string memory svg = string(_base64Decode(_slice(image, bytes(SVG_PREFIX).length)));
        assertTrue(_contains(svg, "<svg"), "decoded image must contain <svg");
        assertTrue(_contains(svg, "Agent ID Badge"), "SVG must contain the badge name");
        assertTrue(_contains(svg, "#1"), "SVG must contain the token id");
    }

    function test_TokenURINonexistentReverts() public {
        vm.expectRevert(AgentIDBadge.NonexistentToken.selector);
        badge.tokenURI(999);
    }

    // ------------------------------------------------------------------
    // (5) The owner cannot mint on behalf of someone else.
    //     There is no mintTo / admin-mint function: mint() always mints
    //     to msg.sender only. After the owner mints, other addresses are
    //     unaffected and can still mint their own badge.
    // ------------------------------------------------------------------
    function test_OwnerCannotMintForOthers() public {
        // The owner is NOT an Agent ID holder, so even the owner's own
        // mint() must fail — ownership grants no minting power at all.
        vm.prank(owner);
        vm.expectRevert(AgentIDBadge.NotAgentIDHolder.selector);
        badge.mint();

        // Give the owner an Agent ID: owner can then mint ONLY for itself.
        agentId.grant(owner);
        vm.prank(owner);
        uint256 tokenId = badge.mint();
        assertEq(badge.ownerOf(tokenId), owner);
        assertFalse(badge.hasMinted(holder), "holder must be unaffected by owner's mint");
        assertFalse(badge.hasMinted(holder2), "holder2 must be unaffected by owner's mint");

        // Holders can still mint their own badges afterwards.
        vm.prank(holder);
        assertEq(badge.mint(), 2);
    }

    // ------------------------------------------------------------------
    // Payments are rejected: no funds ever enter the contract
    // ------------------------------------------------------------------
    function test_MintWithValueReverts() public {
        vm.deal(holder, 1 ether);
        vm.prank(holder);
        vm.expectRevert(AgentIDBadge.PaymentNotAccepted.selector);
        badge.mint{value: 0.001 ether}();
        assertEq(address(badge).balance, 0);
    }

    function test_DirectTransferReverts() public {
        vm.prank(holder);
        vm.deal(holder, 1 ether);
        (bool ok,) = address(badge).call{value: 0.01 ether}("");
        assertFalse(ok, "direct BNB transfer must be rejected");
        assertEq(address(badge).balance, 0);
    }

    // ------------------------------------------------------------------
    // Owner powers: only name/description updates, only by owner
    // ------------------------------------------------------------------
    function test_OwnerCanUpdateNameAndDescription() public {
        vm.prank(owner);
        badge.setBadgeName("Agent ID Badge v2");
        vm.prank(owner);
        badge.setBadgeDescription("Updated description.");
        assertEq(badge.badgeName(), "Agent ID Badge v2");
        assertEq(badge.badgeDescription(), "Updated description.");

        vm.prank(holder);
        badge.mint();
        string memory json = string(_base64Decode(_slice(badge.tokenURI(1), bytes(JSON_PREFIX).length)));
        assertEq(vm.parseJsonString(json, ".name"), "Agent ID Badge v2 #1");
    }

    function test_NonOwnerCannotUpdateMetadata() public {
        vm.prank(holder);
        vm.expectRevert();
        badge.setBadgeName("Hacked");
        vm.prank(holder);
        vm.expectRevert();
        badge.setBadgeDescription("Hacked");
    }

    // ------------------------------------------------------------------
    // Helpers: base64 decode, prefix check, substring search, slicing
    // ------------------------------------------------------------------
    function _startsWith(string memory s, string memory prefix) internal pure returns (bool) {
        bytes memory sb = bytes(s);
        bytes memory pb = bytes(prefix);
        if (sb.length < pb.length) return false;
        for (uint256 i = 0; i < pb.length; i++) {
            if (sb[i] != pb[i]) return false;
        }
        return true;
    }

    function _slice(string memory s, uint256 start) internal pure returns (string memory) {
        bytes memory b = bytes(s);
        require(start <= b.length, "slice out of bounds");
        bytes memory out = new bytes(b.length - start);
        for (uint256 i = 0; i < out.length; i++) {
            out[i] = b[start + i];
        }
        return string(out);
    }

    function _contains(string memory haystack, string memory needle) internal pure returns (bool) {
        bytes memory h = bytes(haystack);
        bytes memory n = bytes(needle);
        if (n.length == 0 || n.length > h.length) return false;
        for (uint256 i = 0; i <= h.length - n.length; i++) {
            bool found = true;
            for (uint256 j = 0; j < n.length; j++) {
                if (h[i + j] != n[j]) {
                    found = false;
                    break;
                }
            }
            if (found) return true;
        }
        return false;
    }

    function _b64val(bytes1 c) internal pure returns (uint256) {
        uint8 v = uint8(c);
        if (v >= 65 && v <= 90) return v - 65; // A-Z
        if (v >= 97 && v <= 122) return v - 71; // a-z
        if (v >= 48 && v <= 57) return v + 4; // 0-9
        if (v == 43) return 62; // +
        if (v == 47) return 63; // /
        return 0; // '=' padding
    }

    function _base64Decode(string memory data) internal pure returns (bytes memory) {
        bytes memory b = bytes(data);
        uint256 len = b.length;
        uint256 padding;
        if (len >= 1 && b[len - 1] == "=") padding++;
        if (len >= 2 && b[len - 2] == "=") padding++;
        uint256 outLen = (len * 3) / 4 - padding;
        bytes memory out = new bytes(outLen);
        uint256 j;
        for (uint256 i = 0; i < len; i += 4) {
            uint256 n = (_b64val(b[i]) << 18) | (_b64val(b[i + 1]) << 12) | (_b64val(b[i + 2]) << 6)
                | _b64val(b[i + 3]);
            if (j < outLen) out[j++] = bytes1(uint8(n >> 16));
            if (j < outLen) out[j++] = bytes1(uint8(n >> 8));
            if (j < outLen) out[j++] = bytes1(uint8(n));
        }
        return out;
    }
}
