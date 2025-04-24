# README 4
# Pool Minter & Interactor Usage Guide

## Introduction
This guide describes how to mint dual-token and multi-token liquidity pools using the `index.html` page and how to interact (swap tokens) via the `interact.html` page.

## Prerequisites
- A Web3 wallet (e.g., MetaMask) connected to the desired network.
- Browser storage enabled (LocalStorage) for persisting pool addresses.
- Ensure `index.html` and `interact.html` are served over HTTP(S) or opened as file:// if CORS settings permit.

## Minting Pools

### Mint Dual LP Pool
1. Open `index.html` in your browser.
2. Allow your wallet to connect and authorize.
3. Click **Mint Dual LP Pool & Add Liquidity**.
   - The UI will sequentially:
     - Deploy the DualPool contract.
     - Approve token0 and token1 (predefined tokens).
     - Perform a dry run of `addLiquidity`.
     - Add liquidity on-chain.
   - Status updates appear in the **Status** paragraph.
4. Upon success, the pool address is saved to LocalStorage and shown in the **Deployed Pools** table.

### Mint Multi-Token LP Pool
1. Open `index.html`.
2. Set the **Number of tokens for Multi LP Pool** (1–5).
3. Click **Mint Multi‑Token LP Pool & Add Liquidity**.
   - Workflow:
     - Deploy MultiPool contract with the selected tokens.
     - Approve each token for the pool.
     - Add liquidity via `addLiquidity(amounts[])`.
4. The new pool is stored and displayed in the table.

## Managing Pools
- **Remove**: Click the **Remove** button next to a pool to delete it.
- **Remove All Pools**: Click **Remove All Pools** to clear all stored pools and reset the table.

## Interacting & Swapping Tokens

1. Open `interact.html`.
2. Select a pool from the **Choose Pool** dropdown.
3. Choose **Token In**; for multi-token pools, choose **Token Out**.
4. Enter an amount in **Amount In** (e.g., `1.5`).
5. Click **Approve & Swap**:
   - Approves the token transfer.
   - Executes `swap()` on the pool contract.
   - On completion, the **Swap Results** section updates:
     - **New Balance**: Your updated token balance.
     - **Pool Reserves**: Current reserves for the selected pool.

## Persistence
- Pool data is stored in LocalStorage under keys `dualPool_<address>` and `multiPool_<address>`.
- To reset, use the **Remove** buttons or clear LocalStorage manually via browser dev tools.

## Troubleshooting
- Ensure your wallet is unlocked and on the correct network.
- Check the browser console for detailed error logs.
