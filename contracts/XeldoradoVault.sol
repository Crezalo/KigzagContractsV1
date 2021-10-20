// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import './CreatorNFT.sol';
import './interfaces/IERC20X.sol';
import './interfaces/ICreatorToken.sol';
import './interfaces/IXeldoradoVault.sol';
import './libraries/SafeMath.sol';
import './libraries/XeldoradoLibrary.sol';

contract XeldoradoVault is IXeldoradoVault{
    using SafeMath  for uint;
    
    address public override admin;
    address public override creator;
    address public override token;
    address public override basetoken;
    uint256 private liquidityFillStartTime;
    mapping(uint=>address) public override vaultIdTonftContract;    
    mapping(uint=>uint) public override vaultIdToTokenId;
    uint public override allNFTs;
    uint[] public override redeemedNFTs;
    uint public override minpriceofbasetoken;
    address public override pair;
    
    uint public override startliquidfill;
    CreatorNFT private nftcontract;
    uint public override initialBalance;
    
    uint private unlocked = 1;
    uint private ICTOhours;
    
    modifier lock() {
        require(unlocked == 1, 'Xeldorado: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }
    
    constructor(address _creator, string memory _name, string memory _symbol){
        admin = msg.sender;// CreatorFactory
        creator = _creator;
        startliquidfill = 0;
        allNFTs=0;
        nftcontract = new CreatorNFT(_creator,_name,_symbol);
    }
    
    function initialize(address _token) public virtual override {
        require(msg.sender == admin, 'Xeldorado: only CreatorFactory can initialize');
        token = _token;
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
    
    function singleNFTPrice() public virtual override view returns(uint){
        return ((1111888 * 10 ** 18) / (allNFTs.sub(redeemedNFTs.length)));
    }
    
    function singleNFTReturnPrice() public virtual override view returns(uint){
        return ((1111888 * 10 ** 18) / (allNFTs.sub(redeemedNFTs.length).add(1)));
    }
    
    function _exist(uint[] memory _array, uint _vaultId) internal pure returns (bool){
      for (uint i; i < _array.length;i++){
          if (_array[i]==_vaultId) return true;
      }
      return false;
    }
    
    function redeemNFT(address _to, uint _vaultId) public virtual override lock {
        require(_exist(redeemedNFTs, _vaultId) == false, 'Xeldorado: Already reedemed!');
        // uint randomId = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, allNFTs))) % allNFTs;
        
        IERC721(vaultIdTonftContract[_vaultId]).transferFrom(address(this), _to, vaultIdToTokenId[_vaultId]);
        ICreatorToken(token).burnTokens(_to, singleNFTPrice()); //burn creator tokens equivalent to 1 NFT from _to address
        
        // bool success = IERC20X(token).transferFrom(_to, creator, ((1111888 * 10 ** 18) / (allNFTs.sub(redeemedNFTs.length))));
        // require(success, 'Xeldorado: tokens transfer failed');
        redeemedNFTs.push(_vaultId);
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
    
    function ReturnOfRedeemedNFT(address _to, uint _vaultId) public virtual override {
        // get approval
        uint _redeemedNFTid = _findIndexOfVaultIdInRedeemendNFTArray(_vaultId);
        require(_redeemedNFTid != 10**18, 'Xeldorado: invalid vault id for redeemable nft');
        IERC721(vaultIdTonftContract[_vaultId]).transferFrom(_to, address(this), vaultIdToTokenId[_vaultId]);
        ICreatorToken(token).mintTokens(_to,singleNFTReturnPrice()); // mint creator tokens
        
        _removeRedeemedNFTfromArray(_redeemedNFTid);
        
        emit NFTReturned(_to, _vaultId);
    }
    
    
    function initializeLiquidityOffering(address _basetoken, uint _minpriceofbasetoken, address _pair, uint _hours) public virtual override {
        basetoken = _basetoken;
        minpriceofbasetoken = _minpriceofbasetoken;
        startliquidfill = 1;
        pair = _pair;
        liquidityFillStartTime = block.timestamp;
        ICTOhours = _hours;
        emit liquidityFillStarted(token,_basetoken,_minpriceofbasetoken);
    }
    
    // Eg If _minpriceofbasetoken = 7 * 10^16 and buyer bids for 1 CT = 0.1 WETH then _bidpriceofbasetoken = 10 ^ 17 
    function bidCreatorToken(address _buyer, uint _amount, uint _bidpriceofbasetoken, uint _xfee, uint _cfee,address _feeTo) public virtual override lock returns(bool success){
        require(startliquidfill == 1, 'Xeldorado: liquidity filling either not started or already done');
        require(initialBalance<= 2 * (IERC20X(token).balanceOf(address(this)).sub(_amount.mul(10 ** 18))), 'Xeldorado: fully subscribed');
        require(minpriceofbasetoken <= _bidpriceofbasetoken, 'Xeldorado: please bid higher than min price');
        
        success = IERC20X(basetoken).transferFrom(_buyer, address(this), _amount.mul(_bidpriceofbasetoken));
        require(success, 'Xeldorado: transfer of base token failed');
        success = IERC20X(token).transfer(_buyer,_amount.mul(10 ** 18));
        require(success, 'Xeldorado: transfer of token to buyer failed');
        
        // fee
        success = IERC20X(basetoken).transferFrom(_buyer, _feeTo,  XeldoradoLibrary.calculateFee(_amount.mul(_bidpriceofbasetoken), _xfee.mul(10))); //xfee pass calculated fee // scale of 1000 
        require(success, 'Xeldorado: xfee paid');
        success = IERC20X(basetoken).transferFrom(_buyer, creator,  XeldoradoLibrary.calculateFee(_amount.mul(_bidpriceofbasetoken), _cfee)); //cfee pass calculated fee // scale of 10000
        require(success, 'Xeldorado: cfee paid');
        endLiquidityFilling();
    }
    
    function viewLiquidityFiling() public virtual override returns(uint percent){
        require(startliquidfill == 1, 'Xeldorado: liquidity filling either not started or already done');
        uint tokenbalance = IERC20X(token).balanceOf(address(this));
        endLiquidityFilling();
        return (initialBalance.sub(tokenbalance).mul(2*10**18)/initialBalance);
    }
    
    function endLiquidityFilling() public virtual override {
        if(((block.timestamp.sub(liquidityFillStartTime)) / (60)) >= ICTOhours){
            bool success = IERC20X(token).transfer(pair, initialBalance.sub(IERC20X(token).balanceOf(address(this))));
            require(success,'Xeldorado: creator token transfer to Pair failed');
            success = IERC20X(token).transfer(creator, IERC20X(token).balanceOf(address(this)));
            require(success,'Xeldorado: creator token transfer to Pair failed');
            success = IERC20X(basetoken).transfer(pair,IERC20X(basetoken).balanceOf(address(this)));
            require(success,'Xeldorado: base token transfer to Pair failed');
            require(success,'Xeldorado: lquidity pool failure');
            startliquidfill = 2;
            emit liquidityFillEnded(pair);
        }
    }
    
}