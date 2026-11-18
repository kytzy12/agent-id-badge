// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {AgentIDBadge} from "../src/AgentIDBadge.sol";

/// @notice Deploy AgentIDBadge.
/// @dev Local test (Anvil) — deploy a MockAgentID first, then:
///      anvil &
///      AGENT_ID=<mock address> forge script script/Deploy.s.sol \
///        --rpc-url http://127.0.0.1:8545 --broadcast
/// @dev Mainnet deploy — see README.md. DO NOT run without review.
///      forge script script/Deploy.s.sol --rpc-url $BSC_RPC_URL --broadcast \
///        --verify --verifier etherscan --etherscan-api-key $BSCSCAN_API_KEY
contract Deploy is Script {
    /// @notice Real Agent ID contract on BNB Chain mainnet (ERC-721, non-transferable).
    /// @dev EIP-55 checksummed form of 0x60b9262456de011f7d15a54cdd8c48baaa8b022f.
    address public constant AGENT_ID_MAINNET = 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F;

    function run() external {
        // The deployer becomes the initial owner. Override with DEPLOYER env var.
        address deployer = vm.envOr("DEPLOYER", msg.sender);
        // Point at the real Agent ID by default; override with AGENT_ID for local tests.
        address agentId = vm.envOr("AGENT_ID", AGENT_ID_MAINNET);

        vm.startBroadcast();
        AgentIDBadge badge = new AgentIDBadge(agentId, deployer);
        vm.stopBroadcast();

        console.log("AgentIDBadge deployed at:", address(badge));
        console.log("Agent ID contract used:", agentId);
        console.log("Owner:", deployer);
    }
}
