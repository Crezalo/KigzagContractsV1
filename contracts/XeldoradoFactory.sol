// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import './interfaces/IXeldoradoFactory.sol';
import './XeldoradoPair.sol';
import './XeldoradoCreatorFactory.sol';

contract XeldoradoFactory is IXeldoradoFactory {
    address public override feeTo;
    address public override feeToSetter;
    address public override routerContract;
    uint public override swapFee;
    uint public override ictoFee;
    uint public override redeemNftFee;
    uint public override returnNftFee;
    uint public override maxCreatorFee;
    uint public override discount;
    uint public override VestingDuration;
    uint public override vestingCliffInt;
    uint public override noOFTokensForDiscount;
    address public override exchangeToken;
    uint public override totalCreatorTokenSupply;
    uint public override percentCreatorOwnership; // on scale of 1000 so 24% is 240
    address public override migrationContract;
    uint public override migrationDuration; // duration of voting for migration contract
    uint public override migrationVoterThreshold;
    uint public override migrationVoterTokenThreshold;
    address public override xeldoradoCreatorFactory;
    address[] private BaseTokens;
    mapping(address=>bool) public override haltPairTrading; // to be used only in case of emergency situation like a security loop hole being misused
    bool public override haltAllPairsTrading; // to be used only in case of emergency situation like a security loop hole being misused

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

    function allPairsLength() public virtual override view returns (uint) {
        return allPairs.length;
    }
    
    function checkTokenExistsInBaseTokens(address btoken) public virtual override view returns(bool){
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
        require(tokenA == xcf.creatorToken(creator) && checkTokenExistsInBaseTokens(tokenB) , 'Xeldorado: Token not in order or Creator Token not present or base token not present');
        
        XeldoradoPair pair = new XeldoradoPair(tokenA, tokenB, creator, address(this), xeldoradoCreatorFactory);
        getPair[tokenA][tokenB] = address(pair);
        getPair[tokenB][tokenA] = address(pair); // populate mapping in the reverse direction
        allPairs.push(address(pair));
        pairAddress = address(pair);
        emit PairCreated(tokenA, tokenB, address(pair), allPairs.length);
    }

    //// Admin functions // Use web3 and interface for below functions
    function addNewBaseToken(address btoken) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        BaseTokens.push(btoken);
    }

    function setRouterContract(address _routerContract) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        routerContract = _routerContract;
    }

    function setFeeTo(address _feeTo) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
    
    function setSwapFee(uint _fee) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        swapFee = _fee;
        // set to 5 (i.e. 0.5% on the scale of 1000)
    }
    
    function setICTOFee(uint _fee) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        ictoFee = _fee;
        // set to 5 (i.e. 0.5% on the scale of 1000)
    }
    
    function setRedeemNftFee(uint _fee) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        redeemNftFee = _fee;
        // set to 5 (i.e. 0.5% on the scale of 1000)
    }
    
    function setReturnNftFee(uint _fee) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        returnNftFee = _fee;
        // set to 5 (i.e. 0.5% on the scale of 1000)
    }

    function setMaxCreatorFee(uint _fee) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        maxCreatorFee = _fee;
        // set to 10 (i.e. 0.1% on the scale of 10000)
    }
    
    function setDiscount(uint _discount) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        discount = _discount;
        // set to 2 (i.e. 0.2% on the scale of 1000) so actual fee = 0.5%-0.2%
    }
    
    function setNoOFTokensForDiscount(uint _noOFTokensForDiscount) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        noOFTokensForDiscount = _noOFTokensForDiscount;
    }
    
    function setExchangeToken(address _exchangeToken) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        exchangeToken = _exchangeToken;
    }
    
    function setVestingDuration(uint _duration) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        VestingDuration = _duration;
    }
    
    function setVestingCliffInt(uint _vestingCliffInt) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        vestingCliffInt = _vestingCliffInt; // set to 8 for a cliff of 3 months over 2 years vesting duration
    }
    
    function setTotalCreatorTokenSupply(uint _totalCreatorTokenSupply) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        totalCreatorTokenSupply = _totalCreatorTokenSupply;  // starting total supply for a creator's creator token // set 1111888 by default
    }
    
    function setPercentCreatorOwnership(uint _percentCreatorOwnership) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        percentCreatorOwnership = _percentCreatorOwnership;  // on scale of 1000 so 24% is 240
    }

    function setMigrationVoterThreshold(uint _migrationVoterThreshold) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN'); 
        migrationVoterThreshold = _migrationVoterThreshold; // set % of unique voters of total distinct voters needed to approve migration contract 
    }
    
    function setMigrationVoterTokenThreshold(uint _migrationVoterTokenThreshold) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        migrationVoterTokenThreshold = _migrationVoterTokenThreshold; // set % of tokens (hold by voters) of total supply needed to approve migration contract 
    }
    
    function setHaltPairTrading(address _pair, bool value) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        haltPairTrading[_pair] = value; // set true to halt a specific trading in case of emergency security needs
    }
    
    function setHaltAllPairsTrading(bool _haltAllPairsTrading) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        haltAllPairsTrading = _haltAllPairsTrading; // set true to halt all trading in case of emergency security needs
    }
    
    function setMigrationContract(address _migrationContract) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        migrationContract = _migrationContract; //migration contract
    }

    function setMigrationDuration(uint _migrationDuration) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        migrationDuration = _migrationDuration; //migration duration
    }
}
