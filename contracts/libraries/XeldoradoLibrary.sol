// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import '../interfaces/IXeldoradoPair.sol';
import '../interfaces/IXeldoradoFactory.sol';
import '../interfaces/IXeldoradoVault.sol';
import '../interfaces/IERC20X.sol';

import "./SafeMath.sol";

import '../XeldoradoVault.sol';
import '../CreatorVestingVault.sol';

library XeldoradoLibrary {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'XeldoradoLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'XeldoradoLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = IXeldoradoFactory(factory).getPair(token0, token1);
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IXeldoradoPair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'XeldoradoLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'XeldoradoLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }
    
    function calculateFee(uint amount, uint fee) internal pure returns (uint) {
        // fee percent in scale of 10000
        return amount.mul(fee)/10000;
    }

    // if extra tokens needed then extraBaseTokensNeeded will be greator then 0 and leftOverCreatorTokensDeposited will be 0
    // otherwise leftOverBaseTokensDeposited will be greator then 0 and extraBaseTokensNeeded will be 0
    function crossCreatorNFTSwapStats(address _swapper, address _inVault, address _outVault) internal view returns(uint extraBaseTokensNeeded, uint leftOverBaseTokensDeposited, uint amountOut, uint amountIn, uint creatorTokensOut, uint creatorTokensIn) {
        // Creator Tokens of In NFT

        if(IXeldoradoFactory(IXeldoradoVault(_inVault).factory()).noOFTokensForDiscount() <= IERC20X(IXeldoradoFactory(IXeldoradoVault(_inVault).factory()).exchangeToken()).balanceOf(_swapper))
        {
            creatorTokensOut = IXeldoradoVault(_inVault).singleNFTPrice().sub(calculateFee(IXeldoradoVault(_inVault).singleNFTPrice(), IXeldoradoFactory(IXeldoradoVault(_inVault).factory()).nftFee().sub(IXeldoradoFactory(IXeldoradoVault(_inVault).factory()).nftDiscount()).add(IXeldoradoCreatorFactory(IXeldoradoPair(IXeldoradoVault(_inVault).pair()).creatorfactory()).creatorNFTFee(IXeldoradoVault(_inVault).creator())))); // singleNFTPrice - xfee + cfee
        }
        else{
            creatorTokensOut = IXeldoradoVault(_inVault).singleNFTPrice().sub(calculateFee(IXeldoradoVault(_inVault).singleNFTPrice(), IXeldoradoFactory(IXeldoradoVault(_inVault).factory()).nftFee().add(IXeldoradoCreatorFactory(IXeldoradoPair(IXeldoradoVault(_inVault).pair()).creatorfactory()).creatorNFTFee(IXeldoradoVault(_inVault).creator())))); // singleNFTPrice - xfee + cfee
        }

        // Creator Tokens to Base Tokens for In NFT
        (uint reserve0, uint reserve1,) = IXeldoradoPair(IXeldoradoVault(_inVault).pair()).getReserves();
        amountOut = getAmountOut(creatorTokensOut, reserve0, reserve1);

        if(IXeldoradoFactory(IXeldoradoVault(_inVault).factory()).noOFTokensForDiscount() <= IERC20X(IXeldoradoFactory(IXeldoradoVault(_inVault).factory()).exchangeToken()).balanceOf(_swapper))
        {
            amountOut = amountOut.sub(calculateFee(amountOut, IXeldoradoFactory(IXeldoradoVault(_inVault).factory()).swapFee().sub(IXeldoradoFactory(IXeldoradoVault(_inVault).factory()).swapDiscount()).add(IXeldoradoCreatorFactory(IXeldoradoPair(IXeldoradoVault(_inVault).pair()).creatorfactory()).creatorSwapFee(IXeldoradoVault(_inVault).creator()))));
        }
        else{
            amountOut = amountOut.sub(calculateFee(amountOut, IXeldoradoFactory(IXeldoradoVault(_inVault).factory()).swapFee().add(IXeldoradoCreatorFactory(IXeldoradoPair(IXeldoradoVault(_inVault).pair()).creatorfactory()).creatorSwapFee(IXeldoradoVault(_inVault).creator()))));
        }
        
        // Creator Tokens of Out NFT

        if(IXeldoradoFactory(IXeldoradoVault(_outVault).factory()).noOFTokensForDiscount() <= IERC20X(IXeldoradoFactory(IXeldoradoVault(_outVault).factory()).exchangeToken()).balanceOf(_swapper))
        {
            creatorTokensIn = IXeldoradoVault(_outVault).singleNFTPrice().add(calculateFee(IXeldoradoVault(_outVault).singleNFTPrice(), IXeldoradoFactory(IXeldoradoVault(_outVault).factory()).nftFee().sub(IXeldoradoFactory(IXeldoradoVault(_outVault).factory()).nftDiscount()).add(IXeldoradoCreatorFactory(IXeldoradoPair(IXeldoradoVault(_outVault).pair()).creatorfactory()).creatorNFTFee(IXeldoradoVault(_outVault).creator())))); // singleNFTPrice - xfee + cfee
        }
        else
        {
            creatorTokensIn = IXeldoradoVault(_outVault).singleNFTPrice().add(calculateFee(IXeldoradoVault(_outVault).singleNFTPrice(), IXeldoradoFactory(IXeldoradoVault(_outVault).factory()).nftFee().add(IXeldoradoCreatorFactory(IXeldoradoPair(IXeldoradoVault(_outVault).pair()).creatorfactory()).creatorNFTFee(IXeldoradoVault(_outVault).creator())))); // singleNFTPrice - xfee + cfee
        }

        // Get AmountIn of BaseToken to get creatorTokensIn for Out NFT
        (reserve0, reserve1,) = IXeldoradoPair(IXeldoradoVault(_outVault).pair()).getReserves();
        // to get creatorTokenIn worth of outNFT's creatorTokens find amount In in BaseTokens to be provided to the pair
        amountIn = getAmountIn(creatorTokensIn, reserve0, reserve1);
        uint tenth = 10000;
        if(IXeldoradoFactory(IXeldoradoVault(_outVault).factory()).noOFTokensForDiscount() <= IERC20X(IXeldoradoFactory(IXeldoradoVault(_outVault).factory()).exchangeToken()).balanceOf(_swapper))
        {
            amountIn = amountIn.mul(tenth).div(tenth.sub(IXeldoradoFactory(IXeldoradoVault(_outVault).factory()).swapFee()).add(IXeldoradoFactory(IXeldoradoVault(_outVault).factory()).swapDiscount()).sub(IXeldoradoCreatorFactory(IXeldoradoPair(IXeldoradoVault(_outVault).pair()).creatorfactory()).creatorSwapFee(IXeldoradoVault(_outVault).creator())));
        }
        else{
            amountIn = amountIn.mul(tenth).div(tenth.sub(IXeldoradoFactory(IXeldoradoVault(_outVault).factory()).swapFee()).sub(IXeldoradoCreatorFactory(IXeldoradoPair(IXeldoradoVault(_outVault).pair()).creatorfactory()).creatorSwapFee(IXeldoradoVault(_outVault).creator())));
        }

        if (amountIn > amountOut) {
            extraBaseTokensNeeded = amountIn.sub(amountOut);
        }
        else{
            leftOverBaseTokensDeposited = amountOut.sub(amountIn);
        }
        
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'XeldoradoLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'XeldoradoLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = amountIn.mul(reserveOut);
        uint denominator = reserveIn.add(amountIn);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'XeldoradoLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'XeldoradoLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut);
        uint denominator = reserveOut.sub(amountOut);
        amountIn = (numerator / denominator);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'XeldoradoLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'XeldoradoLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}