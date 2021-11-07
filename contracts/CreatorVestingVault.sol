// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import './interfaces/IERC20X.sol';
import './interfaces/ICreatorVestingVault.sol';
import './libraries/SafeMath.sol';

contract CreatorVestingVault is ICreatorVestingVault {
    using SafeMath  for uint;
    
    uint public override initialCreatorVVBalance;
    uint public override currentCreatorVVBalance;
    uint private startTimeStamp;
    address public override ctoken;
    address public override creator;
    uint private isInitialised;
    uint private duration;
    
    uint private unlocked;
    
    modifier lock() {
        require(unlocked == 1, 'Xeldorado: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }
    
    constructor() {
        isInitialised = 0;
        unlocked = 1;
    }
    
    function initialize(address _ctoken, address _creator, uint _duration) public override lock {
        require(isInitialised==0,'Xeldorado: already isInitialised');
        isInitialised = 1;
        startTimeStamp = block.timestamp;
        ctoken = _ctoken;
        creator = _creator;
        duration = _duration;
        initialCreatorVVBalance = IERC20X(ctoken).balanceOf(address(this));
        currentCreatorVVBalance = initialCreatorVVBalance;
    }
    
    function currentBalanceUpdate() public override lock {
        currentCreatorVVBalance = IERC20X(ctoken).balanceOf(address(this));
    }
    
    
    function minimumCreatorBalance() public view override returns(uint){
        if((block.timestamp.sub(startTimeStamp)).div(duration) > 1) return 0;
        return initialCreatorVVBalance.sub(initialCreatorVVBalance.mul(block.timestamp.sub(startTimeStamp)).div(duration));
    }
    
    // in proportion to time spent since start  amount from vesting vault can be redeemed by the creator
    function redeemedVestedTokens(uint amount) public override lock {
        require(amount<= currentCreatorVVBalance.sub(minimumCreatorBalance()),'Xeldorado: vesting limit reached');
        currentCreatorVVBalance = currentCreatorVVBalance.sub(amount);
        IERC20X(ctoken).transfer(creator,amount);
        emit AmountVested(creator, ctoken, amount);
    }
}