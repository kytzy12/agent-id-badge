// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {AgentIDBadge} from "../src/AgentIDBadge.sol";
import {MockAgentID} from "../test/MockAgentID.sol";

/// @notice Local end-to-end check on Anvil ONLY. Never run on mainnet.
/// Deploys MockAgentID, grants a mock Agent ID to the broadcaster, deploys
/// the badge contract, mints token #1, and prints the tokenURI so it can be
/// decoded and verified off-chain (see README.md).
contract LocalE2E is Script {
    function run() external {
        vm.startBroadcast();
        MockAgentID mock = new MockAgentID();
        uint256 mockId = mock.grant(msg.sender);
        AgentIDBadge badge = new AgentIDBadge(address(mock), msg.sender);
        uint256 tokenId = badge.mint();
        vm.stopBroadcast();

        console.log("MockAgentID:  ", address(mock));
        console.log("Mock token id granted to minter:", mockId);
        console.log("AgentIDBadge:", address(badge));
        console.log("Minted badge token id:", tokenId);
        console.log("Owner of badge #1:", badge.ownerOf(tokenId));
        console.log("totalMinted:", badge.totalMinted());
        console.log("tokenURI:");
        console.log(badge.tokenURI(tokenId));
    }
}
