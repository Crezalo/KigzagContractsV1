// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import './CreatorNFT.sol';
import './interfaces/IERC20X.sol';
import './interfaces/IXeldoradoVault.sol';
import './libraries/SafeMath.sol';

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
    
    
    function addMintedNFTERC(address _nft, uint _tokenId) public virtual override {
        IERC721(_nft).safeTransferFrom(creator, address(this),_tokenId);
        vaultIdTonftContract[allNFTs] = _nft;
        vaultIdToTokenId[allNFTs] = _tokenId;
        allNFTs +=  1;
        emit NFTadded(vaultIdTonftContract[allNFTs-1], vaultIdToTokenId[allNFTs-1]);
    }
    
    
    function addNFTByCreateNewCollection(string memory _tokenURI) public virtual override{
        uint tokenId = nftcontract.createToken(_tokenURI, address(this));
        vaultIdTonftContract[allNFTs] = address(nftcontract);
        vaultIdToTokenId[allNFTs] = tokenId;
        allNFTs +=  1;
        emit NFTadded(vaultIdTonftContract[allNFTs-1], vaultIdToTokenId[allNFTs-1]);
    }
    
    function singleNFTPrice() public virtual override view returns(uint){
        return ((118888 * 10 ** 18) / (allNFTs.sub(redeemedNFTs.length)));
    }
    
    function _exist(uint[] memory _array, uint _vaultId) internal pure returns (bool){
      for (uint i; i < _array.length;i++){
          if (_array[i]==_vaultId) return true;
      }
      return false;
    }
    
    function redeemNFT(address _to, uint _vaultId) public virtual override {
        require(_exist(redeemedNFTs, _vaultId) == false, 'Xeldorado: Already reedemed!');
        // uint randomId = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, allNFTs))) % allNFTs;
        IERC721(vaultIdTonftContract[_vaultId]).safeTransferFrom(address(this), _to, vaultIdToTokenId[_vaultId]);
        bool success = IERC20X(token).transferFrom(_to, creator, ((118888 * 10 ** 18) / (allNFTs.sub(redeemedNFTs.length))));
        require(success, 'Xeldorado: tokens transfer failed');
        redeemedNFTs.push(_vaultId);
        emit NFTRedeemed(vaultIdTonftContract[_vaultId], vaultIdToTokenId[_vaultId]);
    }
    
    
    function initializeLiquidityOffering(address _basetoken, uint _minpriceofbasetoken, address _pair) public virtual override {
        basetoken = _basetoken;
        minpriceofbasetoken = _minpriceofbasetoken;
        startliquidfill = 1;
        pair = _pair;
        liquidityFillStartTime = block.timestamp;
        emit liquidityFillStarted(token,_basetoken,_minpriceofbasetoken);
    }
    
    // Eg If _minpriceofbasetoken = 7 * 10^16 and buyer bids for 1 CT = 0.1 WETH then _bidpriceofbasetoken = 10 ^ 17 
    function bidCreatorToken(address _buyer, uint _amount, uint _bidpriceofbasetoken, uint _xfee, uint _cfee,address _feeTo) public virtual override returns(bool success){
        require(startliquidfill == 1, 'Xeldorado: liquidity filling either not started or already done');
        require(initialBalance>= 2 * (IERC20X(token).balanceOf(address(this)).sub(_amount)), 'Xeldorado: fully subscribed');
        require(minpriceofbasetoken <= _bidpriceofbasetoken, 'Xeldorado: please bid higher than min price');
        
        success = IERC20X(basetoken).transferFrom(_buyer, address(this), _amount.mul(_bidpriceofbasetoken) / (10**18));
        require(success, 'Xeldorado: transfer of base token failed');
        success = IERC20X(token).transfer(_buyer,_amount);
        require(success, 'Xeldorado: transfer of token to buyer failed');
        
        // fee
        success = IERC20X(basetoken).transferFrom(_buyer, _feeTo, _xfee);
        require(success, 'Xeldorado: xfee paid');
        success = IERC20X(basetoken).transferFrom(_buyer, creator, _cfee);
        require(success, 'Xeldorado: cfee paid');
        endLiquidityFilling();
    }
    
    function viewLiquidityFiling() public virtual override returns(uint percent){
        require(startliquidfill == 1, 'Xeldorado: liquidity filling either not started or already done');
        uint tokenbalance = IERC20X(token).balanceOf(address(this));
        endLiquidityFilling();
        return (tokenbalance/(2 * 118888 * 10 ** 15));
    }
    
    function endLiquidityFilling() public virtual override {
        if(((block.timestamp.sub(liquidityFillStartTime)) / (24 * 60 * 60)) >= 14){
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