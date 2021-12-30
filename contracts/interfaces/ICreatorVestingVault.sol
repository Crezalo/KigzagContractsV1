// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

interface ICreatorVestingVault {
    
    event AmountVested(address creator, address ctoken, uint amount);
    
    function initialCreatorVVBalance() external view returns(uint);
    function currentCreatorVVBalance() external view returns(uint);
    function redeemedCreatorBalance() external view returns(uint);
    // function FLOVVBalance() external view returns(uint);
    function ctoken() external view returns(address);
    function creator() external view returns(address);
    
    function currentBalanceUpdate() external;
    function minimumCreatorBalance() external view returns(uint);
    function redeemedVestedTokens(uint amount) external;

    // only vault can call
    // function addFLOBalanceToVault(uint amount) external; 
    function initialize(address _ctoken, address _creator, uint _duration) external;
    // function updateVaultAddress(address _newVaut) external;
}