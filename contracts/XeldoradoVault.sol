// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import './CreatorNFT.sol';
import './interfaces/IERC20X.sol';
import './interfaces/ICreatorToken.sol';
import './interfaces/IXeldoradoVault.sol';
import './interfaces/IXeldoradoFactory.sol';
import './interfaces/IXeldoradoPair.sol';
import './interfaces/ICreatorVestingVault.sol';
import './libraries/SafeMath.sol';
// import './libraries/XeldoradoLibrary1.sol';

contract XeldoradoVault is IXeldoradoVault{
    using SafeMath  for uint;
    
    // address private admin;
    address public override creator;
    address public override creatorVestingVault;
    address public override token;
    address public override basetoken;
    uint256 private liquidityFillStartTime;
    mapping(uint=>address) public override vaultIdTonftContract;    
    mapping(uint=>uint) public override vaultIdToTokenId;
    mapping(uint=>bool) public override vaultIdTodrirectNFTTrasnfer;
    uint public override allNFTs;
    uint[] public override redeemedNFTs;
    uint public override allRedeemedNFTs;
    uint public override minpriceofbasetoken;
    address public override pair;
    
    uint public override startliquidfill;
    CreatorNFT private nftcontract;
    uint public override initialBalance;
    uint public override FLOBalance;
    
    
    uint private unlocked;
    uint public override ICTOmin;
    bool private migrationApproved;
    
    modifier lock() {
        require(unlocked == 1, 'Xeldorado: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }
    
    constructor(string memory _name, string memory _symbol){
        creator = msg.sender; // Creator
        startliquidfill = 0;
        allNFTs=0;
        unlocked = 1;
        nftcontract = new CreatorNFT(creator,_name,_symbol);
    }
    
    function initialize(address _token, address _creatorVestingVault) public virtual override {
        // require(msg.sender == admin, 'Xeldorado: Forbidden');
        token = _token;
        creatorVestingVault = _creatorVestingVault;
        initialBalance = IERC20X(token).balanceOf(address(this));
    }
    
    
    function addMintedNFTERC(address _nft, uint _tokenId) public virtual override lock {
        IERC721(_nft).transferFrom(creator, address(this),_tokenId);
        vaultIdTonftContract[allNFTs] = _nft;
        vaultIdToTokenId[allNFTs] = _tokenId;
        allNFTs +=  1;
        emit NFTadded(vaultIdTonftContract[allNFTs-1], vaultIdToTokenId[allNFTs-1]);
    }
    
    
    function addNFTByCreateNewCollection(string memory _tokenURI) public virtual override lock {
        uint tokenId = nftcontract.createToken(_tokenURI, address(this));
        vaultIdTonftContract[allNFTs] = address(nftcontract);
        vaultIdToTokenId[allNFTs] = tokenId;
        allNFTs +=  1;
        emit NFTadded(vaultIdTonftContract[allNFTs-1], vaultIdToTokenId[allNFTs-1]);
    }
    
    
    function addNFTByCreateNewCollection_Batch(string[] memory _tokenURI) public virtual override lock {
        uint[] memory tokenId = nftcontract.createBatchToken(_tokenURI, address(this));
        for(uint i=0;i<tokenId.length;i++)
        {
            vaultIdTonftContract[allNFTs] = address(nftcontract);
            vaultIdToTokenId[allNFTs] = tokenId[i];
            allNFTs +=  1;
            emit NFTadded(vaultIdTonftContract[allNFTs-1], vaultIdToTokenId[allNFTs-1]);
        }
    }
    
    function singleNFTPrice() public virtual override view returns(uint){
        return (IERC20X(token).totalSupply() / (allNFTs.sub(redeemedNFTs.length)));
    }

    function _exist(uint[] memory _array, uint _vaultId) internal pure returns (bool){
        for (uint i; i < _array.length;i++){
            if (_array[i]==_vaultId) return true;
        }
        return false;
    }
      
    function calculateFee(uint amount, uint fee) internal pure returns (uint) {
        // fee percent in scale of 10000
        return amount.mul(fee)/10000;
    }
    
    function redeemNFT(address _to, uint _vaultId, uint _xfee, address _feeTo) public virtual override lock {
        require(_exist(redeemedNFTs, _vaultId) == false, 'Xeldorado: Already reedemed!');
        
        IERC721(vaultIdTonftContract[_vaultId]).transferFrom(address(this), _to, vaultIdToTokenId[_vaultId]);
        ICreatorToken(token).burnTokens(_to, singleNFTPrice()); //burn creator tokens equivalent to 1 NFT from _to address
        ICreatorToken(token).mintTokens(_feeTo, calculateFee(singleNFTPrice(), _xfee.mul(10))); //mint xfee in creator token
        
        redeemedNFTs.push(_vaultId);
        allRedeemedNFTs += 1;
        emit NFTRedeemed(vaultIdTonftContract[_vaultId], vaultIdToTokenId[_vaultId]);
    }
    
    function _findIndexOfVaultIdInRedeemendNFTArray(uint _vaultId) internal view returns(uint){
        for(uint k=0;k<redeemedNFTs.length;k++){
            if(redeemedNFTs[k]==_vaultId){
                return k;
            }
        }
        
        return 10**18;
    }
    
    function _removeRedeemedNFTfromArray(uint index) internal {
      require(index < redeemedNFTs.length);
      redeemedNFTs[index] = redeemedNFTs[redeemedNFTs.length-1];
      redeemedNFTs.pop();
    }
    
    function ReturnOfRedeemedNFT(address _to, uint _vaultId, uint _xfee, address _feeTo) public virtual override lock {
        // get approval
        uint _redeemedNFTid = _findIndexOfVaultIdInRedeemendNFTArray(_vaultId);
        require(_redeemedNFTid != 10**18, 'Xeldorado: invalid vaultid');
        IERC721(vaultIdTonftContract[_vaultId]).transferFrom(_to, address(this), vaultIdToTokenId[_vaultId]);
        if(IXeldoradoFactory(IXeldoradoPair(pair).factory()).noOFTokensForDiscount() <= IERC20X(IXeldoradoFactory(IXeldoradoPair(pair).factory()).exchangeToken()).balanceOf(_to))
        {
            ICreatorToken(token).mintTokens(_to, singleNFTPrice().sub(calculateFee(singleNFTPrice(), _xfee.sub(IXeldoradoFactory(IXeldoradoPair(pair).factory()).discount()).mul(10)))); // mint creator tokens
            ICreatorToken(token).mintTokens(_feeTo, calculateFee(singleNFTPrice(), _xfee.sub(IXeldoradoFactory(IXeldoradoPair(pair).factory()).discount()).mul(10))); //mint xfee in creator token 
        }
        else{
            ICreatorToken(token).mintTokens(_to,singleNFTPrice().sub(calculateFee(singleNFTPrice(), _xfee.mul(10)))); // mint creator tokens
            ICreatorToken(token).mintTokens(_feeTo, calculateFee(singleNFTPrice(), _xfee.mul(10))); //mint xfee in creator token 
        }
        
        _removeRedeemedNFTfromArray(_redeemedNFTid);
        allRedeemedNFTs -= 1;
        emit NFTReturned(_to, _vaultId);
    }
    
    
    function initializeLiquidityOffering(address _basetoken, uint _minpriceofbasetoken, address _pair, uint _min) public virtual override lock{
        require(startliquidfill == 0, 'Xeldorado: liquidity offering already initialized.');
        basetoken = _basetoken;
        minpriceofbasetoken = _minpriceofbasetoken;
        startliquidfill = startliquidfill + 1;
        pair = _pair;
        liquidityFillStartTime = block.timestamp;
        ICTOmin = _min;
        ICreatorVestingVault(creatorVestingVault).initialize(token, creator);
        emit liquidityFillStarted(token,_basetoken,_minpriceofbasetoken);

    }
    
    function addTokensForFLO(uint amount) public virtual override lock {
        IERC20X(token).transferFrom(creator, address(this), amount);
        FLOBalance = amount;
    }
    
    function initializeFurtherLiquidityOffering(uint _min) public virtual override lock {
        require(startliquidfill%3 == 0, 'Xeldorado: liquidity currently running');
        (uint ctreserve, uint btreserve, ) = IXeldoradoPair(pair).getReserves();
        minpriceofbasetoken = (btreserve * 10 ** 18)/ctreserve;
        startliquidfill = startliquidfill + 1;
        liquidityFillStartTime = block.timestamp;
        ICTOmin = _min;
        emit liquidityFillStarted(token,basetoken,minpriceofbasetoken);
    }
    
    // Eg If _minpriceofbasetoken = 7 * 10^16 and buyer bids for 1 CT = 0.1 WETH then _bidpriceofbasetoken = 10 ^ 17 
    function bidCreatorToken(address _buyer, uint _amount, uint _bidpriceofbasetoken, uint _xfee, uint _cfee,address _feeTo) public virtual override lock{
        require(startliquidfill%3 == 1, 'Xeldorado: liquidity filling either not started or already done');
        
        if (startliquidfill >3)
        {
            require(FLOBalance<= 2 * (IERC20X(token).balanceOf(address(this)).sub(_amount.mul(10 ** 18))), 'Xeldorado: amount beyond fully subscription');
            (uint ctreserve, uint btreserve, ) = IXeldoradoPair(pair).getReserves();
            minpriceofbasetoken = (btreserve * 10 ** 18)/ctreserve;
        }
        else{
            require(initialBalance<= 2 * (IERC20X(token).balanceOf(address(this)).sub(_amount.mul(10 ** 18))), 'Xeldorado: amount beyond fully subscription');
        }
        
        require(minpriceofbasetoken <= _bidpriceofbasetoken, 'Xeldorado: please bid higher than min price');
        require(IERC20X(basetoken).transferFrom(_buyer, address(this), _amount.mul(_bidpriceofbasetoken)), 'Xeldorado: transfer 1 failed');
        require(IERC20X(token).transfer(_buyer,_amount.mul(10 ** 18)), 'Xeldorado: transfer 2 failed');
        
        // fee
        if(IXeldoradoFactory(IXeldoradoPair(pair).factory()).noOFTokensForDiscount() <= IERC20X(IXeldoradoFactory(IXeldoradoPair(pair).factory()).exchangeToken()).balanceOf(_buyer))
        {
            //xfee pass calculated fee // scale of 1000 
            require(IERC20X(basetoken).transferFrom(_buyer, _feeTo,  calculateFee(_amount.mul(_bidpriceofbasetoken), _xfee.sub(IXeldoradoFactory(IXeldoradoPair(pair).factory()).discount()).mul(10))), 'Xeldorado: xfee paid');
        }
        else{
            //xfee pass calculated fee // scale of 1000 
            require(IERC20X(basetoken).transferFrom(_buyer, _feeTo,  calculateFee(_amount.mul(_bidpriceofbasetoken), _xfee.mul(10))), 'Xeldorado: xfee paid');
            
        }
        //cfee pass calculated fee // scale of 10000
        require(IERC20X(basetoken).transferFrom(_buyer, creator,  calculateFee(_amount.mul(_bidpriceofbasetoken), _cfee)), 'Xeldorado: cfee paid');
        emit biddingCreatorToken(_buyer, _amount, _bidpriceofbasetoken);
        endLiquidityFilling();
    }
    
    function viewLiquidityFiling() public virtual override view returns(uint percent){
        require(startliquidfill%3 == 1, 'Xeldorado: liquidity filling either not started or already done');
        uint tokenbalance = IERC20X(token).balanceOf(address(this));
        if(startliquidfill>3) return (FLOBalance.sub(tokenbalance).mul(2*10**18)/FLOBalance);
        return (initialBalance.sub(tokenbalance).mul(20000)/initialBalance); // (InitialBalance - CurrentBalance )/(InitialBalance/2) on scale of 10000 so 97.58% = 9758
    }
    
    function endLiquidityFilling() public virtual override {
        if(((block.timestamp.sub(liquidityFillStartTime)) / (60)) >= ICTOmin){
            if(startliquidfill>3) require(IERC20X(token).transfer(pair, FLOBalance.sub(IERC20X(token).balanceOf(address(this)))),'Xeldorado: creator token transfer to Pair failed');
            else require(IERC20X(token).transfer(pair, initialBalance.sub(IERC20X(token).balanceOf(address(this)))),'Xeldorado: transfer 3 failed');
            require(IERC20X(token).transfer(creatorVestingVault, IERC20X(token).balanceOf(address(this))),'Xeldorado: transfer 4 failed');
            require(IERC20X(basetoken).transfer(pair,IERC20X(basetoken).balanceOf(address(this))),'Xeldorado: transfer 5 failed');
            startliquidfill = startliquidfill + 2;
            IXeldoradoPair(pair).LiquidityAdded();
            emit liquidityFillEnded(pair);
        }
    }
    
    // Use web3 and interface for below functions
    function approveDirectNFTTransfer(uint vaultId) public virtual override {
        require(msg.sender == creator, 'Xeldorado: creator only');
        vaultIdTodrirectNFTTrasnfer[vaultId] = true;
    }
    
    function directTransferNFT(uint _vaultId, address _to) public virtual override lock {
        require(msg.sender == creator, 'Xeldorado: creator only');
        IERC721(vaultIdTonftContract[_vaultId]).transferFrom(address(this), _to, vaultIdToTokenId[_vaultId]);
        redeemedNFTs.push(_vaultId);
        allRedeemedNFTs += 1;
    }
    
    function migrateNFTToV2_createRequest() public virtual override {
        require(msg.sender == creator, 'Xeldorado: creator only');
        migrationApproved = true;
        emit migrationVaultRequestCreated();
    }
    
    function migrationApprove(address toContract) public virtual override lock {
        require((msg.sender == IXeldoradoFactory(IXeldoradoPair(pair).factory()).migrationApprover() && migrationApproved), 'Xeldorado: migrator allowed after creator approves migration');
        for(uint i; i< allNFTs; i++){
            if(_findIndexOfVaultIdInRedeemendNFTArray(i) == 10**18){
                IERC721(vaultIdTonftContract[i]).transferFrom(address(this), toContract, vaultIdToTokenId[i]);
            }
        }
        emit migrationVaultRequestApproved(toContract);
    }
}