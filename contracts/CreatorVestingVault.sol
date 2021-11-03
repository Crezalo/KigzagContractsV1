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
    
    function initialize(address _ctoken, address _creator) public override lock {
        require(isInitialised==0,'Xeldorado: already isInitialised');
        isInitialised = 1;
        startTimeStamp = block.timestamp;
        ctoken = _ctoken;
        creator = _creator;
        initialCreatorVVBalance = IERC20X(ctoken).balanceOf(address(this));
        currentCreatorVVBalance = initialCreatorVVBalance;
    }
    
    // 2% of the starting total supply = 1111888 * 10^18 * 0.02
    // sub 2% of total amount times number of months passed bsically 22237.76 tokens can be sold by creator in one month
    function minimumCreatorBalance() public view override returns(uint){
        return initialCreatorVVBalance.sub((block.timestamp.sub(startTimeStamp)).mul(2223776 * 10 ** 16) / (24 * 60 * 60 * 30 ));
    }
    
    function redeemedVestedTokens(uint amount) public override lock {
        require(amount<= currentCreatorVVBalance.sub(minimumCreatorBalance()),'Xeldorado: cannot redeem more than 2% a month');
        currentCreatorVVBalance = currentCreatorVVBalance - amount;
        IERC20X(ctoken).transfer(creator,amount);
        emit AmountVested(creator, ctoken, amount);
    }
}