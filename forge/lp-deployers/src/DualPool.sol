// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

contract DualPool {
    IERC20 public token0;
    IERC20 public token1;
    uint112 private reserve0;
    uint112 private reserve1;

    event LiquidityAdded(address indexed provider, uint256 amount0, uint256 amount1, uint112 newReserve0, uint112 newReserve1);
    event Swapped(address indexed buyer, address indexed tokenIn, uint256 amountIn, address indexed tokenOut, uint256 amountOut);

    constructor(address _token0, address _token1) {
        require(_token0 != _token1, "Tokens must differ");
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    /// @notice Adds liquidity in proportion to current reserves
    function addLiquidity(uint256 amount0, uint256 amount1) external {
        // transfer tokens in
        token0.transferFrom(msg.sender, address(this), amount0);
        token1.transferFrom(msg.sender, address(this), amount1);
        // update reserves
        reserve0 += uint112(amount0);
        reserve1 += uint112(amount1);
        emit LiquidityAdded(msg.sender, amount0, amount1, reserve0, reserve1);
    }

    /// @notice Swaps exactly `amountIn` of tokenIn for tokenOut
    function swap(address tokenIn, uint256 amountIn) external {
        require(tokenIn == address(token0) || tokenIn == address(token1), "Invalid tokenIn");
        // identify in/out
        (IERC20 inToken, IERC20 outToken, uint112 resIn, uint112 resOut) =
            tokenIn == address(token0)
                ? (token0, token1, reserve0, reserve1)
                : (token1, token0, reserve1, reserve0);

        // constant‐product formula: amountOut = resOut - (resIn * resOut) / (resIn + amountIn)
        uint256 numerator   = uint256(resIn) * uint256(resOut);
        uint256 denominator = uint256(resIn) + amountIn;
        uint256 amountOut   = uint256(resOut) - (numerator / denominator);

        require(amountOut > 0, "Insufficient output");
        // transfer tokens
        inToken.transferFrom(msg.sender, address(this), amountIn);
        outToken.transfer(msg.sender, amountOut);

        // update reserves
        if (tokenIn == address(token0)) {
            reserve0 = uint112(resIn + amountIn);
            reserve1 = uint112(resOut - amountOut);
        } else {
            reserve1 = uint112(resIn + amountIn);
            reserve0 = uint112(resOut - amountOut);
        }

        emit Swapped(msg.sender, tokenIn, amountIn, address(outToken), amountOut);
    }

    /// @notice Expose reserves for UI
    function getReserves() external view returns (uint112, uint112) {
        return (reserve0, reserve1);
    }
}
