// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;


interface IXeldoradoFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function routerContract() external view returns (address);
    function swapFee() external view returns(uint);
    function ictoFee() external view returns(uint);
    function redeemNftFee() external view returns(uint);
    function returnNftFee() external view returns(uint);
    function maxCreatorFee() external view returns(uint);
    function discount() external view returns(uint);
    function VestingDuration() external view returns(uint);
    function vestingCliffInt() external view returns(uint);
    function noOFTokensForDiscount() external view returns(uint);
    function exchangeToken() external view returns(address);
    function totalCreatorTokenSupply() external view returns(uint);
    function percentCreatorOwnership() external view returns(uint);
    function migrationContract() external view returns(address);
    function migrationDuration() external view returns(uint);
    function migrationVoterThreshold() external view returns(uint);
    function migrationVoterTokenThreshold() external view returns(uint);
    function haltPairTrading(address pair) external view returns(bool);
    function haltAllPairsTrading() external view returns (bool);
    function xeldoradoCreatorFactory() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function checkTokenExistsInBaseTokens(address btoken) external view returns (bool);

    function createPair(address tokenA, address tokenB, address creator) external returns (address pairAddress);

    // although via interface but need particular msg.senders
    function addNewBaseToken(address btoken) external;
    function setRouterContract(address _routerContract) external;
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setSwapFee(uint _fee) external;
    function setICTOFee(uint _fee) external;
    function setRedeemNftFee(uint _fee) external;
    function setReturnNftFee(uint _fee) external;
    function setMaxCreatorFee(uint _fee) external;
    function setDiscount(uint _discount) external;
    function setNoOFTokensForDiscount(uint _noOFTokensForDiscount) external;
    function setExchangeToken(address _exchangeToken) external;
    function setVestingDuration(uint _duration) external;
    function setVestingCliffInt(uint _vestingCliffInt) external;
    function setTotalCreatorTokenSupply(uint _totalCreatorTokenSupply) external;
    function setPercentCreatorOwnership(uint _percentCreatorOwnership) external;
    function setMigrationVoterThreshold(uint _migrationVoterThreshold) external;
    function setMigrationVoterTokenThreshold(uint _migrationVoterTokenThreshold) external;
    function setHaltPairTrading(address _pair, bool value) external;
    function setHaltAllPairsTrading(bool _haltAllPairsTrading) external;
    function setMigrationContract(address _migrationContract) external;
    function setMigrationDuration(uint _migrationDuration) external;
}
