// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { MerkleAirdrop, IERC20 } from "../src/MerkleAirdrop.sol";
import { Script } from "forge-std/Script.sol";
import { Token } from "../src/Token.sol";
import { console } from "forge-std/console.sol";

contract DeployMerkleAirdrop is Script {
    bytes32 public ROOT = 0xcf729f33ab5eab9b05b70ba64ef3e2b6a02c8c94f1700b28bd4f49d52dc54cd1;
    // 4 users, 25 tokens each
    uint256 public AMOUNT_TO_TRANSFER = 4 * (25 * 1e18);

    // Deploy the airdrop contract and token contract
    function deployMerkleAirdrop() public returns (MerkleAirdrop, Token) {
        vm.startBroadcast();
        Token token = new Token();
        MerkleAirdrop airdrop = new MerkleAirdrop(ROOT, IERC20(token));
        // Send tokens -> Merkle Air Drop contract
        token.mint(token.owner(), AMOUNT_TO_TRANSFER);
        IERC20(token).transfer(address(airdrop), AMOUNT_TO_TRANSFER);
        vm.stopBroadcast();
        return (airdrop, token);
    }

    function run() external returns (MerkleAirdrop, Token) {
        return deployMerkleAirdrop();
    }
}