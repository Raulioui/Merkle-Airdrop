// SPDX-Licence-Indentifier: MIT
pragma solidity ^0.8.24;

import { Script, console } from "forge-std/Script.sol";
import { DevOpsTools } from "foundry-devops/src/DevOpsTools.sol";
import { MerkleAirdrop } from "../src/MerkleAirdrop.sol";

contract ClaimAirdrop is Script {
    address private constant CLAIMER = 0x13FFba08c4C6636062c4fD812A97a67EAfc2Fe2B;
    uint256 private constant AMOUNT_TO_CLAIM = (25 * 1e18); 

    bytes32 addressProof = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 amountProof = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] private proof = [addressProof, amountProof];

    // Signature of the message hash of the claimer address and the amount to claim
    bytes private SIGNATURE = hex"80cd043c22d1db47710282292dec15a7c9c4f54cc0569329dba6840957258933646c2c7c8ea685dd5321625bc7105ca82207adcb5ec5014b38450468b57b1b6c1c";

    error ClaimAirdropScript__InvalidSignatureLength();

    function claimAirdrop(address airdrop) public {
        vm.startBroadcast();
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(SIGNATURE);
        console.log("Claiming Airdrop");
        MerkleAirdrop(airdrop).claim(CLAIMER, AMOUNT_TO_CLAIM, proof, v, r, s);
        vm.stopBroadcast();
        console.log("Claimed Airdrop");
    }

    function splitSignature(bytes memory sig) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        // 32 + 32 + 1 = 65
        require(sig.length == 65, "ClaimAirdrop: Invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("MerkleAirdrop", block.chainid);
        claimAirdrop(mostRecentlyDeployed);
    }
}