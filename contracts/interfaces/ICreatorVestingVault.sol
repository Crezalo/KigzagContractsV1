// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

interface ICreatorVestingVault {
    
    event AmountVested(address creator, address ctoken, uint amount);
    
    function initialCreatorVVBalance() external view returns(uint);
    function currentCreatorVVBalance() external view returns(uint);
    function ctoken() external view returns(address);
    function creator() external view returns(address);
    
    
    function minimumCreatorBalance() external view returns(uint);
    function redeemedVestedTokens(uint amount) external;
    function initialize(address _ctoken, address _creator) external;
}