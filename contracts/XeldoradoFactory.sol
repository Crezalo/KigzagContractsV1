// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import './interfaces/IXeldoradoFactory.sol';
import './interfaces/ICreatorToken.sol';
import './XeldoradoPair.sol';
import './XeldoradoCreatorFactory.sol';

contract XeldoradoFactory is IXeldoradoFactory {
    address public override feeTo;
    address public override feeToSetter;
    uint public override swapFee;
    uint public override ictoFee;
    uint public override nftFee;
    uint public override maxCreatorFee;
    uint public override swapDiscount; 
    uint public override ictoDiscount;
    uint public override nftDiscount;
    uint public override VestingDuration; // in seconds
    uint public override vestingCliffInt;
    uint public override noOFTokensForDiscount;
    address public override exchangeToken;
    uint public override totalCreatorTokenSupply;
    uint public override percentCreatorOwnership; // on scale of 1000 so 24% is 240
    uint public override percentDAOOwnership; // on scale of 1000 so 6% is 60
    // address public override directNFTTransferApproverContract;
    address public override migrationContract;
    uint public override migrationDuration; // duration of voting for migration contract // in seconds
    address public override xeldoradoCreatorFactory;
    address[] private BaseTokens;
    // mapping(address=>bool) public override haltPairTrading; // to be used only in case of emergency situation like a security loop hole being misused
    bool public override haltAllPairsTrading; // to be used only in case of emergency situation like a security loop hole being misused

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;
    
    XeldoradoCreatorFactory private xcf;
    // event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    // except createPair all other functions are for admin use only
    // feeToSetter address will be handling all admin functions 
    // as we progress and become a XeldoradoDAO we will place a contract as feeToSetter, any modification will happen via DAO contract
    constructor(address _feeToSetter, address[] memory _BaseTokens, address _exchangeToken) {
        feeToSetter = _feeToSetter;
        xcf = new XeldoradoCreatorFactory();
        xeldoradoCreatorFactory = address(xcf);
        BaseTokens = _BaseTokens;
        feeTo = _feeToSetter;
        swapFee = 60;
        ictoFee = 50;
        nftFee = 40;
        maxCreatorFee = 10;
        swapDiscount = 10; //Important: Rule never set discount greater than any of the fees
        ictoDiscount = 20; //Important: Rule never set discount greater than any of the fees
        nftDiscount = 30; //Important: Rule never set discount greater than any of the fees
        VestingDuration = 3600; // in seconds
        vestingCliffInt = 8;
        noOFTokensForDiscount = 50 * 10**18;
        exchangeToken = _exchangeToken;
        totalCreatorTokenSupply = 10**24;
        percentCreatorOwnership = 240; // scale of 1000
        percentDAOOwnership = 60; // scale of 1000
    }

    function allPairsLength() public virtual override view returns (uint) {
        return allPairs.length;
    }
    
    function checkTokenExistsInBaseTokens(address btoken) public virtual override view returns(bool){
        for(uint i;i<BaseTokens.length;i++){
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
        
        XeldoradoPair pair = new XeldoradoPair(tokenA, tokenB, creator, xeldoradoCreatorFactory);
        getPair[tokenA][tokenB] = address(pair);
        getPair[tokenB][tokenA] = address(pair); // populate mapping in the reverse direction
        allPairs.push(address(pair));
        pairAddress = address(pair);
        emit PairCreated(tokenA, tokenB, address(pair), allPairs.length);
    }

    //// Admin functions // Use web3 and interface for below functions
    // only FeeToSetter can call
    function addNewBaseToken(address btoken) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        BaseTokens.push(btoken);
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
        // set to 50 (i.e. 0.5% on the scale of 10000)
    }
    
    function setICTOFee(uint _fee) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        ictoFee = _fee;
        // set to 50 (i.e. 0.5% on the scale of 10000)
    }
    
    function setNFTFee(uint _fee) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        nftFee = _fee;
        // set to 50 (i.e. 0.5% on the scale of 10000)
    }

    function setMaxCreatorFee(uint _fee) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        maxCreatorFee = _fee;
        // set to 10 (i.e. 0.1% on the scale of 10000)
    }
    
    function setSwapDiscount(uint _discount) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        swapDiscount = _discount; 
        //Important:  Rule never set discount greater than swap fees
        // set to 20 (i.e. 0.2% on the scale of 10000) so actual fee = 0.5%-0.2%
        // discount is applied for exchange token holders with certain number of tokens in their address
    }
    
    function setICTODiscount(uint _discount) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        ictoDiscount = _discount; 
        //Important:  Rule never set discount greater than icto fees
        // set to 20 (i.e. 0.2% on the scale of 10000) so actual fee = 0.5%-0.2%
        // discount is applied for exchange token holders with certain number of tokens in their address
    }
    
    function setNFTDiscount(uint _discount) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        nftDiscount = _discount; 
        //Important:  Rule never set discount greater than nft fees
        // set to 20 (i.e. 0.2% on the scale of 10000) so actual fee = 0.5%-0.2%
        // discount is applied for exchange token holders with certain number of tokens in their address
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
        VestingDuration = _duration; // set in seconds
    }
    
    function setVestingCliffInt(uint _vestingCliffInt) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        vestingCliffInt = _vestingCliffInt; // set to 8 for a cliff of 3 months over 2 years vesting duration
    }
    
    function setTotalCreatorTokenSupply(uint _totalCreatorTokenSupply) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        totalCreatorTokenSupply = _totalCreatorTokenSupply;  // starting total supply for a creator's creator token // set 1000000 by default
    }
    
    function setPercentCreatorOwnership(uint _percentCreatorOwnership) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        percentCreatorOwnership = _percentCreatorOwnership;  // on scale of 1000 so 24% is 240
    }
    
    function setPercentDAOOwnership(uint _percentDAOOwnership) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        percentDAOOwnership = _percentDAOOwnership;  // on scale of 1000 so 4% is 40
    }
    
    // function setHaltPairTrading(address _pair, bool value) public virtual override {
    //     require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
    //     haltPairTrading[_pair] = value; // set true to halt a specific trading in case of emergency security needs
    // }
    // not needed since the underlying code is same for all creators so if issue happens it will happen across the exchange
    
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
        migrationDuration = _migrationDuration; //migration duration in seconds
    }

    // dont get into this because it will be difficult to answer whose tokens are getting burnt
    // this function was implemented to be used for gaming projects but after shifting to Creator Social Tokens it is redundant
    // function setDirectNFTTransfer_Approver(address _directNFTTransferApproverContract) public virtual override {
    //     require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
    //     //few selected gaming based NFT creators will be approved for direct transfer function 
    //     //besides gaming any other reasonable use case will also be allowed
    //     //approval will be creator specific and not on individual NFTs
    //     //only creators whose creator address is a contract will be allowed after that contract's complete introspection 
    //     //this is to ensure creator doesn't end up gifting NFTs to their own other account address since these NFTs can be redeemed for Creator token and cause a rug pull
    //     //our team will verify using directNFTTransferApproverContract and voting will happen via DAO to bring full transparency 
    //     directNFTTransferApproverContract = _directNFTTransferApproverContract; 
    // }

    // only Pair Contract can call
    function updatePair(address token0, address token1, address newPair) public virtual override {
        require(msg.sender==getPair[token0][token1], 'Xeldorado: only Pair allowed');
        require(getPair[token0][token1]!=address(0) && getPair[token1][token0]!=address(0), 'Xeldorado: only existing pairs');
        emit CreatorPairUpdated(getPair[token0][token1], newPair, ICreatorToken(token0).creator());
        getPair[token0][token1] = newPair;
        getPair[token1][token0] = newPair;
    }
}
