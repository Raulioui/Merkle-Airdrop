# Merkle Airdrop

Advanced Merkle Airdrop with Foundry and Digital Signatures - Advanced token airdrop system using Foundry, leveraging Merkle proofs for efficient eligibility verification.

---

## ✨ Features

* **Merkle allowlist**: Only addresses in the tree can claim.
* **Second‑preimage hardened leaves**: `leaf = keccak256( keccak256(abi.encode(addr, amount)) )`.
* **EIP‑712 signed claims**: Optional meta‑tx flow — any sender can submit if the recipient signed.
* **Idempotent**: One claim per address.
* **Tested with Foundry**.

---

## 🧱 Architecture

**Contracts**

* `Token.sol` — Simple ERC20 with owner‑mint for funding the airdrop.
* `MerkleAirdrop.sol` — Core verifier & distributor.

**Scripts**

* `GenerateInput.s.sol` — Create `input.json` with `[address, amount]` entries.
* `CreateMerkle.s.sol` — Build leaves and proofs using Murky, output `output.json` (per‑user proof, leaf, root).
* `ClaimAirdrop.s.sol` — Example claim broadcast using a precomputed signature & proof.

**Test**

* `MerkleAirdrop.t.sol` — Positive path & double‑claim revert.

---

## 🧾 Leaf format

The tree commits to `(address account, uint256 amount)` per user.

```
leaf = keccak256( bytes.concat( keccak256(abi.encode(account, amount)) ) )
```

This matches the Murky script implementation, which converts both values to 32‑byte words and removes array offset/length before hashing, then re‑hashes to mitigate second‑preimage attacks.

---

## 📦 Requirements

* Foundry (forge + cast)
* Node.js (optional)

Dependencies (via `forge install`):

* OpenZeppelin Contracts
* Murky
* foundry‑devops

---

## 🚀 Quickstart

```bash
# 1) Install deps
forge install OpenZeppelin/openzeppelin-contracts@v5.0.2 \
             dmihal/murky \
             ChainAccelOrg/foundry-devops

# 2) Build & test
forge build
forge test -vv

# 3) Generate inputs (addresses & equal amounts)
forge script script/GenerateInput.s.sol --broadcast --rpc-url <RPC>

# 4) Build Merkle proofs & root
forge script script/CreateMerkle.s.sol --broadcast --rpc-url <RPC>
# Output: script/target/output.json (per address: inputs, proof[], root, leaf)

# 5) Deploy token & airdrop (example Foundry script or manual)
# Token is minted to owner, then owner funds the airdrop contract.

# 6) Claim
forge script script/ClaimAirdrop.s.sol --broadcast --rpc-url <RPC>
```

> The provided sample JSON files demonstrate the expected structure for `input.json` and the generated `output.json`.

---

## 🔐 EIP‑712 signed claim

To enable relayed claims, the contract requires an EIP‑712 signature by the **recipient** over `(account, amount)`:

```
AirdropClaim(address account,uint256 amount)
```

The script/test show how to compute `getMessageHash(account, amount)` and sign with Foundry’s `vm.sign`. The contract verifies the signature and checks the Merkle proof, then transfers tokens and marks the address as claimed.

---
