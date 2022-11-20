// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ISimpleSwap } from "./interface/ISimpleSwap.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SimpleSwap is ISimpleSwap, ERC20 {
    // Implement core logic here
    constructor(address _tokenA, address _tokenB) ERC20("SimpleSwap Token", "SST") {
        require(_tokenA != address(0), "SimpleSwap: TOKENA_IS_NOT_CONTRACT");
        require(_tokenB != address(0), "SimpleSwap: TOKENB_IS_NOT_CONTRACT");
        require(_tokenA != _tokenB, "SimpleSwap: TOKENA_TOKENB_IDENTICAL_ADDRESS");
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    address public tokenA;
    address public tokenB;

    function swap(address tokenIn, address tokenOut, uint256 amountIn) external override returns (uint256 amountOut) {}

    function addLiquidity(
        uint256 amountAIn,
        uint256 amountBIn
    ) external override returns (uint256 amountA, uint256 amountB, uint256 liquidity) {}

    function removeLiquidity(uint256 liquidity) external override returns (uint256 amountA, uint256 amountB) {}

    function getReserves() external view override returns (uint256 reserveA, uint256 reserveB) {
        return (ERC20(tokenA).balanceOf(address(this)), ERC20(tokenB).balanceOf(address(this)));
    }

    function getTokenA() external view override returns (address) {
        return tokenA;
    }

    function getTokenB() external view override returns (address) {
        return tokenB;
    }
}
