// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import './interfaces/IERC20X.sol';
import './libraries/Math.sol';
import './libraries/SafeMath.sol';
import './libraries/UQ112x112.sol';
import './libraries/XeldoradoLibrary1.sol';
import './interfaces/IXeldoradoPair.sol';
import './interfaces/IXeldoradoFactory.sol';
import './interfaces/IXeldoradoCreatorFactory.sol';


contract XeldoradoPair is IXeldoradoPair {
    using SafeMath  for uint;
    using UQ112x112 for uint224;

    uint public constant override MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public override admin;
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
    bool private migrationApproved;
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
    
    // event Swap(
    //     address indexed sender,
    //     uint amount0In,
    //     uint amount1In,
    //     uint amount0Out,
    //     uint amount1Out,
    //     address indexed to
    // );
    // event Sync(uint112 reserve0, uint112 reserve1);

    constructor() {
        admin = msg.sender;// xeldorado factory
    }

    // called once by the admin at time of deployment
    function initialize(address _token0, address _token1, address _creator, address _factory, address _creatorfactory) public virtual override {
        require(msg.sender == admin, 'Xeldorado: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
        creator = _creator;
        factory = _factory;
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
        require((tokenIn==token0 && tokenOut==token1) || (tokenIn==token1 && tokenOut==token0), 'Xeldorado: one or both tokens dont match the pair');
        require(amountIn > 0 && amountOut > 0, 'Xeldorado: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
    
        uint balance0;
        uint balance1;
        
        if (tokenIn == token0){
            require(amountOut < _reserve1, 'Xeldorado: INSUFFICIENT_LIQUIDITY');
            if(XeldoradoLibrary1.getAmountOut(amountIn,_reserve0,reserve1) >= amountOut) amountOut = XeldoradoLibrary1.getAmountOut(amountIn,_reserve0,reserve1);
            else require(0>1, 'Xeldorado:cannot swap for mentioned amount out');
            
            require(to != token0 && to != token1, 'Xeldorado: INVALID_TO');
            
            //take approval from to
            require(IERC20X(token0).transferFrom(to, address(this), amountIn),'Xeldorado: amount In transfer failed');
            // charge exchange fee
            if(IXeldoradoFactory(factory).noOFTokensForDiscount() <= IERC20X(IXeldoradoFactory(factory).exchangeToken()).balanceOf(to))
            {
                require(IERC20X(token1).transfer(IXeldoradoFactory(factory).feeTo(), XeldoradoLibrary1.calculateFee(amountOut, IXeldoradoFactory(factory).fee().sub(IXeldoradoFactory(factory).discount()).mul(10))),'Xeldorado: exchange fee transfer failed');
            }
            else{
                require(IERC20X(token1).transfer(IXeldoradoFactory(factory).feeTo(), XeldoradoLibrary1.calculateFee(amountOut, IXeldoradoFactory(factory).fee().mul(10))),'Xeldorado: exchange fee transfer failed');
            }
            // charge creator royalty fee
            require(IERC20X(token1).transfer(creator, XeldoradoLibrary1.calculateFee(amountOut, IXeldoradoCreatorFactory(creatorfactory).creatorFee(creator))),'Xeldorado: creator fee transfer failed');
            //transfer amountOut to to
            require(IERC20X(token1).transfer(to,amountOut.sub(XeldoradoLibrary1.calculateFee(amountOut, IXeldoradoFactory(factory).fee().mul(10))).sub(XeldoradoLibrary1.calculateFee(amountOut, IXeldoradoCreatorFactory(creatorfactory).creatorFee(creator)))), 'Xeldorado: amount Out transfer failed');
            
            balance0 = IERC20X(token0).balanceOf(address(this));
            balance1 = IERC20X(token1).balanceOf(address(this));
        
            // require(balance0.mul(1000).sub(amountIn.mul(3)).mul(balance1.mul(1000)) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'Xeldorado: K');
        }
        else {
            require(amountOut < _reserve0, 'Xeldorado: INSUFFICIENT_LIQUIDITY');
            uint amountIn_up = amountIn.sub(XeldoradoLibrary1.calculateFee(amountIn, IXeldoradoFactory(factory).fee().mul(10))).sub(IXeldoradoCreatorFactory(creatorfactory).creatorFee(creator)); // after fee deductions
            if(XeldoradoLibrary1.getAmountOut(amountIn_up,_reserve1,reserve0) >= amountOut) amountOut = XeldoradoLibrary1.getAmountOut(amountIn_up,_reserve1,reserve0);
            else require(0>1, 'Xeldorado:cannot swap for mentioned amount out');
            
            require(to != token0 && to != token1, 'Xeldorado: INVALID_TO');
        
            //take approval from to
            require(IERC20X(token1).transferFrom(to, address(this),amountIn),'Xeldorado: amount In transfer failed');
            
            // charge exchange fee
            if(IXeldoradoFactory(factory).noOFTokensForDiscount() <= IERC20X(IXeldoradoFactory(factory).exchangeToken()).balanceOf(to))
            {
                require(IERC20X(token1).transfer(IXeldoradoFactory(factory).feeTo(), XeldoradoLibrary1.calculateFee(amountIn, IXeldoradoFactory(factory).fee().sub(IXeldoradoFactory(factory).discount()).mul(10))),'Xeldorado: exchange fee transfer failed');
            }
            else{
                require(IERC20X(token1).transfer(IXeldoradoFactory(factory).feeTo(), XeldoradoLibrary1.calculateFee(amountIn, IXeldoradoFactory(factory).fee().mul(10))),'Xeldorado: exchange fee transfer failed');
            }
            // charge creator royalty fee
            require(IERC20X(token1).transfer(creator, XeldoradoLibrary1.calculateFee(amountIn, IXeldoradoCreatorFactory(creatorfactory).creatorFee(creator))),'Xeldorado: creator fee transfer failed');
            
            //transfer amountOut to to
            require(IERC20X(token0).transfer(to,amountOut), 'Xeldorado: amount Out transfer failed');
            
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
    
    // Use web3 and interface for below functions
    function migrateLiquidityToV2_createRequest() public virtual override {
        require(msg.sender == creator, 'Xeldorado: Only creator');
        migrationApproved = true;
        emit migrationPairRequestCreated();
    }
    
    function migrationApprove(address toContract) public virtual override lock {
        require((msg.sender == IXeldoradoFactory(factory).migrationApprover() && migrationApproved), 'Xeldorado: only migration contract');
        IERC20X(token0).transfer(toContract, IERC20X(token0).balanceOf(address(this)));
        IERC20X(token1).transfer(toContract, IERC20X(token1).balanceOf(address(this)));
        emit migrationPairRequestApproved(toContract);
    }
}
