// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;


interface IXeldoradoFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function fee() external view returns(uint);
    function xeldoradoCreatorFactory() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB, address creator) external returns (address pairAddress);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setFee(uint _fee) external;
}
