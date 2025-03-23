// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test, console2 } from "forge-std/Test.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {Token} from "../src/Token.sol";
import {ZkSyncChainChecker} from "foundry-devops/src/ZkSyncChainChecker.sol";

contract MerkleAirdropTest is Test {
    MerkleAirdrop public airdrop;
    Token public token;

    bytes32 public ROOT = 0x86b96300244262a710ea539381606436fcea5e9b65beaa2ba1d4402ee1162858;

    bytes32 addressProof = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 amountProof = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] public USERPROOF = [addressProof, amountProof];
    
    uint256 airdropAmount = 25e18;
    uint256 initialAmount = 100e18;

    address user;
    uint256 userPrivateKey;

    address payer;

    function setUp() public {
        token = new Token();
        airdrop = new MerkleAirdrop(ROOT, token);

        token.mint(token.owner(), initialAmount);
        token.transfer(address(airdrop), initialAmount);

        payer = makeAddr("payer");
        (user, userPrivateKey) = makeAddrAndKey("user");
    }

    function signMessage(uint256 privKey, address account) public view returns (uint8 v, bytes32 r, bytes32 s) {
        bytes32 hashedMessage = airdrop.getMessageHash(account, airdropAmount);
        (v, r, s) = vm.sign(privKey, hashedMessage);
    }

    function testUserCanClaim() public {
        require(token.balanceOf(user) == 0);
        
        vm.startPrank(user);
        (uint8 v, bytes32 r, bytes32 s) = signMessage(userPrivateKey, user);
        vm.stopPrank();

        vm.prank(payer);
        airdrop.claim(user, airdropAmount, USERPROOF, v, r, s);

        require(token.balanceOf(user) == airdropAmount);
    }

    function testRevertsIfUserAlreadyClaimed() public {
        require(token.balanceOf(user) == 0);

        (uint8 v, bytes32 r, bytes32 s) = signMessage(userPrivateKey, user);
        
        vm.prank(user);
        airdrop.claim(user, airdropAmount, USERPROOF, v, r, s);

        vm.prank(user);
        vm.expectRevert("MerkleAirdrop: Account already claimed");
        airdrop.claim(user, airdropAmount, USERPROOF, v, r, s);
    }
}