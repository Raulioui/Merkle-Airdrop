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

## 🧪 Testing

Key tests:

* `testUserCanClaim` — Happy path: proof + signature transfers tokens.
* `testRevertsIfUserAlreadyClaimed` — Second claim reverts.

Run with:

```bash
forge test -vv
```

---

## 🛠️ Configuration

**Token decimals & amounts**

* The repo uses 18 decimals. Adjust `AMOUNT` in `GenerateInput.s.sol` as needed.

**Allowlist**

* Edit `whitelist[]` in `GenerateInput.s.sol` to set recipients.

**Paths**

* Scripts write to `script/target/input.json` and `script/target/output.json`.

---

## 📁 Repo layout (suggested)

```
root/
├─ src/
│  ├─ Token.sol
│  └─ MerkleAirdrop.sol
├─ script/
│  ├─ GenerateInput.s.sol
│  ├─ CreateMerkle.s.sol
│  ├─ ClaimAirdrop.s.sol
│  └─ target/
│     ├─ input.json
│     └─ output.json
└─ test/
   └─ MerkleAirdrop.t.sol
```

---

## ⚠️ Security notes

* **Use `safeTransfer`** for ERC‑20 sends in case tokens don’t return `bool`.
* **Set `hasClaimed` before transfer** (already done) to prevent re‑entrancy.
* **Immutable `merkleRoot` and `airdropToken`** (already done) — prevents admin tampering.
* **Signature domain** — make sure the `TYPEHASH` is clearly named and matches the struct.
* **Funding** — ensure the airdrop contract is funded before users claim.

---

## 🔧 Potential improvements

* Rename `DOMAIN_SEPARATOR` constant to `TYPEHASH` to reflect its purpose.
* Remove unused `address[] public claimers;` or push to it only if you need an index.
* Replace `airdropToken.transfer` with `IERC20(…).safeTransfer`.
* Add an owner‑only `sweep` function for accidental ETH/token recovery (non‑airdrop tokens).
* Emit remaining airdrop balance or total distributed metrics.
* Gas: pack storage (`hasClaimed` is already mapping<bool>; fine).
* Add negative tests: wrong proof, wrong amount, wrong signer, replay with different amount.

---

## 📄 License

MIT

