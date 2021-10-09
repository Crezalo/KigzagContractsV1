// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import './interfaces/IXeldoradoFactory.sol';
import './XeldoradoPair.sol';
import './XeldoradoCreatorFactory.sol';

contract XeldoradoFactory is IXeldoradoFactory {
    address public override feeTo;
    address public override feeToSetter;
    uint public override fee;
    address public override xeldoradoCreatorFactory;
    address private WETH;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;
    
    XeldoradoCreatorFactory private xcf;
    // event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter, address _WETH) {
        feeToSetter = _feeToSetter;
        xcf = new XeldoradoCreatorFactory();
        xeldoradoCreatorFactory = address(xcf);
        WETH = _WETH;
    }

    function allPairsLength() public virtual override view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB, address creator) public virtual override returns (address pairAddress) {
        require(tokenA != tokenB && tokenA != address(0) && tokenB != address(0), 'Xeldorado: address issue');
        require(getPair[tokenA][tokenB] == address(0), 'Xeldorado: PAIR_EXISTS'); // single check is sufficient
        require((tokenA == WETH && tokenB == xcf.creatorToken(creator)) || (tokenB == WETH && tokenA == xcf.creatorToken(creator)), 'Xeldorado: either token not WETH or Creator Token not present');
        
        XeldoradoPair pair = new XeldoradoPair();
        pair.initialize(tokenA, tokenB, creator, address(this), xeldoradoCreatorFactory);
        getPair[tokenA][tokenB] = address(pair);
        getPair[tokenB][tokenA] = address(pair); // populate mapping in the reverse direction
        allPairs.push(address(pair));
        pairAddress = address(pair);
        emit PairCreated(tokenA, tokenB, address(pair), allPairs.length);
    }


    function setFeeTo(address _feeTo) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
    
    function setFee(uint _fee) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        fee = _fee;
        // set to 5 (i.e. 0.5% on the scale of 1000)
    }
}
