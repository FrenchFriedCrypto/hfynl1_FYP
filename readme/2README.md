# README 2
# Local Anvil State Transfer & Setup

This guide shows how to export your Anvil chain state from **PC A**, copy it to **PC B**, and then import it—plus everything you need to install on the new machine.

---

## Prerequisites on PC B

Before importing the snapshot, install:

1. **Git Bash (includes `curl` & Unix tools)**
   Download and run the Git for Windows installer (which bundles Git Bash):
   ```bash
   # Download from official site, then double-click and follow prompts:
   https://git-scm.com/download/win
   ```

2. **OKX Web3 Wallet (Chrome/Firefox extension)**
   1. Visit OKX Web3 Wallet page:
      ```text
      https://www.okx.com/web3
      ```
   2. Click **Connect Wallet** → **Install extension** → **Add to Chrome/Firefox**.
   3. Pin the extension via the browser’s puzzle-piece icon.

3. **Foundry (forge, cast, anvil, chisel)**
   Open Git Bash and run:
   ```bash
   curl -L https://foundry.paradigm.xyz | bash    # installs `foundryup`
   source ~/.bashrc                              # or reopen your shell
   foundryup                                     # fetches latest forge, anvil, cast…
   ```
   *Windows users must use Git Bash or WSL; PowerShell/CMD are not supported.*

---

## 1. On PC A: Export the Chain State

1. **Start Anvil**
   ```bash
   anvil
   ```
2. **In a new Git Bash shell**, dump state:
   ```bash
   curl -s -X POST http://127.0.0.1:8545      -H "Content-Type: application/json"      --data '{
       "jsonrpc":"2.0",
       "id":1,
       "method":"anvil_dumpState",
       "params":[]
     }' > anvil-state.hex
   ```
3. **Stop Anvil** (`Ctrl+C`).  
   You now have `anvil-state.hex`.

---

## 2. Transfer the Snapshot

Copy `anvil-state.hex` to **PC B** via USB, `scp`, Git, Dropbox, etc.

---

## 3. On PC B: Import & Run

1. **Ensure Foundry is installed** (see Prerequisites above).
2. **Start Anvil** in the same folder as `anvil-state.hex`:
   ```bash
   anvil &
   ANVIL_PID=$!
   ```
3. **Load the saved state**:
   ```bash
   STATE_HEX=$(< anvil-state.hex)
   curl -s -X POST http://127.0.0.1:8545      -H "Content-Type: application/json"      --data "{
       "jsonrpc":"2.0",
       "id":1,
       "method":"anvil_loadState",
       "params":["$STATE_HEX"]
     }"
   ```
   Your Anvil node now mirrors PC A’s chain.

---

## 4. Verify

- **Block number:**
  ```bash
  cast block-number
  ```
- **Account balances / contracts:**
  ```bash
  cast balance <ADDRESS>
  ```
- **Deploy / interact** exactly where you left off.

---

Happy coding!
