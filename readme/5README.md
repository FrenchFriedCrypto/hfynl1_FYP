# Liquidity Pool & Token Factory Demo

This repository demonstrates how to:
1. Compile minimal AMM pool contracts (dual‑token & multi‑token) using Foundry.  
2. Compile and deploy a simple ERC‑20 token factory contract.  
3. Build a static HTML/JavaScript front‑end that, with a single button click, deploys new pool or token contracts on a local chain and persists their addresses in `localStorage`.  

---

## Table of Contents

- [Prerequisites](#prerequisites)  
- [Project Layout](#project-layout)  
- [1. Setup Foundry Project](#1-setup-foundry-project)  
- [2. Compile Contracts](#2-compile-contracts)  
- [3. Run Local Node (Anvil)](#3-run-local-node-anvil)  
- [3.1 Persist & Transfer Chain State](#31-persist--transfer-chain-state)  
- [4. Compile & Deploy ERC‑20 Token Factory](#4-compile--deploy-erc-20-token-factory)  
- [5. Extract ABI & Bytecode](#5-extract-abi--bytecode)  
- [6. Front‑End: `index.html`](#6-front-end-indexhtml)  
- [7. Serve & Test](#7-serve--test)  
- [8. Troubleshooting](#8-troubleshooting)  

---

## Prerequisites

- **Node.js** (for `npx http-server`) or **Python 3** (for `python3 -m http.server`)  
- **Foundry** (forge & anvil) installed  
- A browser wallet that can connect to a custom RPC (OKX Wallet, MetaMask, etc.)  

---

## Project Layout

```
lp-deployers/
├── foundry.toml
├── src/
│   ├── DualPool.sol
│   ├── MultiPool.sol
│   └── MyToken.sol
├── out/                    ← compiled artifacts (ABI & bytecode)
│   ├── DualPool.sol/
│   ├── MultiPool.sol/
│   └── MyToken.sol/
├── index.html             ← front‑end interface
└── args.txt               ← (optional) constructor args file
```

---

## 1. Setup Foundry Project

```bash
# In your workspace folder:
forge init lp-deployers --no-git
cd lp-deployers

# Copy your .sol files into src/:
# - DualPool.sol
# - MultiPool.sol
# - MyToken.sol
```

---

## 2. Compile Contracts

```bash
forge build
```

- Outputs JSON artifacts in `out/<Contract>.sol/<Contract>.json`  
- Each JSON includes `"abi"` and `"bytecode"`  

---

## 3. Run Local Node (Anvil)

In a separate terminal, start Anvil:

```bash
anvil --chain-id 31337 --port 8545
```

- Prints 20 unlocked accounts & private keys  
- Pick one account’s private key for deployments  

---

## 3.1 Persist & Transfer Chain State

To save your chain’s state and resume it on another machine, run Anvil with state dump/load:

```bash
anvil   --port 8545   --chain-id 31337   --state anvil-state.json   --preserve-historical-states
```

- `--state anvil-state.json` loads the file if present, and dumps updated state on exit  
- `--preserve-historical-states` retains all block data for RPC queries  
- **Transfer** the `anvil-state.json` file to another PC and restart Anvil with the same command to continue where you left off  

---

## 4. Compile & Deploy ERC‑20 Token Factory

### 4.1 Compile

```bash
forge build
```

### 4.2 Deploy (“broadcast” to network)

```bash
# Export your chosen private key:
export PRIVATE_KEY=0x…<anvil-key>…

forge create --broadcast   src/MyToken.sol:MyToken   --rpc-url http://127.0.0.1:8545   --private-key $PRIVATE_KEY   --chain 31337   --constructor-args     "MyToken" "MTK" 1000000000000000000000
```

- The `--broadcast` flag sends the transaction to your node instead of doing a dry‑run  
- Owner can later call `mint(...)`  
- Copy the `Deployed to: 0x…` token address if needed  

---

## 5. Extract ABI & Bytecode

### 5.1 From `out/` Artifacts

- **ABI:** copy the `abi` array from `out/<Contract>.sol/<Contract>.json`  
- **Bytecode:** copy the `bytecode` hex string  

### 5.2 With `forge inspect`

```bash
forge inspect src/DualPool.sol:DualPool abi    > dualAbi.json
forge inspect src/MultiPool.sol:MultiPool abi  > multiAbi.json
forge inspect src/MyToken.sol:MyToken abi      > tokenAbi.json
```

---

## 6. Front‑End: `index.html`

1. Place `index.html` at project root (alongside `src/` & `foundry.toml`).  
2. Edit ABIs & bytecodes into the `<script>` block:

   ```js
   const dualAbi      = [ /* paste DualPool ABI */ ];
   const dualBytecode = "0x…";  // DualPool bytecode

   const multiAbi      = [ /* paste MultiPool ABI */ ];
   const multiBytecode = "0x…"; // MultiPool bytecode

   const tokenAbi      = [ /* paste MyToken ABI */ ];
   const tokenBytecode = "0x…"; // MyToken bytecode
   ```

3. Insert your deployed token factory address (if you need to mint tokens on‑demand).  

---

## 7. Serve & Test

```bash
# From project root:
npx http-server .        # → http://localhost:8080
# or
python3 -m http.server 8000
```

1. Open `http://localhost:8080/index.html`  
2. Switch OKX/MetaMask to **Custom RPC** → `http://localhost:8545`  
3. Click buttons:
   - **Mint Dual LP Pool** → deploys `DualPool`  
   - **Mint Multi‑Token LP Pool** → deploys `MultiPool`  
   - **Mint ERC‑20 Token** → deploys `MyToken`  

Statuses and deployed addresses will appear on‑page and in `localStorage`.

---

## 8. Troubleshooting

- **“Nothing to compile”**  
  Ensure `.sol` files live under `src/` and rerun `forge build`.  
- **Unicode errors**  
  Replace non‑ASCII (e.g. “≥”) with ASCII (`>=`) in `require()` messages.  
- **Dry run enabled**  
  `forge create` warns “not broadcasting” if you omit `--broadcast` or `--private-key`. Include `--broadcast` and correct flags.  
- **HTML click doesn’t fire**  
  Serve over HTTP (not `file://`), open DevTools Console, check for errors or missing contract addresses/ABIs.  

---

Happy building—and now you have a **fully self‑contained** demo of on‑demand pool & token deployment from a static HTML page!
