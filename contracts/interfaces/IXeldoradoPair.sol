// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

interface IXeldoradoPair {
    event Swap(address indexed sender, uint amountIn, address tokenIn, uint amountOut, address tokenOut, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);
    // event migrationPairRequestCreated();
    event migrationPairCompleted(address toContract);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    // function kLast() external view returns (uint);
    function creator() external view returns (address);
    function factory() external view returns (address);
    
    function creatorfactory() external view returns (address);
    function LiquidityAdded() external;
    
    function swap(address tokenIn, uint amountIn, address tokenOut, uint amountOut, address to) external;
    // function skim(address to) external;
    function sync() external;

    // only migration contract can call
    function migratePair(address toContract) external;
}
