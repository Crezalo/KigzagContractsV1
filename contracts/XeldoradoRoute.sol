// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import './interfaces/IXeldoradoFactory.sol';
import './interfaces/IXeldoradoCreatorFactory.sol';
import './interfaces/IXeldoradoVault.sol';
import './interfaces/IXeldoradoPair.sol';
import './interfaces/IERC20X.sol';
import './interfaces/IERC721.sol';
import './interfaces/IWETH.sol';
import './libraries/XeldoradoLibrary.sol';
import './libraries/SafeMath.sol';

contract XeldoradoRoute {
    using SafeMath for uint;

    address public immutable factory;
    address public immutable xeldoradocreatorfactory;
    address public immutable WETH;
    address public admin;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }

    constructor(address _factory, address _WETH) {
        factory = _factory;
        xeldoradocreatorfactory = IXeldoradoFactory(_factory).xeldoradoCreatorFactory();
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    
    //////////////////////////////////
    // ***** Factory functions**** //
    ////////////////////////////////
    function feeTo() public view returns (address){
        return IXeldoradoFactory(factory).feeTo();
    }
    
    function feeToSetter() public view returns (address){
        return IXeldoradoFactory(factory).feeToSetter();
    }
    
    function fee() public view returns(uint){
        return IXeldoradoFactory(factory).fee();
    }
    
    function xeldoradoCreatorFactory() public view returns (address){
        return IXeldoradoFactory(factory).xeldoradoCreatorFactory();
    }

    function getPair(address tokenA, address tokenB) public view returns (address pair){
        pair = IXeldoradoFactory(factory).getPair(tokenA, tokenB);
    }
    
    function allPairs(uint index) public view returns (address pair){
        pair = IXeldoradoFactory(factory).allPairs(index);
    }
    
    function allPairsLength() public view returns (uint){
        return IXeldoradoFactory(factory).allPairsLength();
    }

    function createPair(address tokenA, address tokenB) internal returns (address pair) {
        require(IXeldoradoCreatorFactory(xeldoradocreatorfactory).creatorExist(msg.sender),'Xeldorado: creator does not exist');
        return IXeldoradoFactory(factory).createPair(tokenA, tokenB, msg.sender);
    }
    
    //////////////////////////////////////////
    // ***** Creator Factory functions**** //
    ////////////////////////////////////////
    
    function newCreator(uint _creatorFee) public {
        IXeldoradoCreatorFactory(xeldoradocreatorfactory).newCreator(msg.sender, _creatorFee);
    }
    
    function updateCreatorFee(uint _creatorFee) public{
        IXeldoradoCreatorFactory(xeldoradocreatorfactory).updateCreatorFee(msg.sender, _creatorFee);
    }
    
    function generateCreatorVault(string memory _name, string memory _symbol) public returns(address vault, address token){
        (vault, token) = IXeldoradoCreatorFactory(xeldoradocreatorfactory).generateCreatorVault(msg.sender, _name, _symbol);
    }
    
    function creatorToken(address _creator) public view returns(address ctoken){
       ctoken = IXeldoradoCreatorFactory(xeldoradocreatorfactory).creatorToken(_creator);
    }
    function creatorVault(address _creator) public view returns(address cvault) {
        cvault = IXeldoradoCreatorFactory(xeldoradocreatorfactory).creatorVault(_creator);
    }
    function creatorFee(address _creator) public view returns(uint cfee) {
        cfee = IXeldoradoCreatorFactory(xeldoradocreatorfactory).creatorFee(_creator);
    }
    function allCreators(uint index) public view returns(address creator){
        creator = IXeldoradoCreatorFactory(xeldoradocreatorfactory).allCreators(index);
    }
    
    
    ////////////////////////////////////////
    // ***** Creator Vault functions**** //
    //////////////////////////////////////
    
    function vaultAdmin(address vault) public view returns(address){
        return IXeldoradoVault(vault).admin();
    }
    
    function vaultCreator(address vault) public view returns(address){
        return IXeldoradoVault(vault).creator();
    }
    
    function vaultToken(address vault) public view returns(address){
        return IXeldoradoVault(vault).token();
    }
    
    function vaultBasetoken(address vault) public view returns(address){
        return IXeldoradoVault(vault).basetoken();
    }
    
    function vaultIdTonftContract(uint index, address vault) public view returns(address){
        return IXeldoradoVault(vault).vaultIdTonftContract(index);
    }
    
    function vaultIdToTokenId(uint index, address vault) public view returns(uint){
        return IXeldoradoVault(vault).vaultIdToTokenId(index);
    }
    
    function allNFTs(address vault) public view returns(uint){
        return IXeldoradoVault(vault).allNFTs();
    }
    
    function redeemedNFTs(uint index, address vault) public view returns(uint){
        return IXeldoradoVault(vault).redeemedNFTs(index);
    }
    
    function minpriceofbasetoken(address vault) public view returns(uint){
        return IXeldoradoVault(vault).minpriceofbasetoken();
    }
    
    function vaultPair(address vault) public view returns(address){
        return IXeldoradoVault(vault).pair();
    } 
    
    function startliquidfill(address vault) public view returns(uint){
        return IXeldoradoVault(vault).startliquidfill();
    }
    
    function initialBalance(address vault) public view returns(uint){
        return IXeldoradoVault(vault).initialBalance();
    }
    
    function addMintedNFTERC(address _nft, uint _tokenId, address vault) public{
        require(msg.sender == vaultCreator(vault), 'Xeldorado: only creator can add new NFTs');
        IERC721(_nft).approve(vault, _tokenId);
        IXeldoradoVault(vault).addMintedNFTERC(_nft,_tokenId);
    }
    
    function addNFTByCreateNewCollection(string memory _tokenURI, address vault) public{
        require(msg.sender == vaultCreator(vault), 'Xeldorado: only creator can add new NFTs');
        IXeldoradoVault(vault).addNFTByCreateNewCollection(_tokenURI);
    }
    
    function singleNFTPrice(address vault) public returns(uint){
        return IXeldoradoVault(vault).singleNFTPrice();
    }
    
    function redeemNFT(address _to, uint _vaultId, address vault) public{
        require(IERC20X(vaultToken(vault)).approve(vault, singleNFTPrice(vault)), 'Xeldorado: need token approval');
        IXeldoradoVault(vault).redeemNFT(_to, _vaultId);
        IERC20X(vaultToken(vault)).approve(vault, 0);
    }
    
    function initializeLiquidityOffering(address _basetoken, uint _minpriceofbasetoken, address vault) public {
        require(msg.sender == vaultCreator(vault), 'Xeldorado: only creator can add new NFTs');
        IXeldoradoVault(vault).initializeLiquidityOffering(_basetoken, _minpriceofbasetoken, createPair(creatorToken(vault), WETH));
    }
    
    function bidCreatorToken(address _buyer, uint _amount, uint _bidpriceofbasetoken, address vault) public returns(bool success){
        require(IERC20X(vaultBasetoken(vault)).approve(vault, _amount.mul(_bidpriceofbasetoken).mul(1000).add(fee().mul(10).add(creatorFee(vaultCreator(vault))) / 10) / (10**21)), 'Xeldorado: need approval');
        success = IXeldoradoVault(vault).bidCreatorToken(_buyer, _amount, _bidpriceofbasetoken, fee(), creatorFee(vaultCreator(vault)),feeTo());
        require(IERC20X(vaultBasetoken(vault)).approve(vault, 0), 'Xeldorado: need approval');
    }
    
    function endLiquidityFilling(address vault) public {
        require(msg.sender == vaultCreator(vault), 'Xeldorado: only creator can add new NFTs');
        IXeldoradoVault(vault).endLiquidityFilling();
    }
    function viewLiquidityFiling(address vault) public returns (uint percent){
        require(msg.sender == vaultCreator(vault), 'Xeldorado: only creator can add new NFTs');
        percent = IXeldoradoVault(vault).viewLiquidityFiling(); // scale of 1000
    }
    
    ///////////////////////////////////////
    // ***** Creator Pair functions**** //
    /////////////////////////////////////
}