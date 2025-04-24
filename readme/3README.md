# README 3
# Automated AMM Pools & Token Factory

This document describes the methodology and architecture behind our on-chain token and liquidity‑pool contracts. We implement two core pool types—Dual-Token Pool and Multi-Token Pool—on top of minimal ERC-20 token contracts. The focus here is on the **design decisions**, **core logic**, and **deployment flows** used in each contract.

---

## Table of Contents

1. [Project Overview](#project-overview)  
2. [Token Contract Design](#token-contract-design)  
3. [Dual-Token Pool](#dual-token-pool)  
   - [Constructor & State](#constructor--state)  
   - [Liquidity Addition](#liquidity-addition)  
   - [Simple Swap Logic](#simple-swap-logic)  
4. [Multi-Token Pool](#multi-token-pool)  
   - [Constructor & Dynamic Arrays](#constructor--dynamic-arrays)  
   - [Batch Liquidity Addition](#batch-liquidity-addition)  
   - [Generalized Swap](#generalized-swap)  
5. [Key Design Decisions](#key-design-decisions)  
6. [Future Extensions](#future-extensions)  

---

## Project Overview

- **ERC-20 Tokens**  
  - Minimal compliant tokens with `name`, `symbol`, `decimals`, and `balanceOf`/`transfer` functionality.  
- **Dual-Token Pool**  
  - Pair of tokens `token0` & `token1`.  
  - Users deposit equal values of both tokens to receive “pool services.”  
  - Supports a simple constant‑product swap.  
- **Multi-Token Pool**  
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

## Key Design Decisions

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

## Future Extensions

- **LP token issuance** to track individual shares.  
- **Swap fees** and **fee distribution**.  
- **Price oracles** for slippage protection.  
- **Permit** (ERC-20 `permit()`) to reduce upfront approvals.  
- **Composable pools** where LP tokens themselves can be pooled.

---

*End of README.md*
