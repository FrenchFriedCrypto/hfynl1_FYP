// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

contract MultiPool {
    // --- State ---
    address[] public tokens;
    mapping(address => uint256) public reserves;  // token → reserve

    // --- Events ---
    event LiquidityAdded(address indexed provider, address[] tokens, uint256[] amounts);
    event Swapped(
        address indexed buyer,
        address indexed tokenIn,
        uint256 amountIn,
        address indexed tokenOut,
        uint256 amountOut
    );

    /// @notice Constructor: only registers tokens, no deposits here
    constructor(address[] memory _tokens) {
        require(_tokens.length >= 2, "Need >=2 tokens");
        tokens = _tokens;
        // initialize reserves to zero
        for (uint i = 0; i < tokens.length; i++) {
            reserves[tokens[i]] = 0;
        }
    }

    /// @notice Add (initial) liquidity: caller must approve this contract first
    function addLiquidity(uint256[] memory amounts) external {
        require(amounts.length == tokens.length, "Bad array length");
        for (uint i = 0; i < tokens.length; i++) {
            address t = tokens[i];
            uint256 amt = amounts[i];
            require(
                IERC20(t).transferFrom(msg.sender, address(this), amt),
                "TF"
            );
            reserves[t] += amt;
        }
        emit LiquidityAdded(msg.sender, tokens, amounts);
    }

    /// @notice Swap exact `amountIn` of `tokenIn` for `tokenOut` using N‑variate constant product
    function swap(address tokenIn, uint256 amountIn, address tokenOut)
    external
    {
        uint256 Rin = reserves[tokenIn];
        uint256 Rout = reserves[tokenOut];
        require(Rin > 0 && Rout > 0, "Invalid tokens");

        // pull in
        require(IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn),
            "TF in");

        // 2-token constant-product formula
        uint256 amountOut = (amountIn * Rout) / (Rin + amountIn);
        require(amountOut > 0, "Insufficient output");

        // push out
        require(IERC20(tokenOut).transfer(msg.sender, amountOut),
            "TF out");

        // update reserves
        reserves[tokenIn]  = Rin + amountIn;
        reserves[tokenOut] = Rout - amountOut;

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
