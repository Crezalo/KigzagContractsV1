// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import './interfaces/IERC20X.sol';
import './interfaces/ICreatorVestingVault.sol';
import './interfaces/IXeldoradoFactory.sol';
import './libraries/SafeMath.sol';

contract CreatorVestingVault is ICreatorVestingVault {
    using SafeMath  for uint;
    
    uint public override initialCreatorVVBalance;
    uint public override currentCreatorVVBalance;
    uint public override FLOVVBalance;
    uint public override redeemedCreatorBalance;
    uint private startTimeStamp;
    address public override ctoken;
    address public override creator;
    uint private isInitialised;
    uint private duration;
    
    uint private unlocked;

    address factory;
    address vault;
    
    modifier lock() {
        require(unlocked == 1, 'Xeldorado: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }
    
    constructor(address _factory, address _vault) {
        isInitialised = 0;
        unlocked = 1;
        factory = _factory;
        vault = _vault;
    }
    
    function initialize(address _ctoken, address _creator, uint _duration) public override lock {
        require(isInitialised==0,'Xeldorado: already isInitialised');
        require(msg.sender==vault,'Xeldorado: only vault allowed');
        isInitialised = 1;
        startTimeStamp = block.timestamp;
        ctoken = _ctoken;
        creator = _creator;
        duration = _duration;
        initialCreatorVVBalance = IERC20X(ctoken).balanceOf(address(this));
        currentCreatorVVBalance = initialCreatorVVBalance;
        redeemedCreatorBalance = 0;
        FLOVVBalance = 0;
    }
    
    function currentBalanceUpdate() public override lock {
        // uint totalBalance = IERC20X(ctoken).balanceOf(address(this));
        currentCreatorVVBalance = initialCreatorVVBalance.sub(redeemedCreatorBalance);
        FLOVVBalance = IERC20X(ctoken).balanceOf(address(this)).sub(currentCreatorVVBalance);
    }
    
    
    function minimumCreatorBalance() public view override returns(uint){
        if((block.timestamp.sub(startTimeStamp)).div(duration) > 1) return 0;
        return initialCreatorVVBalance.sub(initialCreatorVVBalance.mul(block.timestamp.sub(startTimeStamp)).div(duration));
    }
    
    // in proportion to time passed since start of ICTO, amount from vesting vault can be redeemed by the creator
    function redeemedVestedTokens(uint amount) public override lock {
        require((block.timestamp.sub(startTimeStamp)).mul(IXeldoradoFactory(factory).vestingCliffInt()).div(duration) > 1 , 'Xeldorado: cliff hanger period');
        require(amount<= currentCreatorVVBalance.sub(minimumCreatorBalance()),'Xeldorado: vesting limit reached');
        redeemedCreatorBalance += amount;
        IERC20X(ctoken).transfer(creator,amount);
        currentBalanceUpdate();
        emit AmountVested(creator, ctoken, amount);
    }

    function addFLOBalanceToVault(uint amount) public override lock {
        require(msg.sender==vault,'Xeldorado: only vault allowed');
        require(amount<=FLOVVBalance,'Xeldorado: not adequate FLO balance');
        IERC20X(ctoken).transfer(vault,amount);
        currentBalanceUpdate();
        emit FLOAmountAdded(creator, ctoken, amount);
    }
}