// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import '../interfaces/IERC20X.sol';

import "./SafeMath.sol";

// import './CreatorToken.sol';
import '../XeldoradoVault.sol';
import '../CreatorVestingVault.sol';

library XeldoradoLibrary1 {
    using SafeMath for uint;
    
    function singleNFTPrice(address token, uint allNFTs, uint redeemedNFTsLength) internal view returns(uint){
        return (IERC20X(token).totalSupply() / (allNFTs.sub(redeemedNFTsLength)));
    }
    
    function _exist(uint[] memory _array, uint _vaultId) internal pure returns (bool){
      for (uint i; i < _array.length;i++){
          if (_array[i]==_vaultId) return true;
      }
      return false;
    }
    
    function calculateFee(uint amount, uint fee) internal pure returns (uint) {
        // fee percent in scale of 10000
        return amount.mul(fee)/10000;
    }
    
    // update 
    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'XeldoradoLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'XeldoradoLibrary: INSUFFICIENT_LIQUIDITY');
        // uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountIn.mul(reserveOut);
        uint denominator = reserveIn.add(amountIn);
        amountOut = numerator / denominator;
    }
    
}