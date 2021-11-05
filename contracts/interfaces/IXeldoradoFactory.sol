// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;


interface IXeldoradoFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function fee() external view returns(uint);
    function discount() external view returns(uint);
    function VestingDuration() external view returns(uint);
    function noOFTokensForDiscount() external view returns(uint);
    function exchangeToken() external view returns(address);
    function migrationApprover() external view returns(address);
    function xeldoradoCreatorFactory() external view returns (address);

    function addNewBaseToken(address btoken) external;
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB, address creator) external returns (address pairAddress);

    // function setFeeTo(address) external;
    // function setFeeToSetter(address) external;
    // function setFee(uint _fee) external;
    // function setDiscount(uint _discount) external;
    // function setNoOFTokensForDiscount(uint _noOFTokensForDiscount) external;
    // function setExchangeToken(address _exchangeToken) external;
    // function migrationApproval() external;
}
