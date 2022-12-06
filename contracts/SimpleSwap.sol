// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ISimpleSwap } from "./interface/ISimpleSwap.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "hardhat/console.sol";

contract SimpleSwap is ISimpleSwap, ERC20 {
    using Math for uint256; // ^0.8 version already pre-check overflow

    // Implement core logic here

    address public tokenA;
    address public tokenB;

    constructor(address _tokenA, address _tokenB) ERC20("SimpleSwap Token", "SST") {
        require(_tokenA != address(0), "SimpleSwap: TOKENA_IS_NOT_CONTRACT");
        require(_tokenB != address(0), "SimpleSwap: TOKENB_IS_NOT_CONTRACT");
        require(_tokenA != _tokenB, "SimpleSwap: TOKENA_TOKENB_IDENTICAL_ADDRESS");
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    function swap(address tokenIn, address tokenOut, uint256 amountIn) external override returns (uint256 amountOut) {
        require(tokenIn != tokenOut, "SimpleSwap: IDENTICAL_ADDRESS");
        require(tokenIn == tokenA || tokenIn == tokenB, "SimpleSwap: INVALID_TOKEN_IN");
        require(tokenOut == tokenA || tokenOut == tokenB, "SimpleSwap: INVALID_TOKEN_OUT");
        require(amountIn != 0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");

        // get reserve before swapping
        uint256 reserveInPre = IERC20(tokenIn).balanceOf(address(this));
        uint256 reserveOutPre = IERC20(tokenOut).balanceOf(address(this));
        // x * y = k
        uint256 k = reserveInPre * reserveOutPre;
        // amountOut = reserveBCurrent - (k / (reserveACurrent + amountIn));
        // amountOut = (reserveOutPre * amountIn) / (reserveInPre + amountIn);
        amountOut = (reserveOutPre * amountIn) / (reserveInPre + amountIn);

        require(amountOut > 0, "SimpleSwap: INSUFFICIENT_OUTPUT_AMOUNT");

        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).transfer(msg.sender, amountOut);
        uint256 reserveInNew = IERC20(tokenIn).balanceOf(address(this));
        uint256 reserveOutNew = IERC20(tokenOut).balanceOf(address(this));
        require(reserveInNew * reserveOutNew >= k, "k value doesn't pass criteria");
        uint256 actualAmountIn = reserveInNew - reserveInPre;
        uint256 actualAmountOut = reserveOutPre - reserveOutNew;

        emit Swap(msg.sender, tokenIn, tokenOut, actualAmountIn, actualAmountOut);
        return actualAmountOut;
    }

    function addLiquidity(
        uint256 amountAIn,
        uint256 amountBIn
    ) external override returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        require(amountAIn != 0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");
        require(amountBIn != 0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");

        uint256 reserveACurrent = IERC20(tokenA).balanceOf(address(this));
        uint256 reserveBCurrent = IERC20(tokenB).balanceOf(address(this));
        uint256 actualAmountA;
        uint256 actualAmountB;

        // first add liquidity
        if (totalSupply() == 0) {
            actualAmountA = amountAIn;
            actualAmountB = amountBIn;
            liquidity = Math.sqrt(actualAmountA * actualAmountB);
            _mint(msg.sender, liquidity);
            IERC20(tokenA).transferFrom(msg.sender, address(this), actualAmountA);
            IERC20(tokenB).transferFrom(msg.sender, address(this), actualAmountB);
        } else {
            uint256 proportionTokenA = ((amountAIn * type(uint32).max) / reserveACurrent);
            uint256 proportionTokenB = ((amountBIn * type(uint32).max) / reserveBCurrent);

            // add liquidity (reserveA:reserveB = tokenAIn:tokenBIn)
            if (proportionTokenA == proportionTokenB) {
                actualAmountA = amountAIn;
                actualAmountB = amountBIn;
                liquidity = Math.sqrt(actualAmountA * actualAmountB);
                _mint(msg.sender, liquidity);
                IERC20(tokenA).transferFrom(msg.sender, address(this), actualAmountA);
                IERC20(tokenB).transferFrom(msg.sender, address(this), actualAmountB);
            }
            // add liquidity (reserveA:reserveB > tokenAIn:tokenBIn)
            else if (proportionTokenA < proportionTokenB) {
                actualAmountA = amountAIn;
                actualAmountB = reserveBCurrent * (amountAIn / reserveACurrent);
                liquidity = Math.sqrt(actualAmountA * actualAmountB);
                _mint(msg.sender, liquidity);
                IERC20(tokenA).transferFrom(msg.sender, address(this), actualAmountA);
                IERC20(tokenB).transferFrom(msg.sender, address(this), actualAmountB);
            }
            // add liquidity (reserveA:reserveB < tokenAIn:tokenBIn)
            else if (proportionTokenA > proportionTokenB) {
                actualAmountA = reserveACurrent * (amountBIn / reserveBCurrent);
                actualAmountB = amountBIn;
                liquidity = Math.sqrt(actualAmountA * actualAmountB);
                _mint(msg.sender, liquidity);
                IERC20(tokenA).transferFrom(msg.sender, address(this), actualAmountA);
                IERC20(tokenB).transferFrom(msg.sender, address(this), actualAmountB);
            }
        }

        emit AddLiquidity(msg.sender, actualAmountA, actualAmountB, liquidity);

        return (actualAmountA, actualAmountB, liquidity);
    }

    function removeLiquidity(uint256 liquidity) external override returns (uint256 amountA, uint256 amountB) {
        require(liquidity != 0, "SimpleSwap: INSUFFICIENT_LIQUIDITY_BURNED");

        //get reserve before removeLiquidity
        uint256 reserveACurrent = ERC20(tokenA).balanceOf(address(this));
        uint256 reserveBCurrent = ERC20(tokenB).balanceOf(address(this));
        //get LP token supply before removeLiquidity
        uint256 totalSupplyCurrent = totalSupply();
        //calculate removed amount of tokekA/B by multiple big number to resolve precision problem
        uint256 amountACalculated = reserveACurrent * ((liquidity * 10 ** 18) / totalSupplyCurrent);
        uint256 amountBCalculated = reserveBCurrent * ((liquidity * 10 ** 18) / totalSupplyCurrent);
        //calculate actual removed amount of tokekA/B by divided big number
        uint256 actualAmountA = amountACalculated / 10 ** 18;
        uint256 actualAmountB = amountBCalculated / 10 ** 18;

        _burn(msg.sender, liquidity);
        IERC20(tokenA).transfer(msg.sender, actualAmountA);
        IERC20(tokenB).transfer(msg.sender, actualAmountB);

        emit RemoveLiquidity(msg.sender, actualAmountA, actualAmountB, liquidity);
        emit Transfer(address(this), address(0), liquidity);

        return (actualAmountA, actualAmountB);
    }

    function getReserves() external view override returns (uint256 reserveA, uint256 reserveB) {
        return (IERC20(tokenA).balanceOf(address(this)), IERC20(tokenB).balanceOf(address(this)));
    }

    function getTokenA() external view override returns (address) {
        return tokenA;
    }

    function getTokenB() external view override returns (address) {
        return tokenB;
    }
}
