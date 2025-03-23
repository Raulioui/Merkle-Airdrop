// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MerkleAirdrop is EIP712 {
    using SafeERC20 for IERC20;

    event Claimed(address account, uint256 amount);

    address[] public claimers;
    bytes32 private immutable merkleRoot;
    IERC20 private immutable airdropToken;

    bytes32 private constant DOMAIN_SEPARATOR = keccak256(
        "AirdropClaim(address account, uint256 amount)"
    );

    mapping(address user => bool claimed) public hasClaimed;

    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    constructor(bytes32 _merkleRoot, IERC20 _airdropToken) EIP712("MerkleAirdrop", "1") {
        merkleRoot = _merkleRoot;
        airdropToken = _airdropToken;
    }   

    function claim(
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(!hasClaimed[account], "MerkleAirdrop: Account already claimed");
        require(_isValidSignature(account, getMessageHash(account, amount), v, r, s), "MerkleAirdrop: Invalid signature");

        // Avoiding Second Preimage Attack (https://flawed.net.nz/2018/02/21/attacking-merkle-trees-with-a-second-preimage-attack/)
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));

        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "MerkleAirdrop: Invalid proof");

        hasClaimed[account] = true;

        emit Claimed(account, amount);

        airdropToken.transfer(account, amount);
    }

    function getMessageHash(address account, uint256 amount) public view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(abi.encode(DOMAIN_SEPARATOR, AirdropClaim({account: account, amount: amount})))
        );
    }

    function _isValidSignature(address account, bytes32 digest, uint8 v, bytes32 r, bytes32 s) internal pure returns (bool) {
        (address recoveredSigner, , ) = ECDSA.tryRecover(digest, v, r, s);
        return account == recoveredSigner;
    }

    function getMerkleRoot() external view returns (bytes32) {
        return merkleRoot;
    }

    function getAirDropToken() external view returns (IERC20) {
        return airdropToken;
    }
}