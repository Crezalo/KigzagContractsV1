// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import './interfaces/IXeldoradoFactory.sol';
import './interfaces/IXeldoradoCreatorFactory.sol';
import './interfaces/IXeldoradoVault.sol';
import './interfaces/IXeldoradoPair.sol';
import './interfaces/ICreatorToken.sol';
import './interfaces/ICreatorNFT.sol';
import './interfaces/ICreatorDAO.sol';
import './interfaces/ICreatorVestingVault.sol';
import './libraries/SafeMath.sol';
import './libraries/XeldoradoLibrary.sol';

contract XeldoradoRoute {
    using SafeMath for uint;

    address public immutable factory;
    address public immutable xeldoradocreatorfactory;
    address public admin;
    uint unlocked;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'Xeldorado: CURRENT VERSION EXPIRED');
        _;
    }

    modifier lock() {
        require(unlocked == 1, 'Xeldorado: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor(address _factory) {
        factory = _factory;
        xeldoradocreatorfactory = IXeldoradoFactory(_factory).xeldoradoCreatorFactory();
        admin = msg.sender;
        unlocked==1;
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
    
    function swapFee() public view returns(uint){
        return IXeldoradoFactory(factory).swapFee();
    }
    
    function ictoFee() public view returns(uint){
        return IXeldoradoFactory(factory).ictoFee();
    }
    
    function nftFee() public view returns(uint){
        return IXeldoradoFactory(factory).nftFee();
    }
    
    function maxCreatorFee() public view returns(uint){
        return IXeldoradoFactory(factory).maxCreatorFee();
    }
    
    function swapDiscount() public view returns(uint){
        return IXeldoradoFactory(factory).swapDiscount();
    }
    
    function ictoDiscount() public view returns(uint){
        return IXeldoradoFactory(factory).ictoDiscount();
    }
    
    function nftDiscount() public view returns(uint){
        return IXeldoradoFactory(factory).nftDiscount();
    }
    
    function VestingDuration() public view returns(uint){
        return IXeldoradoFactory(factory).VestingDuration();
    }
    
    function vestingCliffInt() public view returns(uint){
        return IXeldoradoFactory(factory).vestingCliffInt();
    }
    
    function noOFTokensForDiscount() public view returns(uint){
        return IXeldoradoFactory(factory).noOFTokensForDiscount();
    }
    
    function exchangeToken() public view returns(address){
        return IXeldoradoFactory(factory).exchangeToken();
    }
    
    function totalCreatorTokenSupply() public view returns(uint){
        return IXeldoradoFactory(factory).totalCreatorTokenSupply();
    }
    
    function percentCreatorOwnership() public view returns(uint){
        return IXeldoradoFactory(factory).percentCreatorOwnership();
    }
    
    // migration contract
    function migrationContract() public view returns(address){
        return IXeldoradoFactory(factory).migrationContract();
    }

    // migration voting duration 
    function migrationDuration() public view returns(uint){
        return IXeldoradoFactory(factory).migrationDuration();
    }

    function haltAllPairsTrading() public view returns(bool){
        return IXeldoradoFactory(factory).haltAllPairsTrading();
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

    function checkTokenExistsInBaseTokens(address btoken) internal view returns(bool){
        return IXeldoradoFactory(factory).checkTokenExistsInBaseTokens(btoken);
    }
    
    //////////////////////////////////////////
    // ***** Creator Factory functions**** //
    ////////////////////////////////////////
    
    function creatorToken(address _creator) public view returns(address ctoken){
       ctoken = IXeldoradoCreatorFactory(xeldoradocreatorfactory).creatorToken(_creator);
    }
    
    function creatorVault(address _creator) public view returns(address cvault) {
        cvault = IXeldoradoCreatorFactory(xeldoradocreatorfactory).creatorVault(_creator);
    }
    
    function creatorVestingVault(address _creator) public view returns(address cvvault) {
        cvvault = IXeldoradoCreatorFactory(xeldoradocreatorfactory).creatorVestingVault(_creator);
    }

    function creatorBank(address _creator) public view returns(address cBank) {
        cBank = IXeldoradoCreatorFactory(xeldoradocreatorfactory).creatorBank(_creator);
    }

    function creatorDAO(address _creator) public view returns(address cdao) {
        cdao = IXeldoradoCreatorFactory(xeldoradocreatorfactory).creatorDAO(_creator);
    }
    
    function creatorSwapFee(address _creator) public view returns(uint cfee) {
        cfee = IXeldoradoCreatorFactory(xeldoradocreatorfactory).creatorSwapFee(_creator);
    }
    
    function creatorCTOFee(address _creator) public view returns(uint cfee) {
        cfee = IXeldoradoCreatorFactory(xeldoradocreatorfactory).creatorCTOFee(_creator);
    }
    
    function creatorNFTFee(address _creator) public view returns(uint cfee) {
        cfee = IXeldoradoCreatorFactory(xeldoradocreatorfactory).creatorNFTFee(_creator);
    }

    function allCreators(uint index) public view returns(address creator){
        creator = IXeldoradoCreatorFactory(xeldoradocreatorfactory).allCreators(index);
    }

    function creatorExist(address _creator) public view returns(bool){
        return IXeldoradoCreatorFactory(xeldoradocreatorfactory).creatorExist(_creator);
    }

    function newCreator(uint _creatorFee) public {
        IXeldoradoCreatorFactory(xeldoradocreatorfactory).newCreator(msg.sender, _creatorFee, 0, 0);
    }
    
    // Deploy vault contract via web3 to avoid size limit for creator factory
    function generateCreatorVault(string memory _name, string memory _symbol, address vault, address cdao) public returns(address token){
        token = IXeldoradoCreatorFactory(xeldoradocreatorfactory).generateCreatorVault(msg.sender, _name, _symbol, vault, cdao);
    }

    function syncMigrationContractVoting(address _creator) public {
        IXeldoradoCreatorFactory(xeldoradocreatorfactory).syncMigrationContractVoting(_creator);
    }
    
    ////////////////////////////////////////
    // ***** Creator Vault functions**** //
    //////////////////////////////////////
    
    function vaultCreator(address vault) public view returns(address){
        return IXeldoradoVault(vault).creator();
    }
    
    function vaultCreatorDAO(address vault) public view returns(address){
        return IXeldoradoVault(vault).creatorDAO();
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
    
    function allRedeemedNFTs(address vault) public view returns(uint){
        return IXeldoradoVault(vault).allRedeemedNFTs();
    }
    
    function minpriceofbasetoken(address vault) public view returns(uint){
        return IXeldoradoVault(vault).minpriceofbasetoken();
    }
    
    function vaultPair(address vault) public view returns(address){
        return IXeldoradoVault(vault).pair();
    } 
    
    function vaultNftContract(address vault) public view returns(address){
        return IXeldoradoVault(vault).nftContract();
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
    
    function ICTOduration(address vault) public view returns(uint){
        return IXeldoradoVault(vault).ICTOduration();
    }
    
    function singleNFTPrice(address vault) public view returns(uint){
        return IXeldoradoVault(vault).singleNFTPrice();
    }
    
    function redeemNFT(address _to, uint[] memory _vaultIds, address vault) public{
        IXeldoradoVault(vault).redeemNFT(_to, _vaultIds);
    }
    
    function returnOfRedeemedNFT(address _to, uint[] memory _vaultIds, address vault) public {
        IXeldoradoVault(vault).returnOfRedeemedNFT(_to, _vaultIds);
    }
    
    // same creator
    function swapNFT(address _swapper, uint[] memory _inVaultIds, uint[] memory _outVaultIds, address vault) public {
        IXeldoradoVault(vault).swapNFT(_swapper, _inVaultIds, _outVaultIds);
    }
    
    function bidCreatorToken(address _to, uint _amount, uint _bidpriceofbasetoken, address vault) public{
        IXeldoradoVault(vault).bidCreatorToken(_to, _amount, _bidpriceofbasetoken);
    }
    
    function endLiquidityFilling(address vault) public {
        IXeldoradoVault(vault).endLiquidityFilling();
        IXeldoradoPair(vaultPair(vault)).LiquidityAdded();
    }
    
    function viewLiquidityFiling(address vault) public view returns (uint percent){
        percent = IXeldoradoVault(vault).viewLiquidityFiling(); // scale of 1000
    }
    
    ///////////////////////////////////////
    // ***** Creator Pair functions**** //
    /////////////////////////////////////
    
    function pairMINIMUM_LIQUIDITY(address pair) public pure returns (uint){
        return IXeldoradoPair(pair).MINIMUM_LIQUIDITY();
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
    
    function pairSwap(address _to, address tokenIn, uint amountIn, address tokenOut, uint amountOut, address pair) public {
        IXeldoradoPair(pair).swap(tokenIn, amountIn, tokenOut, amountOut, _to);
    }
    
    function pairSync(address pair) public{
        IXeldoradoPair(pair).sync();
    }

    ////////////////////////////////////////////////
    // ***** Cross Creator NFT Swap function**** //
    //////////////////////////////////////////////

    // function crossCreatorNFTSwapStats(address _swapper, address _inVault, address _outVault) public view returns (uint extraBaseTokensNeeded, uint leftOverBaseTokensDeposited, uint amountOut, uint amountIn, uint creatorTokensOut, uint creatorTokensIn) {
    //     (extraBaseTokensNeeded, leftOverBaseTokensDeposited, amountOut, amountIn, creatorTokensOut, creatorTokensIn) = XeldoradoLibrary.crossCreatorNFTSwapStats(_swapper, _inVault, _outVault);
    // }
    
    // get in NFT approval
    // get creator tokens worth single NFT approval
    // get base tokens approval
    // if extra base tokens needed count that as well
    // get creator token 2 approval worth single NFT
    // send only single element in inVaultID and outVaultId
    // function crossCreatorNFTSwap(address _swapper, address _inVault, uint _inVaultId, address _outVault, uint _outVaultId) public {

    //     (uint extraBaseTokensNeeded, uint leftOverBaseTokensDeposited, uint amountOut, uint amountIn, uint creatorTokensOut, uint creatorTokensIn) = crossCreatorNFTSwapStats(_swapper, _inVault, _outVault);

    //     IERC721(vaultIdTonftContract(_inVaultId, _inVault)).transferFrom(_swapper, address(this), vaultIdToTokenId(_inVaultId, _inVault));

    //     if(extraBaseTokensNeeded > 0){
    //         IERC20X(vaultBasetoken(_inVault)).transferFrom(_swapper, address(this), extraBaseTokensNeeded);
    //     }
    //     returnOfRedeemedNFT(address(this), new uint[](_inVaultId), _inVault);
        
    //     crossCreatorTokenSwap(_inVault, _outVault, amountOut, amountIn, creatorTokensOut, creatorTokensIn);
        
    //     redeemNFT(address(this), new uint[](_outVaultId), _outVault);

    //     if(leftOverBaseTokensDeposited>0 && (IERC20X(vaultBasetoken(_inVault)).balanceOf(address(this))==leftOverBaseTokensDeposited)) {
    //         IERC20X(vaultBasetoken(_inVault)).transferFrom(address(this), _swapper, leftOverBaseTokensDeposited);
    //     }
    // }

    // function crossCreatorTokenSwap(address _inVault, address _outVault, uint amountOut, uint amountIn, uint creatorTokensOut, uint creatorTokensIn) public {
    //     pairSwap(address(this), vaultToken(_inVault), creatorTokensOut, vaultBasetoken(_inVault), amountOut, vaultPair(_inVault));
    //     pairSwap(address(this), vaultBasetoken(_inVault), amountIn, vaultToken(_outVault), creatorTokensIn, vaultPair(_outVault));
    // }
    
    ////////////////////////////////////////////////
    // ***** Creator Vesting Vault functions**** //
    //////////////////////////////////////////////
    
    function creatorVVInitialCreatorVVBalance(address _creatorVestingVault) public view returns(uint){
        return ICreatorVestingVault(_creatorVestingVault).initialCreatorVVBalance();
    }
    
    function creatorVVCurrentCreatorVVBalance(address _creatorVestingVault) public view returns(uint){
        return ICreatorVestingVault(_creatorVestingVault).currentCreatorVVBalance();
    }
    
    function creatorVVRedeemedCreatorBalance(address _creatorVestingVault) public view returns(uint){
        return ICreatorVestingVault(_creatorVestingVault).redeemedCreatorBalance();
    }
    
    function creatorVVCreator(address _creatorVestingVault) public view returns (address){
        return ICreatorVestingVault(_creatorVestingVault).creator();
    }
    
    function creatorVVToken(address _creatorVestingVault) public view returns (address){
        return ICreatorVestingVault(_creatorVestingVault).ctoken();
    }
    
    function creatorVVcurrentBalanceUpdate(address _creatorVestingVault) public {
        ICreatorVestingVault(_creatorVestingVault).currentBalanceUpdate();
    }
    
    function creatorVVMinimumCreatorBalance(address _creatorVestingVault) public view returns(uint){
        return ICreatorVestingVault(_creatorVestingVault).minimumCreatorBalance();
    }
    
    function creatorVVRedeemedVestedTokens(address _creatorVestingVault, uint _amount) public {
        ICreatorVestingVault(_creatorVestingVault).redeemedVestedTokens(_amount);
    }

    ////////////////////////////////////////
    // ***** Creator Token functions**** //
    //////////////////////////////////////
    
    function creatorTokenCreator(address ctoken) public view returns (address){
        return ICreatorToken(ctoken).creator();
    }

    function voteCount(address ctoken, uint choice) public view returns(uint){
        return ICreatorToken(ctoken).voteCount(choice);
    }

    function votersTokenCount(address ctoken, uint choice) public view returns(uint){
        return ICreatorToken(ctoken).votersTokenCount(choice);
    }

    function migrationContractPassed(address ctoken) public view returns(bool){
        return ICreatorToken(ctoken).migrationContractPassed();
    }

    //////////////////////////////////////
    // ***** Creator NFT functions**** //
    ////////////////////////////////////
    
    function creatorNFTCreator(address cnft) public view returns (address){
        return ICreatorNFT(cnft).creator();
    }
    
    //////////////////////////////////////
    // ***** Creator DAO functions**** //
    ////////////////////////////////////

    function daoCreator(address cdao) public view returns(address){
        return ICreatorDAO(cdao).creator();
    }

    function daoToken(address cdao) public view returns(address){
        return ICreatorDAO(cdao).token();
    }

    function daoVault(address cdao) public view returns(address){
        return ICreatorDAO(cdao).vault();
    }

    function daoProposals(address cdao) public view returns(uint){
        return ICreatorDAO(cdao).proposals();
    }

    function daoBalance(address cdao) public view returns(uint){
        return ICreatorDAO(cdao).Balance();
    }

    function daoAirdropApprovedAmount(address cdao) public view returns(uint){
        return ICreatorDAO(cdao).airdropApprovedAmount();
    }

    function daoFLOApprovedAmount(address cdao) public view returns(uint){
        return ICreatorDAO(cdao).FLOApprovedAmount();
    }

    function daoAllowances(address cdao, address member) public view returns(uint){
        return ICreatorDAO(cdao).allowances(member);
    }

    function daoProposedAirdropAmount(address cdao) public view returns(uint){
        return ICreatorDAO(cdao).proposedAirdropAmount();
    }

    function daoProposedFLOAmount(address cdao) public view returns(uint){
        return ICreatorDAO(cdao).proposedFLOAmount();
    }

    function daoVotingDuration(address cdao) public view returns(uint){
        return ICreatorDAO(cdao).votingDuration();
    }

    function daoCommunityManagers(address cdao, uint index) public view returns(address){
        return ICreatorDAO(cdao).communityManagers(index);
    }

    function daoAirdropProposalIds(address cdao, uint index) public view returns(uint){
        return ICreatorDAO(cdao).airdropProposalIds(index);
    }

    function daoFLOProposalIds(address cdao, uint index) public view returns(uint){
        return ICreatorDAO(cdao).FLOProposalIds(index);
    }

    function daoAllowancesProposalIds(address cdao, uint index) public view returns(uint){
        return ICreatorDAO(cdao).allowancesProposalIds(index);
    }

    function daoProposal(address cdao, uint proposalId) public view returns(address, string memory, uint, uint) {
        return ICreatorDAO(cdao).proposal(proposalId);
    }

    function daoProposalManagerAllowancesInfoLength(address cdao, uint proposalId) public view returns(uint) {
        return ICreatorDAO(cdao).proposalManagerAllowancesInfoLength(proposalId);
    }

    function daoProposalManagerAllowanesInfo(address cdao, uint proposalId, uint index) public view returns(address, uint) {
        return ICreatorDAO(cdao).proposalManagerAllowanesInfo(proposalId, index);
    }

    function daoProposalVoteDataInfo(address cdao, uint proposalId, uint choice) public view returns(uint, uint) {
        return ICreatorDAO(cdao).proposalVoteDataInfo(proposalId, choice);
    }

    function daoProposalStatus(address cdao, uint proposalId) public view returns(uint){
        return ICreatorDAO(cdao).proposalStatus(proposalId);
    }

    function daoCommunityManagerExists(address cdao, address manager) public view returns(bool){
        return ICreatorDAO(cdao).CommunityManagerExists(manager);
    }

    function daoCurrentBalanceUpdate(address cdao) public {
        ICreatorDAO(cdao).currentBalanceUpdate();
    }

    function daoUpdateAirdropApprovedAmount(address cdao) public {
        ICreatorDAO(cdao).updateAirdropApprovedAmount();
    }

    function daoUpdateFLOApprovedAmount(address cdao) public {
        ICreatorDAO(cdao).updateFLOApprovedAmount();
    }

    function daoUpdateManagerAllowances(address cdao, uint proposalId) public {
        ICreatorDAO(cdao).updateManagerAllowances(proposalId);
    }

    function sendAllowances(address cdao, address[] memory members, uint[] memory amount) public {
        ICreatorDAO(cdao).sendAllowances(members,amount);
    }

}