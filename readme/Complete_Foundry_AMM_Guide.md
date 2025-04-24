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
curl -L https://foundry.paradigm.xyz | bash
source ~/.bashrc
foundryup
```

---

## 2. Transferring Local Chain State

### 🧳 Export from PC A

1. Start Anvil:

   ```bash
   anvil
   ```

2. Dump state:

   ```bash
   curl -s -X POST http://127.0.0.1:8545 -H "Content-Type: application/json" --data '{
     "jsonrpc":"2.0","id":1,"method":"anvil_dumpState","params":[]
   }' > anvil-state.hex
   ```

3. Transfer `anvil-state.hex` to PC B.

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

## 3. Contract Architecture & Design

### 🧱 Tokens

- Minimal ERC-20: `name`, `symbol`, `decimals`, `balanceOf`, `transfer`.

### 🔄 Dual-Token Pool

- Holds `token0`, `token1`.
- Constant-product swap formula:
  \[
  \text{amountOut} = \frac{rOut \times amountIn}{rIn + amountIn}
  \]

### 🔁 Multi-Token Pool

- Supports up to 5 tokens.
- Generalized pairwise swapping within the pool.

---

## 4. Project Compilation & Deployment

### 🏗️ Layout

\`\`\`
lp-deployers/
├── src/
│   ├── DualPool.sol
│   ├── MultiPool.sol
│   └── MyToken.sol
├── index.html
├── out/
└── foundry.toml
\`\`\`

### 🔨 Build Contracts

```bash
forge build
```

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

---

## 5. Web Interface: Mint & Interact

### 🌐 Prerequisites

- Web3 wallet (MetaMask or OKX)
- Anvil running on `localhost:8545`
- ABIs/bytecodes filled in `index.html`

### 🧪 Mint Pools via `index.html`

- **Dual LP Pool**:
  - Deploy `DualPool`
  - Approve tokens
  - Add liquidity
- **Multi Token LP**:
  - Select token count (1–5)
  - Deploy `MultiPool`
  - Batch approve & deposit

### 🔄 Swap via `interact.html`

- Select pool
- Choose tokenIn/tokenOut
- Approve & swap
- Results show updated balance & reserves

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

You're now equipped to:

- Set up a dev chain using Foundry’s Anvil.
- Transfer and reload chain states across PCs.
- Compile and deploy ERC-20 tokens and AMM liquidity pools.
- Mint and interact with smart contracts via a clean browser UI.

