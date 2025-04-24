# Getting Started with Foundry Anvil on Windows

This README will guide you through setting up a fresh Windows installation to running a local Ethereum node using Foundry’s Anvil tool. You’ll install WSL 2, a Linux distro, Foundry, and any necessary dependencies.

---

## Table of Contents

1. [Requirements](#requirements)  
2. [Enable WSL 2 & Install Ubuntu](#enable-wsl-2--install-ubuntu)  
3. [Install Common Dependencies](#install-common-dependencies)  
4. [Install Foundry](#install-foundry)  
5. [Using Anvil (Local Ethereum Node)](#using-anvil-local-ethereum-node)  
6. [Connecting to Anvil](#connecting-to-anvil)  
7. [Troubleshooting](#troubleshooting)  

---

## Requirements

- Windows 10 (2004+) or Windows 11  
- Administrator access to enable WSL  
- Internet connection  

---

## 1. Enable WSL 2 & Install Ubuntu

1. **Open PowerShell as Administrator**  
   - Press **Win + X**, choose **Windows PowerShell (Admin)**
2. **Enable the WSL feature**  
   ```powershell
   wsl --install
   ```
   - This command will enable the required components, install the latest Ubuntu distro, and set WSL 2 as default.
3. **Reboot your machine** when prompted.
4. **Launch Ubuntu** from the Start Menu.  
   - On first run, you’ll be asked to create a UNIX username and password.

---

## 2. Install Common Dependencies

In your Ubuntu terminal:

```bash
# Update package lists
sudo apt update

# Install essentials: curl, Git, build tools
sudo apt install -y curl git build-essential

# (Optional) Install additional tooling
sudo apt install -y make gawk jq
```

---

## 3. Install Foundry

Foundry provides the `forge`, `cast`, and `anvil` tools.

1. **Download & install Foundry**  
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   ```
2. **Activate Foundry in your shell**  
   ```bash
   source ~/.bashrc
   ```
3. **Update to latest Foundry release**  
   ```bash
   foundryup
   ```
4. **Verify installation**  
   ```bash
   forge --version
   cast --version
   anvil --version
   ```

---

## 4. Using Anvil (Local Ethereum Node)

Anvil spins up a local Ethereum JSON-RPC node—great for development and testing.

- **Start Anvil**  
  ```bash
  anvil
  ```
  - By default, Anvil:
    - Runs on HTTP `http://127.0.0.1:8545`
    - Pre-funds 20 test accounts
    - Displays private keys and chain ID in the console

- **Common flags**  
  - Specify a different port:  
    ```bash
    anvil --port 7545
    ```
  - Fork a live network (e.g., mainnet) at a specific block:  
    ```bash
    anvil --fork-url https://mainnet.infura.io/v3/YOUR_INFURA_KEY --fork-block-number 17000000
    ```
  - Increase chain ID or block time:  
    ```bash
    anvil --chain-id 1337 --block-time 2
    ```

---

## 5. Connecting to Anvil

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

## 6. Stopping Anvil

- Press **Ctrl + C** in your Ubuntu terminal to gracefully stop the node.

---

## 7. Troubleshooting

- **“`wsl` is not recognized”**  
  - Make sure you’re running PowerShell as Administrator.
  - Update Windows to the latest version.
- **Foundry commands not found**  
  - Confirm that `~/.foundry/bin` is added to your PATH in `~/.bashrc`.
- **Port already in use**  
  - Specify a different port with `--port`.
- **“fork-url” errors**  
  - Ensure your Infura/Alchemy key is valid and your network URL is correct.

---

Congratulations! You should now have a fully functional local Ethereum node running via Foundry’s Anvil on Windows. Happy developing!
