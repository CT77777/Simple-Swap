// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ISimpleSwap } from "./interface/ISimpleSwap.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SimpleSwap is ISimpleSwap, ERC20 {
    // Implement core logic here
    constructor() ERC20("SimpleSwap Token", "SST") {}

    function swap(address tokenIn, address tokenOut, uint256 amountIn) external override returns (uint256 amountOut) {}

    function addLiquidity(
        uint256 amountAIn,
        uint256 amountBIn
    ) external override returns (uint256 amountA, uint256 amountB, uint256 liquidity) {}

    function removeLiquidity(uint256 liquidity) external override returns (uint256 amountA, uint256 amountB) {}

    function getReserves() external view override returns (uint256 reserveA, uint256 reserveB) {}

    function getTokenA() external view override returns (address tokenA) {}

    function getTokenB() external view override returns (address tokenB) {}
}
