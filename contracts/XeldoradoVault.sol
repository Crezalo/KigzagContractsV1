// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import './CreatorNFT.sol';
import './interfaces/IERC20X.sol';
import './interfaces/ICreatorToken.sol';
import './interfaces/IXeldoradoVault.sol';
import './interfaces/IXeldoradoFactory.sol';
import './interfaces/IXeldoradoCreatorFactory.sol';
import './interfaces/IXeldoradoPair.sol';
import './interfaces/ICreatorVestingVault.sol';
import './interfaces/ICreatorDAO.sol';
import './libraries/SafeMath.sol';

contract XeldoradoVault is IXeldoradoVault{
    using SafeMath  for uint;
    
    address public override creator;
    address public override creatorDAO;
    address public override token;
    address public override basetoken;
    uint256 private liquidityFillStartTime;
    mapping(uint=>address) public override vaultIdTonftContract;    
    mapping(uint=>uint) public override vaultIdToTokenId;
    uint public override allNFTs;
    // uint[] public override redeemedNFTs;
    uint public override allRedeemedNFTs;
    uint public override minpriceofbasetoken;
    address public override pair;
    
    uint public override startliquidfill;
    CreatorNFT private nftcontract;
    address public override nftContract;
    uint public override initialBalance;
    uint public override FLOBalance;
    
    uint private unlocked;
    uint public override ICTOduration; // in seconds
    address public override factory;
    bool public override dependenciesUpdated;

    address creatorfactory;
    
    modifier lock() {
        require(unlocked == 1, 'Xeldorado: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    modifier ishaltTrading() {
        require(IXeldoradoFactory(factory).haltAllPairsTrading() != true ,'Xeldorado: trading is halted for all pairs');
        _;
    }

    // modifier onlyCreator() {
    //     require(msg.sender==creator,'Xeldorado: only creator');
    //     _;
    // }

    modifier onlyCreatorOrAdmins() {
        require(msg.sender==creator || IXeldoradoCreatorFactory(creatorfactory).isCreatorAdmin(creator, msg.sender),'Xeldorado: only creator or admins');
        _;
    }
    
    constructor(string memory _name, string memory _symbol){
        creator = msg.sender; // Creator
        startliquidfill = 0;
        allNFTs=0;
        unlocked = 1;
        nftcontract = new CreatorNFT(creator,_name,_symbol);
        nftContract = address(nftcontract);
    }
    
    function initialize(address _token, address _creatorDAO) public virtual override {
        require(token==address(0),'Xeldorado: initialised');
        creatorfactory = msg.sender; // function called via creator factory
        token = _token;
        creatorDAO = _creatorDAO;
        initialBalance = IERC20X(token).balanceOf(address(this));
    }
    
    // only pair can call
    function updatePair(address toContract) public virtual override {
        require(msg.sender==pair, 'Xeldorado: only pair can update');
        pair = toContract;
    }
    
    // only DAO can call
    function updateCreatorDAO(address toContract) public virtual override {
        require(msg.sender==creatorDAO, 'Xeldorado: only DAO can update');
        creatorDAO = toContract;
    }

    // only creator or admins can call
    function addMintedNFTToVault(address[] memory _nftContracts, uint[] memory _tokenIds) public virtual override onlyCreatorOrAdmins lock {
        require(_nftContracts.length == _tokenIds.length, 'Xeldorado: unbalanced input'); // at a given index nftcontract and tokenid defines an NFT
        
        uint singlenftprice;

        if(startliquidfill>0)
        { 
            singlenftprice = singleNFTPrice();
        }
        
        for(uint i;i<_nftContracts.length;i++)
        {
            IERC721(_nftContracts[i]).transferFrom(creator, address(this), _tokenIds[i]);
            vaultIdTonftContract[allNFTs] = _nftContracts[i];
            vaultIdToTokenId[allNFTs] = _tokenIds[i];
            allNFTs +=  1;
            emit NFTadded(vaultIdTonftContract[allNFTs-1], vaultIdToTokenId[allNFTs-1]);
        }
        
        if(startliquidfill>0)
        {
            ICreatorToken(token).mintTokens(creatorDAO, singlenftprice.mul(_nftContracts.length));
            ICreatorDAO(creatorDAO).currentBalanceUpdate();
        }
    }
    
    // only creator or admins can call

    function mintNFTUsingVaultContract(string[] memory _tokenURI) public virtual override onlyCreatorOrAdmins lock {
        (uint start, uint end) = nftcontract.createBatchToken(_tokenURI, address(this));
        
        uint singlenftprice;
        
        if(startliquidfill>0)
        { 
            singlenftprice = singleNFTPrice();
        }
        
        for(uint i;i<end-start+1;i++)
        {
            vaultIdTonftContract[allNFTs] = address(nftcontract);
            vaultIdToTokenId[allNFTs] = start+i;
            allNFTs +=  1;
            emit NFTadded(vaultIdTonftContract[allNFTs-1], vaultIdToTokenId[allNFTs-1]);
        }
        
        if(startliquidfill>0)
        {
            ICreatorToken(token).mintTokens(creatorDAO, singlenftprice.mul(end-start+1));
            ICreatorDAO(creatorDAO).currentBalanceUpdate();
        }
    }
    
    function singleNFTPrice() public virtual override view returns(uint){
        return (IERC20X(token).totalSupply() / (allNFTs.sub(allRedeemedNFTs)));
    }

    // function _exist(uint[] memory _array, uint _vaultId) internal pure returns (bool){
    //     for(uint i; i < _array.length;i++){
    //         if (_array[i]==_vaultId) return true;
    //     }
    //     return false;
    // }
      
    function calculateFee(uint amount, uint fee) internal pure returns (uint) {
        // fee percent in scale of 10000
        return amount.mul(fee)/10000;
    }
    
    function redeemNFT(address _to, uint[] memory _vaultIds) public virtual override ishaltTrading lock {
        // get approval
        
        uint singlenftprice = singleNFTPrice();
        
        for(uint i;i<_vaultIds.length;i++)
        {
            // require(_exist(redeemedNFTs, _vaultIds[i]) == false, 'Xeldorado: Already reedemed!');
            require(IERC721(vaultIdTonftContract[_vaultIds[i]]).ownerOf(vaultIdToTokenId[_vaultIds[i]]) == address(this), 'Xeldorado: Already reedemed!');
            
            IERC721(vaultIdTonftContract[_vaultIds[i]]).transferFrom(address(this), _to, vaultIdToTokenId[_vaultIds[i]]);
            
            allRedeemedNFTs += 1;
            emit NFTRedeemed(vaultIdTonftContract[_vaultIds[i]], vaultIdToTokenId[_vaultIds[i]]);
        }

        uint discount = 0;

        if(IXeldoradoFactory(factory).noOFTokensForDiscount() <= IERC20X(IXeldoradoFactory(factory).exchangeToken()).balanceOf(_to)) {
            discount = IXeldoradoFactory(factory).nftDiscount();
        }        

        // xfee - discount + cfee    
        uint totalFee = calculateFee(singlenftprice.mul(_vaultIds.length), IXeldoradoFactory(factory).nftFee().sub(discount).add(IXeldoradoCreatorFactory(creatorfactory).creatorNFTFee(creator))); 
        
        //burn creator tokens equivalent to n NFT + xfee - discount + cfee from _to address
        ICreatorToken(token).burnTokens(_to, (singlenftprice.mul(_vaultIds.length)).add(totalFee)); 
        
        //mint xfee - discount in creator token to feeTo
        ICreatorToken(token).mintTokens(IXeldoradoFactory(factory).feeTo(), calculateFee(singlenftprice.mul(_vaultIds.length), IXeldoradoFactory(factory).nftFee().sub(discount))); 
        
        //mint cfee in creator token to creator
        ICreatorToken(token).mintTokens(creator, calculateFee(singlenftprice.mul(_vaultIds.length), IXeldoradoCreatorFactory(creatorfactory).creatorNFTFee(creator))); 
    }
    
    // function _findIndexOfVaultIdInRedeemendNFTArray(uint _vaultId) internal view returns(uint){
    //     for(uint k=0;k<redeemedNFTs.length;k++){
    //         if(redeemedNFTs[k]==_vaultId){
    //             return k;
    //         }
    //     }
        
    //     return 10**18;
    // }
    
    // function _removeRedeemedNFTfromArray(uint index) internal {
    //   require(index < redeemedNFTs.length);
    //   redeemedNFTs[index] = redeemedNFTs[redeemedNFTs.length-1];
    //   redeemedNFTs.pop();
    // }
    
    function returnOfRedeemedNFT(address _to, uint[] memory _vaultIds) public virtual override ishaltTrading lock {
        // get approval
        
        uint singlenftprice = singleNFTPrice();
        
        for(uint i;i<_vaultIds.length;i++)
        {
            // uint _redeemedNFTid = _findIndexOfVaultIdInRedeemendNFTArray(_vaultIds[i]);
            // require(_redeemedNFTid != 10**18, 'Xeldorado: invalid vaultid');
            IERC721(vaultIdTonftContract[_vaultIds[i]]).transferFrom(_to, address(this), vaultIdToTokenId[_vaultIds[i]]);
            
            // _removeRedeemedNFTfromArray(_redeemedNFTid);
            allRedeemedNFTs -= 1;
            emit NFTReturned(_to, _vaultIds[i]);
        }

        uint discount = 0;

        if(IXeldoradoFactory(factory).noOFTokensForDiscount() <= IERC20X(IXeldoradoFactory(factory).exchangeToken()).balanceOf(_to)) {
            discount = IXeldoradoFactory(factory).nftDiscount();
        }        

        // xfee - discount + cfee
        uint totalFee = calculateFee(singlenftprice.mul(_vaultIds.length), IXeldoradoFactory(factory).nftFee().sub(discount).add(IXeldoradoCreatorFactory(creatorfactory).creatorNFTFee(creator))); 
        
        // mint creator tokens to to
        ICreatorToken(token).mintTokens(_to, (singlenftprice.mul(_vaultIds.length)).sub(totalFee)); 

        //mint xfee in creator token to feeTo
        ICreatorToken(token).mintTokens(IXeldoradoFactory(factory).feeTo(), calculateFee(singlenftprice.mul(_vaultIds.length), IXeldoradoFactory(factory).nftFee().sub(discount))); 

        //mint cfee in creator token to creator
        ICreatorToken(token).mintTokens(creator, calculateFee(singlenftprice.mul(_vaultIds.length), IXeldoradoCreatorFactory(creatorfactory).creatorNFTFee(creator))); 
    }

    // swap one NFT of this creator for another NFT of the same creator for no fees at all
    function swapNFT(address _swapper, uint[] memory _inVaultIds, uint[] memory _outVaultIds) public virtual override ishaltTrading lock {
        // get approval
        require(_inVaultIds.length == _outVaultIds.length ,'Xeldorado: unbalanced input output array');
        for(uint i;i<_inVaultIds.length;i++)
        {
            // uint _redeemedNFTid = _findIndexOfVaultIdInRedeemendNFTArray(_inVaultIds[i]);
            // require(_redeemedNFTid != 10**18, 'Xeldorado: invalid vaultid');
            IERC721(vaultIdTonftContract[_inVaultIds[i]]).transferFrom(_swapper, address(this), vaultIdToTokenId[_inVaultIds[i]]);
            // _removeRedeemedNFTfromArray(_redeemedNFTid);
            IERC721(vaultIdTonftContract[_outVaultIds[i]]).transferFrom(address(this), _swapper, vaultIdToTokenId[_outVaultIds[i]]);
            // redeemedNFTs.push(_outVaultIds[i]);
            emit NFTSwapped(_swapper, _inVaultIds[i], _outVaultIds[i]);
        }
    }
    
    // only creator or admins can call
    function initializeLiquidityOffering(address _basetoken, uint _minpriceofbasetoken, uint _sec) public virtual override onlyCreatorOrAdmins lock{
        require(startliquidfill == 0, 'Xeldorado: liquidity offering already initialized.');
        require(allNFTs > 0, 'Xeldorado: add atleast one NFT before ICTO');
        factory = IXeldoradoCreatorFactory(creatorfactory).factory();
        pair = IXeldoradoFactory(factory).createPair(token, _basetoken, creator);
        basetoken = _basetoken;
        minpriceofbasetoken = _minpriceofbasetoken;
        startliquidfill = startliquidfill + 1;
        liquidityFillStartTime = block.timestamp;
        ICTOduration = _sec;
        ICreatorVestingVault(IXeldoradoCreatorFactory(creatorfactory).creatorVestingVault(creator)).initialize(token, creator, IXeldoradoFactory(factory).VestingDuration());
        emit liquidityFillStarted(token,_basetoken,_minpriceofbasetoken);
    }
    
    // only creator or admins can call
    function addTokensForFLO(uint amount) public virtual override onlyCreatorOrAdmins ishaltTrading lock {
        require(startliquidfill%3 == 0 && startliquidfill > 0, 'Xeldorado: liquidity currently running or ICTO not happened');
        ICreatorDAO(creatorDAO).addBalanceToVault(amount);
        FLOBalance = amount;
    }
    
    // only creator or admins can call
    function initializeFurtherLiquidityOffering(uint _min) public virtual override onlyCreatorOrAdmins lock {
        require(startliquidfill%3 == 0 && startliquidfill > 0, 'Xeldorado: liquidity currently running or ICTO not happened');
        (uint ctreserve, uint btreserve, ) = IXeldoradoPair(pair).getReserves();
        minpriceofbasetoken = (btreserve * 10 ** 18)/ctreserve;
        startliquidfill = startliquidfill + 1;
        liquidityFillStartTime = block.timestamp;
        ICTOduration = _min;
        emit liquidityFillStarted(token,basetoken,minpriceofbasetoken);
    }
    
    // Eg If _minpriceofbasetoken = 7 * 10^16 and buyer bids for 1 CT = 0.1 WETH then _bidpriceofbasetoken = 10 ^ 17 
    function bidCreatorToken(address _buyer, uint _amount, uint _bidpriceofbasetoken) public virtual override ishaltTrading lock {
        // get approval
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
        uint discount = 0;

        if(IXeldoradoFactory(factory).noOFTokensForDiscount() <= IERC20X(IXeldoradoFactory(factory).exchangeToken()).balanceOf(_buyer))
        {
            discount = IXeldoradoFactory(factory).ictoDiscount();
        }
        require(minpriceofbasetoken <= _bidpriceofbasetoken, 'Xeldorado: please bid higher than min price');
        require(IERC20X(basetoken).transferFrom(_buyer, address(this), _amount.mul(_bidpriceofbasetoken)), 'Xeldorado: transfer 1 failed');
        require(IERC20X(token).transfer(_buyer,_amount.mul(10 ** 18)), 'Xeldorado: transfer 2 failed');
        
        //xfee to feeTo // scale of 10000 
        require(IERC20X(basetoken).transferFrom(_buyer, IXeldoradoFactory(factory).feeTo(),  calculateFee(_amount.mul(_bidpriceofbasetoken), IXeldoradoFactory(factory).ictoFee().sub(discount))), 'Xeldorado: xfee transfer fail');

        //cfee to creator // scale of 10000
        require(IERC20X(basetoken).transferFrom(_buyer, creator,  calculateFee(_amount.mul(_bidpriceofbasetoken), IXeldoradoCreatorFactory(creatorfactory).creatorCTOFee(creator))), 'Xeldorado: cfee transfer fail');
        
        emit biddingCreatorToken(_buyer, _amount, _bidpriceofbasetoken);
        endLiquidityFilling();
    }
    
    function viewLiquidityFiling() public virtual override view returns(uint percent){
        require(startliquidfill%3 == 1, 'Xeldorado: liquidity filling either not started or already done');
        uint tokenbalance = IERC20X(token).balanceOf(address(this));
        if(startliquidfill>3) return (FLOBalance.sub(tokenbalance).mul(20000)/FLOBalance);
        return (initialBalance.sub(tokenbalance).mul(20000)/initialBalance); // (InitialBalance - CurrentBalance )/(InitialBalance/2) on scale of 10000 so 97.58% = 9758
    }
    
    function endLiquidityFilling() public virtual override {
        if((block.timestamp.sub(liquidityFillStartTime)).div(ICTOduration) > 1 || viewLiquidityFiling() == 10000){
            if(startliquidfill>3) require(IERC20X(token).transfer(pair, FLOBalance.sub(IERC20X(token).balanceOf(address(this)))),'Xeldorado: creator token transfer to Pair failed');
            else require(IERC20X(token).transfer(pair, initialBalance.sub(IERC20X(token).balanceOf(address(this)))),'Xeldorado: transfer 3 failed');
            require(IERC20X(token).transfer(creatorDAO, IERC20X(token).balanceOf(address(this))),'Xeldorado: transfer 4 failed');
            ICreatorDAO(creatorDAO).currentBalanceUpdate();
            require(IERC20X(basetoken).transfer(pair,IERC20X(basetoken).balanceOf(address(this))),'Xeldorado: transfer 5 failed');
            startliquidfill = startliquidfill + 2;
            IXeldoradoPair(pair).LiquidityAdded();
            emit liquidityFillEnded(pair);
        }
    }
    
    // only creator or admins can call
    // creator must be a contract and approved via exchange using DirectTransferApprover
    // dont get into this because it will be difficult to answer whose tokens are getting burnt
    // this function was implemented to be used for gaming projects but after shifting to Creator Social Tokens it is redundant
    // function directTransferNFT(uint[] memory vaultIds, address _to) public virtual override onlyCreatorOrAdmins lock {
    //     require(IXeldoradoCreatorFactory(creatorfactory).creatorDirectTransferApproval(creator) == 2, 'Xeldorado: only qualified creator contracts');
    //     for(uint i;i<vaultIds.length;i++)
    //     {
    //         IERC721(vaultIdTonftContract[vaultIds[i]]).transferFrom(address(this), _to, vaultIdToTokenId[vaultIds[i]]);
    //         redeemedNFTs.push(vaultIds[i]);
    //         allRedeemedNFTs += 1;
    //         emit directTransferNFTCompleted(vaultIds[i], _to);
    //     }
    // }
    
    // only migration contract can call
    // function migrateVault(address toContract) public virtual override lock {
    //     bool votingPassed = ICreatorToken(token).migrationContractPassed();
    //     uint votingPhase = ICreatorToken(token).votingPhase();
    //     require((msg.sender == IXeldoradoFactory(factory).migrationContract() && votingPassed && votingPhase == 0 && (ICreatorToken(token).migrationContract() == IXeldoradoFactory(factory).migrationContract())), 'Xeldorado: only migrator allowed after voting success and migration contract match with voted one');
    //     for(uint i; i< allNFTs; i++){
    //         if(IERC721(vaultIdTonftContract[i]).ownerOf(vaultIdToTokenId[i])==address(this)){
    //             IERC721(vaultIdTonftContract[i]).transferFrom(address(this), toContract, vaultIdToTokenId[i]);
    //         }
    //     }

    //     // updating vault address for all dependent contracts
    //     ICreatorToken(token).updateVaultAddress(toContract);
    //     nftcontract.updateVaultAddress(toContract);
    //     ICreatorDAO(creatorDAO).updateVaultAddress(toContract);
    //     IXeldoradoCreatorFactory(creatorfactory).updateCreatorVaultForMigration(creator,toContract);
    //     dependenciesUpdated = true;
    //     emit migrationVaultCompleted(toContract);
    // }


    // only migration contract can call
    // in case the vault owns 1000k+ NFTs, migrateVault function may run out of gas and require migration of NFTs in multiple batches
    // for small number of NFTs pass start = 0 and end = 
    // start: vaultId of first NFT to tranfer in batch
    // end: vaultId of last NFT to tranfer in batch
    function migrateVaultBatchTransfer(address toContract, uint start, uint end) public virtual override lock {
        bool votingPassed = ICreatorToken(token).migrationContractPassed();
        uint votingPhase = ICreatorToken(token).votingPhase();
        require((msg.sender == IXeldoradoFactory(factory).migrationContract() && votingPassed && votingPhase == 0 && (ICreatorToken(token).migrationContract() == IXeldoradoFactory(factory).migrationContract())), 'Xeldorado: only migrator allowed after voting success and migration contract match with voted one');
        for(uint i=start; i <= end; i++){
            if(IERC721(vaultIdTonftContract[i]).ownerOf(vaultIdToTokenId[i])==address(this)){
                IERC721(vaultIdTonftContract[i]).transferFrom(address(this), toContract, vaultIdToTokenId[i]);
            }
        }

        if(!dependenciesUpdated)
        {
            // updating vault address for all dependent contracts
            ICreatorToken(token).updateVaultAddress(toContract);
            nftcontract.updateVaultAddress(toContract);
            ICreatorDAO(creatorDAO).updateVaultAddress(toContract);
            IXeldoradoCreatorFactory(creatorfactory).updateCreatorVaultForMigration(creator,toContract);
            dependenciesUpdated = true;
        }
        emit migrationVaultBatchCompleted(toContract,start,end);
    }
}