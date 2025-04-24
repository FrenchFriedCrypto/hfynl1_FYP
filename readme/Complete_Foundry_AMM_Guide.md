# 🔧 Complete Guide: Foundry + Anvil + AMM Pools + Token Factory

This document walks you through everything—from setting up your Windows environment with Foundry and Anvil, transferring local chain states, compiling smart contracts, deploying tokens and liquidity pools, and interacting with them through a web interface.

---

## 📌 Table of Contents

1. [Environment Setup on Windows](#1-environment-setup-on-windows)  
2. [Transferring Local Chain State](#2-transferring-local-chain-state)  
3. [Contract Architecture & Design](#3-contract-architecture--design)  
4. [Project Compilation & Deployment](#4-project-compilation--deployment)  
5. [Web Interface: Mint & Interact](#5-web-interface-mint--interact)  
6. [Troubleshooting](#6-troubleshooting)

---

## 1. Environment Setup on Windows

### 🖥️ Requirements

- Windows 10/11 (2004+)
- Administrator access
- Internet connection

### 🐧 Enable WSL 2 & Install Ubuntu

```powershell
wsl --install
```

> Reboot your PC and launch Ubuntu from the Start Menu.

### 🛠️ Install Dependencies

```bash
sudo apt update
sudo apt install -y curl git build-essential make gawk jq
```

### 🔧 Install Foundry

```bash
curl -L https://foundry.paradigm.xyz | bash    # installs `foundryup`
source ~/.bashrc                              # or reopen your shell
foundryup                                     # fetches latest forge, anvil...
```

---

## 2. Transferring Local Chain State

### 🧳 Export from PC A

1. Start Anvil:

   ```bash
   anvil
   ```
   
Alterntatively, run anvil with the following command to save its state on close:

    ```bash
    anvil       
    --port 8545  
    --chain-id 31337   
    --state anvil-state.json   
    --preserve-historical-states
    ```

2. Dump state:

   ```bash
   curl -s -X POST http://127.0.0.1:8545 -H "Content-Type: application/json" --data '{
     "jsonrpc":"2.0","id":1,"method":"anvil_dumpState","params":[]
   }' > anvil-state.hex
   ```

3. Transfer `anvil-state.hex` to new PC.

---

### 🖥️ Import on PC B

1. Ensure Git Bash and Foundry are installed.
2. Start Anvil:

   ```bash
   anvil &
   ANVIL_PID=$!
   ```

3. Load the state:

   ```bash
   STATE_HEX=$(< anvil-state.hex)
   curl -s -X POST http://127.0.0.1:8545 -H "Content-Type: application/json" --data "{
     \"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"anvil_loadState\",\"params\":[\"$STATE_HEX\"]
   }"
   ```

---

## 3. Stopping Anvil

- Press **Ctrl + C** in your Ubuntu terminal to gracefully stop the node.

---

---

## 4. Connecting to Anvil

- **In your dApp or scripts**, point your JSON-RPC provider to:
  ```
  http://127.0.0.1:8545
  ```
- **In MetaMask**:
    1. Open Settings → Networks → Add Network.
    2. Enter:
        - Network Name: `Anvil`
        - RPC URL: `http://localhost:8545`
        - Chain ID: `31337` (default)
        - Currency: `ETH`

Once added, switch MetaMask to the `Anvil` network to see your test accounts and balances.



---

## 5. Contract Architecture & Design

### 🧱 Tokens

- (MVP) Minimal Viable Product for ERC-20 token contract: `name`, `symbol`, `decimals`, `balanceOf`, `transfer`.

### 🔄 Dual-Token Pool

- Pair of tokens `token0` & `token1`.
- Users deposit equal values of both tokens to receive “pool services.”
- Supports a simple constant‑product swap.

(TODO FIX FORMULA)
- Constant-product swap formula:
  \[
  \text{amountOut} = \frac{rOut \times amountIn}{rIn + amountIn}
  \]
CHANGE THIS INTO FRACTION


### 🔁 Multi-Token Pool

- Arbitrary N‑token pool.
- Users deposit proportional amounts of up to 5 different tokens in one transaction.
- Generalized swap that routes from Token A → Token B within the same pool.

All contracts are written in Solidity 0.8.x, with no external dependencies beyond `IERC20`.

---

## Token Contract Design

Each token is a minimal ERC-20 implementation:

```solidity
contract SimpleToken {
  string public name;
  string public symbol;
  uint8  public decimals = 18;
  mapping(address => uint256) public balanceOf;

  constructor(string memory _name, string memory _symbol, uint256 _initialSupply) {
    name        = _name;
    symbol      = _symbol;
    balanceOf[msg.sender] = _initialSupply;
  }

  function transfer(address to, uint256 amount) external returns (bool) {
    require(balanceOf[msg.sender] >= amount, "insufficient balance");
    balanceOf[msg.sender] -= amount;
    balanceOf[to]         += amount;
    return true;
  }

  // Optional: approve/allowance if you need more advanced flows
}
```

- **Why minimal?** We only need `transfer` and `balanceOf` to seed pools and simulate swaps.
- There is **no** LP token, Factory contract, Deployer Address, Vault

---

## Dual-Token Pool

A classic 2-asset constant-product AMM:

```solidity
contract DualPool {
  IERC20 public token0;
  IERC20 public token1;
  uint112 private reserve0;
  uint112 private reserve1;

  constructor(address _token0, address _token1) {
    token0 = IERC20(_token0);
    token1 = IERC20(_token1);
  }

  function addLiquidity(uint256 amount0, uint256 amount1) external {
    token0.transferFrom(msg.sender, address(this), amount0);
    token1.transferFrom(msg.sender, address(this), amount1);
    reserve0 += uint112(amount0);
    reserve1 += uint112(amount1);
  }

  function swap(address tokenIn, uint256 amountIn) external {
    // Determine which side, apply constant‑product formula
    (IERC20 inToken, IERC20 outToken, uint112 rIn, uint112 rOut) =
      tokenIn == address(token0)
        ? (token0, token1, reserve0, reserve1)
        : (token1, token0, reserve1, reserve0);

    uint256 amountOut = (uint256(rOut) * amountIn) / (uint256(rIn) + amountIn);
    inToken.transferFrom(msg.sender, address(this), amountIn);
    outToken.transfer(msg.sender, amountOut);

    // Update reserves
    if (tokenIn == address(token0)) {
      reserve0 += uint112(amountIn);
      reserve1 -= uint112(amountOut);
    } else {
      reserve1 += uint112(amountIn);
      reserve0 -= uint112(amountOut);
    }
  }
}
```

### Constructor & State

- **`token0` / `token1`** – immutable token addresses.
- **`reserve0` / `reserve1`** – on-chain record of pool holdings.

### Liquidity Addition

1. User must `approve` both tokens to the pool contract.
2. Calls `addLiquidity(amount0, amount1)`.
3. Pool updates its reserves.

### Simple Swap Logic
(TODO FIX FORMULA)
- Implements a constant-product swap:  
  \[
  ext{amountOut} = rac{	ext{reserveOut} 	imes 	ext{amountIn}}
  {	ext{reserveIn} + 	ext{amountIn}}
  \]
- No fees, minimal branching for clarity.

---

## Multi-Token Pool

Generalizes the dual pool to N tokens:

```solidity
contract MultiPool {
  address[] public tokens;
  mapping(address => uint256) public reserveOf;

  constructor(address[] memory _tokens) {
    tokens = _tokens;
  }

  function addLiquidity(uint256[] calldata amounts) external {
    require(amounts.length == tokens.length, "length mismatch");
    for (uint i = 0; i < tokens.length; i++) {
      IERC20(tokens[i]).transferFrom(msg.sender, address(this), amounts[i]);
      reserveOf[tokens[i]] += amounts[i];
    }
  }

  function swap(address tokenIn, uint256 amountIn, address tokenOut) external {
    uint256 rIn  = reserveOf[tokenIn];
    uint256 rOut = reserveOf[tokenOut];
    uint256 amountOut = (rOut * amountIn) / (rIn + amountIn);

    IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
    IERC20(tokenOut).transfer(msg.sender, amountOut);

    reserveOf[tokenIn] += amountIn;
    reserveOf[tokenOut] -= amountOut;
  }
}
```

### Constructor & Dynamic Arrays

- Takes an `address[]` of up to 5 tokens.
- Stores them in storage for on-chain iteration.

### Batch Liquidity Addition

- Single call deposits _all_ N tokens.
- Cuts down on round trips and per‑token transactions.

### Generalized Swap

- Any `tokenIn → tokenOut` within the same pool.
- Same constant-product formula applied pairwise.

---

## 6. Key Design Decisions

1. **Simplicity over complexity**
    - No LP shares, mint/burn mechanics, or fees.
    - Focus on core AMM logic.
2. **On-chain reserves**
    - We maintain explicit `reserve` variables to avoid repeated balance queries.
3. **Batch operations**
    - Multi-Token Pool allows depositing up to 5 tokens in one tx to demonstrate dynamic looping in Solidity.
4. **Gas management**
    - Hand‑estimate & buffer gas for larger N, or use `estimateGas()` in deployment scripts.

---

### Future Extensions (TODO WORK ON IF GOT TIME)

- **LP token issuance** to track individual shares.
- **Swap fees** and **fee distribution**.
- **Price oracles** for slippage protection.
- **Permit** (ERC-20 `permit()`) to reduce upfront approvals.
- **Composable pools** where LP tokens themselves can be pooled.

---

## 7. Project Compilation & Deployment

### 🏗️ Layout

```
lp-deployers/
├── src/
│   ├── DualPool.sol
│   ├── MultiPool.sol
│   └── MyToken.sol
├── index.html
├── out/
└── foundry.toml
```

### 🔨 Build Contracts

```bash
forge build
```

### Extract ABI & Bytecode
- From `out/` Artifacts
  - **ABI:** copy the `abi` array from `out/<Contract>.sol/<Contract>.json`
  - **Bytecode:** copy the `bytecode` hex string


### For Front‑End: `index.html`

1. Place `index.html` at project root (alongside `src/` & `foundry.toml`).
2. Insert the ABIs & bytecodes of both contracts into the `<script>` block (Only necessary if chain is new):

   ```js
   const dualAbi      = [ /* paste DualPool ABI */ ];
   const dualBytecode = "0x…";  // DualPool bytecode

   const multiAbi      = [ /* paste MultiPool ABI */ ];
   const multiBytecode = "0x…"; // MultiPool bytecode

   ```

3. Insert your deployed token factory address (if you need to mint tokens on‑demand).

---

### 🚀 Deploy Token with Foundry

```bash
export PRIVATE_KEY=0x...     # from Anvil
forge create --broadcast \
  src/MyToken.sol:MyToken \
  --rpc-url http://127.0.0.1:8545 \
  --private-key $PRIVATE_KEY \
  --chain 31337 \
  --constructor-args "MyToken" "MTK" 1000000000000000000000
```
```bash
forge create 
    --broadcast   
    src/MyToken.sol:MyToken   
    --rpc-url http://127.0.0.1:8545   
    --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80   
    --chain 31337   
    --constructor-args     
    "TokenF" "FILF" 1000000000000000000000000
```

---


## 8. Web Interface: Mint & Interact

### 🌐 Prerequisites

- Web3 wallet (MetaMask or OKX)
- Anvil running on `localhost:8545`
- ABIs/bytecodes filled in `index.html`

### 🧪 Mint Pools via `index.html`

- **Dual LP Pool**:
  1. Open `index.html` in your browser.
  2. Allow your wallet to connect and authorize.
  3. Click **Mint Dual LP Pool & Add Liquidity**.
      - The UI will sequentially:
          - Deploy the DualPool contract.
          - Approve token0 and token1 (predefined tokens).
          - Perform a dry run of `addLiquidity`.
          - Add liquidity on-chain.
      - Status updates appear below the deploy button.
  4. Upon success, the pool address is saved to LocalStorage and shown in the **Deployed Pools** table.

- **Multi Token LP**:
  1. Open `index.html`.
  2. Set the **Number of tokens for Multi LP Pool** (1–5).
  3. Click **Mint Multi‑Token LP Pool & Add Liquidity**.
      - Workflow:
          - Deploy MultiPool contract with the selected tokens.
          - Approve each token for the pool.
          - Add liquidity via `addLiquidity(amounts[])`.
  4. The new pool is stored and displayed in the table.


## 9. Managing Pools
Once a pool is successfully minted it will appear in a table below. To remove a pool from the table (not from the blockchain, as that is immutable, this is purely a UX feature), there are two buttons a user can click on:

- **Remove**: Click the **Remove** button next to a pool to delete it.
- **Remove All Pools**: Click **Remove All Pools** to clear all stored pools and reset the table.

### 🔄 Swap via `interact.html`

1. To reach this webpage, users can either click on the "interact" button beside each pool in the index.html table or click on the "Interact / Swap" button in the navigation bar.
2. Select a pool from the **Choose Pool** dropdown (The firs deployed pool will be selected as teh default).
3. Choose **Token In**; for multi-token pools, choose **Token Out**.
4. Enter an amount into **Amount In** (e.g., `50`).
5. Click **Approve & Swap**:
    - Approves the token transfer.
    - (On the backend)
    - Executes `swap()` on the pool contract.
6. On completion, the **Swap Results** section updates:
    - **New Balance**: Your updated token balance.
    - **Pool Reserves**: Current reserves for the selected pool.

    
---

## 6. Troubleshooting

| Issue | Fix |
|-------|-----|
| `wsl` not recognized | Run PowerShell as Admin |
| `foundryup` not available | Check `~/.bashrc` PATH |
| `anvil` port already in use | Use `--port 7545` or any other free port |
| Swap fails | Ensure approvals and token order match |
| Nothing to compile | Place contracts under `src/` and run `forge build` |
| HTML doesn't work | Serve via HTTP (e.g., `npx http-server`) |

---

## ✅ Summary

- Set up a dev chain using Foundry’s Anvil.
- Transfer and reload chain states across PCs.
- Compile and deploy ERC-20 tokens and AMM liquidity pools.
- Mint and interact with smart contracts via a clean browser UI.

