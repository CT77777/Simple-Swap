// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ISimpleSwap } from "./interface/ISimpleSwap.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "hardhat/console.sol";

contract SimpleSwap is ISimpleSwap, ERC20 {
    using Math for uint256; // ^0.8 version already pre-check overflow

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

    function swap(address tokenIn, address tokenOut, uint256 amountIn) external override returns (uint256 amountOut) {
        require(tokenIn != tokenOut, "SimpleSwap: IDENTICAL_ADDRESS");
        require(tokenIn == tokenA || tokenIn == tokenB, "SimpleSwap: INVALID_TOKEN_IN");
        require(tokenOut == tokenA || tokenOut == tokenB, "SimpleSwap: INVALID_TOKEN_OUT");
        require(amountIn != 0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");

        //非整數時有精度問題需修正
        uint256 reserveACurrent = ERC20(tokenA).balanceOf(address(this));
        uint256 reserveBCurrent = ERC20(tokenB).balanceOf(address(this));
        uint256 k = reserveACurrent * reserveBCurrent;
        amountOut = reserveBCurrent - (k / (reserveACurrent + amountIn));
        require(amountOut >= 1 * 10 ** 18, "SimpleSwap: INSUFFICIENT_OUTPUT_AMOUNT");

        ERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        ERC20(tokenOut).transfer(msg.sender, amountOut);

        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
        return amountOut;
    }

    function addLiquidity(
        uint256 amountAIn,
        uint256 amountBIn
    ) external override returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        require(amountAIn != 0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");
        require(amountBIn != 0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");

        uint256 reserveACurrent = ERC20(tokenA).balanceOf(address(this));
        uint256 reserveBCurrent = ERC20(tokenB).balanceOf(address(this));
        uint256 actualAmountA;
        uint256 actualAmountB;

        if (totalSupply() == 0) {
            actualAmountA = amountAIn;
            actualAmountB = amountBIn;
            liquidity = Math.sqrt(actualAmountA * actualAmountB);
            _mint(msg.sender, liquidity);
            ERC20(tokenA).transferFrom(msg.sender, address(this), actualAmountA);
            ERC20(tokenB).transferFrom(msg.sender, address(this), actualAmountB);
        } else {
            uint256 proportionTokenA = ((amountAIn * type(uint32).max) / reserveACurrent);
            uint256 proportionTokenB = ((amountBIn * type(uint32).max) / reserveBCurrent);

            if (proportionTokenA == proportionTokenB) {
                actualAmountA = amountAIn;
                actualAmountB = amountBIn;
                liquidity = Math.sqrt(actualAmountA * actualAmountB);
                _mint(msg.sender, liquidity);
                ERC20(tokenA).transferFrom(msg.sender, address(this), actualAmountA);
                ERC20(tokenB).transferFrom(msg.sender, address(this), actualAmountB);
            }
            if (proportionTokenA < proportionTokenB) {
                actualAmountA = amountAIn;
                actualAmountB = reserveBCurrent * (amountAIn / reserveACurrent);
                liquidity = Math.sqrt(actualAmountA * actualAmountB);
                _mint(msg.sender, liquidity);
                ERC20(tokenA).transferFrom(msg.sender, address(this), actualAmountA);
                ERC20(tokenB).transferFrom(msg.sender, address(this), actualAmountB);
            }
            if (proportionTokenA > proportionTokenB) {
                actualAmountA = reserveACurrent * (amountBIn / reserveBCurrent);
                actualAmountB = amountBIn;
                liquidity = Math.sqrt(actualAmountA * actualAmountB);
                _mint(msg.sender, liquidity);
                ERC20(tokenA).transferFrom(msg.sender, address(this), actualAmountA);
                ERC20(tokenB).transferFrom(msg.sender, address(this), actualAmountB);
            }
        }

        emit AddLiquidity(msg.sender, actualAmountA, actualAmountB, liquidity);

        return (actualAmountA, actualAmountB, liquidity);
    }

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

    //approve token A allowance to SimpleSwap
    function approveTokenA(uint256 _allowrance) external {
        ERC20(tokenA).approve(address(this), _allowrance);
    }

    //approve token B allowance to SimpleSwap
    function approveTokenB(uint256 _allowrance) external {
        ERC20(tokenB).approve(address(this), _allowrance);
    }
}
