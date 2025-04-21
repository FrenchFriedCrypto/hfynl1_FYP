// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

contract MultiPool {
    address[] public tokens;
    mapping(address => uint256) public reserves;  // token → reserve

    event LiquidityAdded(address indexed provider, address[] tokens, uint256[] amounts);
    event Swapped(address indexed buyer, address indexed tokenIn, uint256 amountIn, address indexed tokenOut, uint256 amountOut);

    constructor(address[] memory _tokens, uint256[] memory initialAmounts) {
        require(_tokens.length >= 2, "Need >=2 tokens");
        require(_tokens.length == initialAmounts.length, "Tokens != amounts");

        tokens = _tokens;
        for (uint i = 0; i < tokens.length; i++) {
            address t = tokens[i];
            uint256 amt = initialAmounts[i];
            IERC20(t).transferFrom(msg.sender, address(this), amt);
            reserves[t] = amt;
        }
        emit LiquidityAdded(msg.sender, tokens, initialAmounts);
    }

    /// @notice Add balanced liquidity across all tokens
    function addLiquidity(uint256[] memory amounts) external {
        require(amounts.length == tokens.length, "Bad array length");
        for (uint i = 0; i < tokens.length; i++) {
            address t = tokens[i];
            IERC20(t).transferFrom(msg.sender, address(this), amounts[i]);
            reserves[t] += amounts[i];
        }
        emit LiquidityAdded(msg.sender, tokens, amounts);
    }

    /// @notice Swap exact `amountIn` of `tokenIn` for `tokenOut` using N‑variate constant product
    function swap(address tokenIn, uint256 amountIn, address tokenOut) external {
        require(reserves[tokenIn] > 0 && reserves[tokenOut] > 0, "Invalid tokens");

        // compute current product k = Π reserves
        uint256 k = 1;
        for (uint i = 0; i < tokens.length; i++) {
            k = k * reserves[tokens[i]];
        }

        // new reserveIn = old + amountIn
        uint256 newReserveIn = reserves[tokenIn] + amountIn;
        // solve for newReserveOut = k / (Π other reserves * newReserveIn)
        uint256 prodOther = k / reserves[tokenOut];
        uint256 newReserveOut = prodOther / newReserveIn;

        uint256 amountOut = reserves[tokenOut] - newReserveOut;
        require(amountOut > 0, "Insufficient output");

        // execute
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).transfer(msg.sender, amountOut);

        // update reserves
        reserves[tokenIn] += amountIn;
        reserves[tokenOut] -= amountOut;

        emit Swapped(msg.sender, tokenIn, amountIn, tokenOut, amountOut);
    }

    /// @notice Get all current reserves in order
    function getAllReserves() external view returns (uint256[] memory) {
        uint256[] memory out = new uint256[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            out[i] = reserves[tokens[i]];
        }
        return out;
    }
}
