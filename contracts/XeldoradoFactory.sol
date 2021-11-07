// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import './interfaces/IXeldoradoFactory.sol';
import './XeldoradoPair.sol';
import './XeldoradoCreatorFactory.sol';

contract XeldoradoFactory is IXeldoradoFactory {
    address public override feeTo;
    address public override feeToSetter;
    uint public override fee;
    uint public override discount;
    uint public override VestingDuration;
    uint public override noOFTokensForDiscount;
    address public override exchangeToken;
    address public override migrationApprover;
    address public override xeldoradoCreatorFactory;
    address[] private BaseTokens;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;
    
    XeldoradoCreatorFactory private xcf;
    // event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter, address[] memory _BaseTokens) {
        feeToSetter = _feeToSetter;
        xcf = new XeldoradoCreatorFactory();
        xeldoradoCreatorFactory = address(xcf);
        BaseTokens = _BaseTokens;
    }

    function addNewBaseToken(address btoken) public virtual override {
        BaseTokens.push(btoken);
    }

    function allPairsLength() public virtual override view returns (uint) {
        return allPairs.length;
    }
    
    function _checkTokenExistsInBaseTokens(address btoken) internal view returns(bool){
        for(uint i=0;i<BaseTokens.length;i++){
            if(BaseTokens[i]==btoken){
                return true;
            }
        }
        return false;
    }

    function createPair(address tokenA, address tokenB, address creator) public virtual override returns (address pairAddress) {
        require(tokenA != tokenB && tokenA != address(0) && tokenB != address(0), 'Xeldorado: address issue');
        require(getPair[tokenA][tokenB] == address(0), 'Xeldorado: PAIR_EXISTS'); // single check is sufficient
        require(tokenA == xcf.creatorToken(creator) && _checkTokenExistsInBaseTokens(tokenB) , 'Xeldorado: either token not WETH or Creator Token not present');
        
        XeldoradoPair pair = new XeldoradoPair();
        pair.initialize(tokenA, tokenB, creator, address(this), xeldoradoCreatorFactory);
        getPair[tokenA][tokenB] = address(pair);
        getPair[tokenB][tokenA] = address(pair); // populate mapping in the reverse direction
        allPairs.push(address(pair));
        pairAddress = address(pair);
        emit PairCreated(tokenA, tokenB, address(pair), allPairs.length);
    }

    //// Admin functions // Use web3 and interface for below functions
    function setFeeTo(address _feeTo) public {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) public {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
    
    function setFee(uint _fee) public {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        fee = _fee;
        // set to 5 (i.e. 0.5% on the scale of 1000)
    }
    
    function setDiscount(uint _discount) public {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        discount = _discount;
        // set to 2 (i.e. 0.2% on the scale of 1000) so actual fee = 0.5%-0.2%
    }
    
    function setNoOFTokensForDiscount(uint _noOFTokensForDiscount) public {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        noOFTokensForDiscount = _noOFTokensForDiscount;
    }
    
    function setExchangeToken(address _exchangeToken) public {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        exchangeToken = _exchangeToken;
    }
    
    function setVestingDuration(uint _duration) public {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        VestingDuration = _duration;
    }
    
    function migrationApproval(address _migrationApprover) public {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        migrationApprover = _migrationApprover;
    }
}
