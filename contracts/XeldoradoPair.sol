// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import './interfaces/IERC20X.sol';
import './libraries/Math.sol';
import './libraries/SafeMath.sol';
import './libraries/UQ112x112.sol';
import './libraries/XeldoradoLibrary.sol';
import './interfaces/IXeldoradoPair.sol';
import './interfaces/ICreatorToken.sol';
import './interfaces/IXeldoradoFactory.sol';
import './interfaces/IXeldoradoCreatorFactory.sol';


contract XeldoradoPair is IXeldoradoPair {
    using SafeMath  for uint;
    using UQ112x112 for uint224;

    uint public constant override MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public override token0; // Creator Token
    address public override token1; // Base Tokens

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public override price0CumulativeLast;
    uint public override price1CumulativeLast;
    // uint public override kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event
    
    address public override creator;
    address public override factory;
    address public override creatorfactory;
    
    uint private startTimeStamp;
    uint private unlocked;
    
    modifier lock() {
        require(unlocked == 1, 'Xeldorado: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves() public view virtual override returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Xeldorado: TRANSFER_FAILED');
    }

    constructor(address _token0, address _token1, address _creator, address _creatorfactory) {
        factory = msg.sender;
        token0 = _token0;
        token1 = _token1;
        creator = _creator;
        creatorfactory = _creatorfactory;
        unlocked = 1;
        startTimeStamp = block.timestamp;
    }
    
    function LiquidityAdded() public virtual override {
        reserve0 = uint112(IERC20X(token0).balanceOf(address(this)));
        reserve1 = uint112(IERC20X(token1).balanceOf(address(this)));
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= (2**112 - 1) && balance1 <= (2**112 - 1), 'Xeldorado: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }
    
    // this low-level function should be called from a contract which performs important safety checks
    function swap(address tokenIn, uint amountIn, address tokenOut, uint amountOut, address to) public virtual override lock {
        require(IXeldoradoFactory(factory).haltAllPairsTrading() != true ,'Xeldorado: trading is halted for all pairs');
        require((tokenIn==token0 && tokenOut==token1) || (tokenIn==token1 && tokenOut==token0), 'Xeldorado: one or both tokens dont match the pair');
        require(amountIn > 0 && amountOut > 0, 'Xeldorado: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
    
        uint balance0;
        uint balance1;
        uint discount=0;

        if(IXeldoradoFactory(factory).noOFTokensForDiscount() <= IERC20X(IXeldoradoFactory(factory).exchangeToken()).balanceOf(to))
        {
            discount = IXeldoradoFactory(factory).swapDiscount();
        }
        
        if (tokenIn == token0){
            require(amountOut < _reserve1, 'Xeldorado: INSUFFICIENT_LIQUIDITY');
            if(XeldoradoLibrary.getAmountOut(amountIn,_reserve0,_reserve1) >= amountOut) amountOut = XeldoradoLibrary.getAmountOut(amountIn,_reserve0,_reserve1);
            else require(0>1, 'Xeldorado:cannot swap for mentioned amount out');
            
            require(to != token0 && to != token1, 'Xeldorado: INVALID_TO');
            
            //take approval from to
            require(IERC20X(token0).transferFrom(to, address(this), amountIn),'Xeldorado: amount In transfer failed');
            
            //transfer amountOut to to = amountOut - (amountOut x (swapFee - swapDiscount + creatorSwapFee ))
            require(IERC20X(token1).transfer(to, amountOut.sub(XeldoradoLibrary.calculateFee(amountOut, IXeldoradoFactory(factory).swapFee().sub(discount).add(IXeldoradoCreatorFactory(creatorfactory).creatorSwapFee(creator))))), 'Xeldorado: amount Out transfer failed');
            
            // charge exchange fee
            require(IERC20X(token1).transfer(IXeldoradoFactory(factory).feeTo(), XeldoradoLibrary.calculateFee(amountOut, IXeldoradoFactory(factory).swapFee().sub(discount))),'Xeldorado: exchange fee transfer failed');
            
            // charge creator royalty fee
            require(IERC20X(token1).transfer(creator, XeldoradoLibrary.calculateFee(amountOut, IXeldoradoCreatorFactory(creatorfactory).creatorSwapFee(creator))),'Xeldorado: creator fee transfer failed');
            
            balance0 = IERC20X(token0).balanceOf(address(this));
            balance1 = IERC20X(token1).balanceOf(address(this));
        
            // require(balance0.mul(1000).sub(amountIn.mul(3)).mul(balance1.mul(1000)) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'Xeldorado: K');
        }
        else {
            require(amountOut < _reserve0, 'Xeldorado: INSUFFICIENT_LIQUIDITY');
            uint amountIn_up;
            
            amountIn_up = amountIn.sub(XeldoradoLibrary.calculateFee(amountIn, IXeldoradoFactory(factory).swapFee().sub(discount).add(IXeldoradoCreatorFactory(creatorfactory).creatorSwapFee(creator)))); // after fee deductions
            
            if(XeldoradoLibrary.getAmountOut(amountIn_up,_reserve1,_reserve0) >= amountOut) amountOut = XeldoradoLibrary.getAmountOut(amountIn_up,_reserve1,_reserve0);
            else require(0>1, 'Xeldorado: cannot swap for mentioned amount out');
            
            require(to != token0 && to != token1, 'Xeldorado: INVALID_TO');
        
            //take approval from to
            require(IERC20X(token1).transferFrom(to, address(this),amountIn),'Xeldorado: amount In transfer failed');

            //transfer amountOut to to
            require(IERC20X(token0).transfer(to,amountOut), 'Xeldorado: amount Out transfer failed');
            
            // charge exchange fee
            require(IERC20X(token1).transfer(IXeldoradoFactory(factory).feeTo(), XeldoradoLibrary.calculateFee(amountIn, IXeldoradoFactory(factory).swapFee().sub(discount))),'Xeldorado: exchange fee transfer failed');
            
            // charge creator royalty fee
            require(IERC20X(token1).transfer(creator, XeldoradoLibrary.calculateFee(amountIn, IXeldoradoCreatorFactory(creatorfactory).creatorSwapFee(creator))),'Xeldorado: creator fee transfer failed');
            
            
            balance0 = IERC20X(token0).balanceOf(address(this));
            balance1 = IERC20X(token1).balanceOf(address(this));
            
            // require(balance0.mul(1000).mul(balance1.mul(1000).sub(amountIn.mul(3))) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'Xeldorado: K');
        }
        
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amountIn, tokenIn, amountOut, tokenOut, to);
    }

    // force balances to match reserves
    // function skim(address to) public virtual override lock {
    //     address _token0 = token0; // gas savings
    //     address _token1 = token1; // gas savings
    //     _safeTransfer(_token0, to, IERC20X(_token0).balanceOf(address(this)).sub(reserve0));
    //     _safeTransfer(_token1, to, IERC20X(_token1).balanceOf(address(this)).sub(reserve1));
    // }

    // force reserves to match balances
    function sync() public virtual override lock {
        _update(IERC20X(token0).balanceOf(address(this)), IERC20X(token1).balanceOf(address(this)), reserve0, reserve1);
    }
    
    // only migration contract can call
    function migratePair(address toContract) public virtual override lock {
        bool votingPassed = ICreatorToken(token0).migrationContractPassed();
        uint votingPhase = ICreatorToken(token0).votingPhase();
        require((msg.sender == IXeldoradoFactory(factory).migrationContract() && votingPassed && votingPhase == 0 && (ICreatorToken(token0).migrationContract() == IXeldoradoFactory(factory).migrationContract())), 'Xeldorado: only migrator allowed after creator approves migration and voting success and migration contract match with voted one');
        IERC20X(token0).transfer(toContract, IERC20X(token0).balanceOf(address(this)));
        IERC20X(token1).transfer(toContract, IERC20X(token1).balanceOf(address(this)));
        LiquidityAdded();

        // update pair address for all dependent contract 
        IXeldoradoFactory(factory).updatePair(token0, token1, toContract);
        IXeldoradoVault(IXeldoradoCreatorFactory(creatorfactory).creatorVault(creator)).updatePair(toContract);
        emit migrationPairCompleted(toContract);
    }
}
