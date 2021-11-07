// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import './interfaces/IXeldoradoFactory.sol';
import './interfaces/IXeldoradoCreatorFactory.sol';
import './interfaces/IXeldoradoVault.sol';
import './interfaces/IXeldoradoPair.sol';
import './interfaces/IERC20X.sol';
import './interfaces/IERC721.sol';
import './interfaces/ICreatorVestingVault.sol';
import './libraries/SafeMath.sol';

contract XeldoradoRoute {
    using SafeMath for uint;

    address public immutable factory;
    address public immutable xeldoradocreatorfactory;
    address[] public BaseTokens;
    address public admin;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'Xeldorado: CURRENT VERSION EXPIRED');
        _;
    }

    constructor(address _factory, address[] memory _BaseTokens) {
        factory = _factory;
        xeldoradocreatorfactory = IXeldoradoFactory(_factory).xeldoradoCreatorFactory();
        BaseTokens = _BaseTokens;
        admin = msg.sender;
    }
    
    function _checkTokenExistsInBaseTokens(address btoken) internal view returns(bool){
        for(uint i=0;i<BaseTokens.length;i++){
            if(BaseTokens[i]==btoken){
                return true;
            }
        }
        return false;
    }
    
    function addNewBaseToken(address btoken) public {
        require(msg.sender==admin,'Xeldorado: forbidden');
        IXeldoradoFactory(factory).addNewBaseToken(btoken);
        BaseTokens.push(btoken);
    }

    // receive() external payable {
    //     assert(msg.sender == BaseTokens); // only accept ETH via fallback from the BaseTokens contract
    // }

    
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
    
    function discount() public view returns(uint){
        return IXeldoradoFactory(factory).discount();
    }
    
    function VestingDuration() public view returns(uint){
        return IXeldoradoFactory(factory).VestingDuration();
    }
    
    function noOFTokensForDiscount() public view returns(uint){
        return IXeldoradoFactory(factory).noOFTokensForDiscount();
    }
    
    function exchangeToken() public view returns(address){
        return IXeldoradoFactory(factory).exchangeToken();
    }
    
    function migrationApprover() public view returns(address){
        return IXeldoradoFactory(factory).migrationApprover();
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
    
    // Deploy vault contract via web3 to avoid size limit for creator factory
    function generateCreatorVault(string memory _name, string memory _symbol, address vault) public returns(address token){
        // XeldoradoVault cvault_o = new XeldoradoVault(vaultCreator(vault), _name, _symbol);
        // vault = address(cvault_o);
        token = IXeldoradoCreatorFactory(xeldoradocreatorfactory).generateCreatorVault(msg.sender, _name, _symbol, vault);
    }
    
    function creatorToken(address _creator) public view returns(address ctoken){
       ctoken = IXeldoradoCreatorFactory(xeldoradocreatorfactory).creatorToken(_creator);
    }
    
    function creatorVault(address _creator) public view returns(address cvault) {
        cvault = IXeldoradoCreatorFactory(xeldoradocreatorfactory).creatorVault(_creator);
    }
    
    function creatorVestingVault(address _creator) public view returns(address cvvault) {
        cvvault = IXeldoradoCreatorFactory(xeldoradocreatorfactory).creatorVestingVault(_creator);
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
    
    function vaultCreator(address vault) public view returns(address){
        return IXeldoradoVault(vault).creator();
    }
    
    function vaultCreatorVestingVault(address vault) public view returns(address){
        return IXeldoradoVault(vault).creatorVestingVault();
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
    
    function allRedeemedNFTs(address vault) public view returns(uint){
        return IXeldoradoVault(vault).allRedeemedNFTs();
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
    
    function FLOBalance(address vault) public view returns(uint){
        return IXeldoradoVault(vault).FLOBalance();
    }
    
    function ICTOmin(address vault) public view returns(uint){
        return IXeldoradoVault(vault).ICTOmin();
    }
    
    
    function addMintedNFTERC(address _nft, uint _tokenId, address vault) public{
        require(msg.sender == vaultCreator(vault), 'Xeldorado: only creator can add new NFTs');
        IXeldoradoVault(vault).addMintedNFTERC(_nft,_tokenId);
    }
    
    function addNFTByCreateNewCollection(string memory _tokenURI, address vault) public{
        require(msg.sender == vaultCreator(vault), 'Xeldorado: only creator can add new NFTs');
        IXeldoradoVault(vault).addNFTByCreateNewCollection(_tokenURI);
    }
    
    function addNFTByCreateNewCollection_Batch(string[] memory _tokenURI, address vault) public{
        require(msg.sender == vaultCreator(vault), 'Xeldorado: only creator can add new NFTs');
        IXeldoradoVault(vault).addNFTByCreateNewCollection_Batch(_tokenURI);
    }
    
    function singleNFTPrice(address vault) public view returns(uint){
        return IXeldoradoVault(vault).singleNFTPrice();
    }
    
    function redeemNFT(uint _vaultId, address vault) public{
        // TransferHelper.safeApprove(vaultToken(vault), vault, singleNFTPrice(vault));
        IXeldoradoVault(vault).redeemNFT(msg.sender, _vaultId, fee(), feeTo());
    }
    
    function ReturnOfRedeemedNFT(uint _vaultId, address vault) public {
        require(msg.sender == IERC721(vaultIdTonftContract(_vaultId,vault)).ownerOf(vaultIdToTokenId(_vaultId,vault)), 'Xeldorado: only NFT owner can return');
        // TransferHelper.safeApprove(vaultIdTonftContract(_vaultId,vault),vault,vaultIdToTokenId(_vaultId,vault));
        IXeldoradoVault(vault).ReturnOfRedeemedNFT(msg.sender, _vaultId, fee(), feeTo());
    }
    
    function initializeLiquidityOffering(address _basetoken, uint _minpriceofbasetoken, uint _min, address vault) public {
        require(msg.sender == vaultCreator(vault), 'Xeldorado: only creator can initialize liquidity offering');
        require(_checkTokenExistsInBaseTokens(_basetoken), 'Xeldorado: must be one of the accepted base tokens');
        IXeldoradoVault(vault).initializeLiquidityOffering(_basetoken, _minpriceofbasetoken, createPair(vaultToken(vault), _basetoken), _min);
    }
    
    function addTokensForFLO(uint amount, address vault) public {
        require(msg.sender == vaultCreator(vault), 'Xeldorado: only creator can initialize liquidity offering');
        IXeldoradoVault(vault).addTokensForFLO(amount);
    }
    
    function initializeFurtherLiquidityOffering(uint _min, address vault) public {
        require(msg.sender == vaultCreator(vault), 'Xeldorado: only creator can initialize liquidity offering');
        IXeldoradoVault(vault).initializeFurtherLiquidityOffering(_min);
    }
    
    function bidCreatorToken(uint _amount, uint _bidpriceofbasetoken, address vault) public{
        // uint totalFees = XeldoradoLibrary1.calculateFee(_amount.mul(_bidpriceofbasetoken)/10**18, fee().mul(10)).add(XeldoradoLibrary1.calculateFee(_amount.mul(_bidpriceofbasetoken)/10**18, creatorFee(vaultCreator(vault))));
        // TransferHelper.safeApprove(vaultBasetoken(vault), vault, (_amount.mul(_bidpriceofbasetoken) / (10**18)).add(totalFees));
        IXeldoradoVault(vault).bidCreatorToken(msg.sender, _amount, _bidpriceofbasetoken, fee(), creatorFee(vaultCreator(vault)), feeTo());
        // TransferHelper.safeApprove(vaultBasetoken(vault), vault, 0);
    }
    
    function endLiquidityFilling(address vault) public {
        // require(msg.sender == vaultCreator(vault), 'Xeldorado: only creator can end Liquidity offering');
        IXeldoradoVault(vault).endLiquidityFilling();
        IXeldoradoPair(vaultPair(vault)).LiquidityAdded();
    }
    
    function viewLiquidityFiling(address vault) public view returns (uint percent){
        // require(msg.sender == vaultCreator(vault), 'Xeldorado: only creator can view Liquidity offering status');
        percent = IXeldoradoVault(vault).viewLiquidityFiling(); // scale of 1000
    }
    
    ///////////////////////////////////////
    // ***** Creator Pair functions**** //
    /////////////////////////////////////
    
    function pairMINIMUM_LIQUIDITY(address pair) public pure returns (uint){
        return IXeldoradoPair(pair).MINIMUM_LIQUIDITY();
    }
    
    function pairAdmin(address pair) public view returns (address){
        return IXeldoradoPair(pair).admin();
        
    }
    
    function pairToken0(address pair) public view returns (address){
        return IXeldoradoPair(pair).token0();
    }
    
    function pairToken1(address pair) public view returns (address){
        return IXeldoradoPair(pair).token1();
        
    }
    
    function pairGetReserves(address pair) public view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast){
        return IXeldoradoPair(pair).getReserves();
        
    }
    
    function pairPrice0CumulativeLast(address pair) public view returns (uint){
        return IXeldoradoPair(pair).price0CumulativeLast();
    }
    
    function pairPrice1CumulativeLast(address pair) public view returns (uint){
        return IXeldoradoPair(pair).price1CumulativeLast();
        
    }
    
    function pairCreator(address pair) public view returns (address){
        return IXeldoradoPair(pair).creator();
    }
    
    function pairLiquidityAdded(address pair) public{
       IXeldoradoPair(pair).LiquidityAdded();
    }
    
    function pairSwap(address tokenIn, uint amountIn, address tokenOut, uint amountOut, address pair) public payable {
        if (tokenIn == pairToken1(pair)){
            // TransferHelper.safeApprove(tokenIn, pair, amountIn.add(XeldoradoLibrary1.calculateFee(amountIn, fee().mul(10)).add(XeldoradoLibrary1.calculateFee(amountIn, creatorFee(pairCreator(pair))))));
            IXeldoradoPair(pair).swap(tokenIn, amountIn, tokenOut, amountOut, msg.sender);
            // TransferHelper.safeApprove(tokenIn, pair, 0);
        }
        else if(tokenOut== pairToken1(pair)){
            // TransferHelper.safeApprove(tokenIn, pair, amountIn);
            // TransferHelper.safeApprove(tokenOut, pair, XeldoradoLibrary1.calculateFee(amountOut, fee().mul(10)).add(XeldoradoLibrary1.calculateFee(amountOut, creatorFee(pairCreator(pair)))));
            IXeldoradoPair(pair).swap(tokenIn, amountIn, tokenOut, amountOut, msg.sender);
            // TransferHelper.safeApprove(tokenIn, pair, 0);
        }
        else {
            require(1==0,"Xeldorado: Shouldn't reach here none of the token is base token");
        }
        
    }
    
    function pairSync(address pair) public{
        IXeldoradoPair(pair).sync();
    }
    
    
    ////////////////////////////////////////////////
    // ***** Creator Vesting Vault functions**** //
    //////////////////////////////////////////////
    
    function creatorVVInitialCreatorVVBalance(address _creatorVestingVault) public view returns(uint){
        return ICreatorVestingVault(_creatorVestingVault).initialCreatorVVBalance();
    }
    
    function creatorVVCurrentCreatorVVBalance(address _creatorVestingVault) public view returns(uint){
        return ICreatorVestingVault(_creatorVestingVault).currentCreatorVVBalance();
    }
    
    function creatorVVMinimumCreatorBalancee(address _creatorVestingVault) public view returns(uint){
        return ICreatorVestingVault(_creatorVestingVault).minimumCreatorBalance();
    }
    
    function creatorVVRedeemedVestedTokens(address _creatorVestingVault, uint _amount) public {
        ICreatorVestingVault(_creatorVestingVault).redeemedVestedTokens(_amount);
    }
}