// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import "./interfaces/ICreatorToken.sol";
import "./interfaces/IXeldoradoVault.sol";
import "./interfaces/IXeldoradoCreatorFactory.sol";
import "./interfaces/IXeldoradoFactory.sol";
import "./interfaces/ICreatorDAO.sol";
import "./interfaces/IERC20X.sol";
import "./libraries/SafeMath.sol";

// 3 main categories of proposals
// Airdrop proposal
// AddFLO proposal
// Allowances proposal
// and
// General purpose proposal

contract CreatorDAO is ICreatorDAO{
    using SafeMath  for uint;

    address public override creator;
    address public override token;
    address public override vault;
    uint public override airdropApprovedAmount;
    uint public override FLOApprovedAmount;
    mapping(address=>uint) public override allowances; 
    uint public override proposedAirdropAmount;
    uint public override proposedFLOAmount;
    uint public override proposals;
    uint public override Balance;
    uint public override votingDuration; //time in seconds
    
    address[] public override communityManagers; 
    uint[] public override airdropProposalIds;
    uint[] public override FLOProposalIds;
    uint[] public override allowancesProposalIds; 
    uint public override TotalAllowances;

    struct generalProposalData{
        uint choices;
        address proposer;
        string link;
        uint startTimeStamp;
        uint category;

        // required in case of Allowances for managers
        address[] managers;
        mapping(address=>uint) proposedAllowancesAmount;
    }

    struct proposalVoteData {
        // for airdrop, FLO and allowances 1: for No and 2: for Yes
        // mapping starts from 1
        mapping(uint=>uint) voteCount;
        mapping(uint=>uint) votersTokenCount;

        mapping(address=>uint) voterValue; // for a voter 0: not voted, further integer value as per choices 
    }

    mapping(uint=>generalProposalData) proposalIdToProposalData;
    mapping(uint=>proposalVoteData) proposalIdToProposalVoteData;

    uint unlocked; 
    address creatorfactory;

    modifier lock() {
        require(unlocked == 1, 'Xeldorado: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    // not needed
    // modifier onlyCreator() {
    //     require(msg.sender==creator,'Xeldorado: only creator');
    //     _;
    // }

    // modifier onlyManagers() {
    //     require(CommunityManagerExists(msg.sender),'Xeldorado: only creator');
    //     _;
    // }

    modifier onlyCreatorOrAdmins() {
        require(msg.sender==creator || IXeldoradoCreatorFactory(creatorfactory).isCreatorAdmin(creator, msg.sender),'Xeldorado: only creator or admins');
        _;
    }

    modifier onlyHolders() {
        require(IERC20X(token).balanceOf(msg.sender)>0 || msg.sender==creator,'Xeldorado: Only holders'); //in case creator might have no tokens
        _;
    }

    modifier notVoted(uint proposalId) {
        require(proposalIdToProposalVoteData[proposalId].voterValue[msg.sender]==0,'Xeldorado: already voted');
        _;
    }

    // use to ensure voting is ongoing for a proposal
    modifier votingOver(uint proposalId) {
        require(block.timestamp.sub(proposalIdToProposalData[proposalId].startTimeStamp).div(votingDuration)<1,'Xeldorado: voting duration over');
        _;
    } 

    // use to ensure voting is complete for a proposal
    modifier votingNotOver(uint proposalId) {
        require(block.timestamp.sub(proposalIdToProposalData[proposalId].startTimeStamp).div(votingDuration)>1,'Xeldorado: voting duration not over');
        _;
    } 

    // use to ensure TotalBalance of DAO >= airdroppedApprovedAmount + FLOApprovedAmount + Sum(Allowances)
    modifier checkBalanceOverFlow(){
        _;
        require(Balance>=airdropApprovedAmount.add(FLOApprovedAmount).add(TotalAllowances),'Xeldorado: Approved Amount OverfLow');
    }

    constructor(address _creatorfactory, uint _votingDuration) {
        creator = msg.sender; // Creator
        unlocked = 1;
        creatorfactory = _creatorfactory;
        proposals = 0;
        votingDuration = _votingDuration; // in seconds
    }

    function CommunityManagerExists(address manager) public virtual override view returns(bool){
        for(uint i;i<communityManagers.length;i++){
            if(manager==communityManagers[i]){
                return true;
            }
        }
        return false;
    }

    function initialise(address _token, address _vault) public virtual override {
        require(msg.sender==creatorfactory,'Xeldorado: only creator factory');
        token = _token;
        vault = _vault;
        currentBalanceUpdate();
    }

    function proposal(uint proposalId) public virtual override view returns(address, string memory, uint, uint){
        return (proposalIdToProposalData[proposalId].proposer, proposalIdToProposalData[proposalId].link, proposalIdToProposalData[proposalId].category, proposalIdToProposalData[proposalId].choices);
    }

    function proposalManagerAllowancesInfoLength(uint proposalId) public virtual override view returns(uint) {
        return proposalIdToProposalData[proposalId].managers.length;
    }

    function proposalManagerAllowanesInfo(uint proposalId, uint index) public virtual override view returns(address manager, uint amount) {
        manager = proposalIdToProposalData[proposalId].managers[index];
        amount = proposalIdToProposalData[proposalId].proposedAllowancesAmount[manager];
    }

    function proposalVoteDataInfo(uint proposalId, uint choice) public virtual override view returns(uint, uint){
        return (proposalIdToProposalVoteData[proposalId].voteCount[choice], proposalIdToProposalVoteData[proposalId].votersTokenCount[choice]);
    }

    function currentBalanceUpdate() public virtual override {
        Balance = IERC20X(token).balanceOf(address(this));
    }

    // only vault can call
    function updateVaultAddress(address _newVaut) public virtual override {
        require(msg.sender==vault, 'Xeldorado: only vault can update');
        vault=_newVaut;
    }

    // only creator oe admins can call
    // check if manager already exists first before calling
    function addCommunityManager(address[] memory managers) public virtual override onlyCreatorOrAdmins {
        for(uint i;i<managers.length;i++)
        {
            communityManagers.push(managers[i]);
            emit managerAdded(address(this), managers[i]);
        }
    }

    // only creator oe admins can call
    // use only one at a time
    function removeCommunityManager(uint index) public virtual override onlyCreatorOrAdmins lock {
        emit managerRemoved(address(this), communityManagers[index]);
        communityManagers[index] = communityManagers[communityManagers.length-1];
        communityManagers.pop();
    }

    // only creator oe admins can call
    function updateVotingDuration(uint _votingDuration) public virtual override onlyCreatorOrAdmins lock {
        votingDuration = _votingDuration;
    }

    //only holders can call
    function airdropProposal(uint amount) public virtual override onlyHolders lock {
        proposalIdToProposalData[proposals].proposer = msg.sender;
        proposalIdToProposalData[proposals].category = 0;
        proposalIdToProposalData[proposals].choices = 2;
        proposalIdToProposalData[proposals].startTimeStamp = block.timestamp;
        proposedAirdropAmount = amount;
        airdropProposalIds.push(proposals);
        proposals+=1;
        emit proposalCreated(0, address(this), msg.sender, proposals-1);
    }

    //only holders can call
    function FLOProposal(uint amount) public virtual override onlyHolders lock {
        proposalIdToProposalData[proposals].proposer = msg.sender;
        proposalIdToProposalData[proposals].category = 1;
        proposalIdToProposalData[proposals].choices = 2;
        proposalIdToProposalData[proposals].startTimeStamp = block.timestamp;
        proposedFLOAmount = amount;
        FLOProposalIds.push(proposals);
        proposals+=1;
        emit proposalCreated(1, address(this), msg.sender, proposals-1);
    }

    //only holders can call
    // it allows multiple members for different allowances amount in same proposal 
    // for this proposedAllowancesAmount  for a member is shifted to generalProposalData
    function allowancesProposal(uint[] memory amount, address[] memory managers) public virtual override onlyHolders lock {
        require(managers.length==amount.length,'Xeldorado: unbalanced array');
        proposalIdToProposalData[proposals].proposer = msg.sender;
        proposalIdToProposalData[proposals].category = 2;
        proposalIdToProposalData[proposals].choices = 2;
        for(uint i;i<managers.length;i++)
        {
            proposalIdToProposalData[proposals].managers.push(managers[i]);
            proposalIdToProposalData[proposals].proposedAllowancesAmount[managers[i]] = amount[i];
        }
        proposalIdToProposalData[proposals].startTimeStamp = block.timestamp;
        allowancesProposalIds.push(proposals);
        proposals+=1;
        emit proposalCreated(2, address(this), msg.sender, proposals-1);
    }

    //only holders can call
    function generalProposal(string memory linkToProposal, uint _choices) public virtual override onlyHolders lock {
        proposalIdToProposalData[proposals].proposer = msg.sender;
        proposalIdToProposalData[proposals].category = 3;
        proposalIdToProposalData[proposals].link = linkToProposal;
        proposalIdToProposalData[proposals].choices = _choices;
        proposalIdToProposalData[proposals].startTimeStamp = block.timestamp;
        proposals+=1;
        emit proposalCreated(3, address(this), msg.sender, proposals-1);
    }

    // only holders can call
    // works for all 4 categories of proposal: Airdrop, AddFLO, Allowances, General Purpose
    // for Airdrop, AddFLO, Allowances: 1: no and 2: yes
    function generalProposalVote(uint proposalId, uint choice) public virtual override votingOver(proposalId) onlyHolders notVoted(proposalId) lock {
        require(choice>=1 && choice<=proposalIdToProposalData[proposalId].choices,'Xeldorado: out of choice');
        proposalIdToProposalVoteData[proposalId].voterValue[msg.sender] = choice;
        proposalIdToProposalVoteData[proposalId].voteCount[choice] += 1;
        proposalIdToProposalVoteData[proposalId].votersTokenCount[choice] += IERC20X(token).balanceOf(msg.sender);
    }

    // although we do count number of voters for a choice ultimately voterTokenCount is considered
    function proposalStatus(uint proposalId) public virtual override view returns(uint choice){
        uint choices = proposalIdToProposalData[proposalId].choices;
        choice = 1;
        uint vtc = proposalIdToProposalVoteData[proposalId].votersTokenCount[1];
        for(uint i=2;i<=choices;i++){
            if(vtc < proposalIdToProposalVoteData[proposalId].votersTokenCount[i]){
                choice = i;
                vtc = proposalIdToProposalVoteData[proposalId].votersTokenCount[i];
            }
        }
    }

    // update airdrop approved amount
    // anyone can call
    function updateAirdropApprovedAmount() public virtual override votingNotOver(airdropProposalIds[airdropProposalIds.length.sub(1)]) lock checkBalanceOverFlow {
        require(proposalStatus(airdropProposalIds[airdropProposalIds.length.sub(1)])==2,'Xeldorado: proposal not passed');
        airdropApprovedAmount += proposedAirdropAmount;
        proposedAirdropAmount=0;
    }

    // update FLO approved amount
    // anyone can call
    function updateFLOApprovedAmount() public virtual override votingNotOver(FLOProposalIds[FLOProposalIds.length.sub(1)]) lock checkBalanceOverFlow{
        require(proposalStatus(FLOProposalIds[FLOProposalIds.length.sub(1)])==2,'Xeldorado: proposal not passed');
        FLOApprovedAmount += proposedFLOAmount;
        proposedFLOAmount=0;
    }

    // update grant approved amount
    // anyone can call
    // proposalId needed 
    // single proposal can have allowancs updates for multiple managers
    // single manager can be granted amounts in different proposals 
    // hence allowances for a manager get incremented 
    // indicating total amount the granted manager can redeem or further allocate to a resource
    function updateManagerAllowances(uint proposalId) public virtual override votingNotOver(proposalId) lock checkBalanceOverFlow {
        require(proposalStatus(proposalId)==2,'Xeldorado: proposal not passed');
        uint manCount = proposalIdToProposalData[proposalId].managers.length;
        for(uint i;i<manCount;i++)
        {
            allowances[proposalIdToProposalData[proposalId].managers[i]] += proposalIdToProposalData[proposalId].proposedAllowancesAmount[proposalIdToProposalData[proposalId].managers[i]];
            TotalAllowances += proposalIdToProposalData[proposalId].proposedAllowancesAmount[proposalIdToProposalData[proposalId].managers[i]];
            emit allowancesUpdated(address(this), address(this) ,proposalIdToProposalData[proposalId].managers[i], proposalIdToProposalData[proposalId].proposedAllowancesAmount[proposalIdToProposalData[proposalId].managers[i]]);
            proposalIdToProposalData[proposalId].proposedAllowancesAmount[proposalIdToProposalData[proposalId].managers[i]]=0;
        }
    }

    // msg.sender's allowances will be deducted to add allowances to _to[]
    // managers who have been voted to get allowances can transfer their allowances to folks they employ
    // TotalAllowances will remain same just shuffle inside Allowances mapping
    function setAllowances(address[] memory _to, uint[] memory _amount) public virtual override lock {
        for(uint i;i<_amount.length;i++){
            require(_amount[i]<allowances[msg.sender],'Xeldorado: not enough allowances');
            allowances[msg.sender] -= _amount[i];
            allowances[_to[i]] += _amount[i];
            emit allowancesUpdated(address(this), msg.sender, _to[i], _amount[i]);
        }
    }

    // only creator or admins can call
    // tested for 1200 members in one go but can try even further
    function airdrop(uint amount, address[] memory members) public virtual override onlyCreatorOrAdmins lock {
        if(IXeldoradoVault(IXeldoradoCreatorFactory(creatorfactory).creatorVault(creator)).startliquidfill() >= 3) {
            require(amount.mul(members.length) <= airdropApprovedAmount,'Xeldorado: amount exceeds airdrop approval');
        }

        for(uint i;i<members.length;i++){
            require(IERC20X(token).transfer(members[i], amount),'Xeldorado: airdrop transfer failed');
            emit Airdropped(creator, amount, members[i]);
        }

        // although lock ensures no reentrancy but still place after transfer for safety instead of placing in the if statement above
        if(IXeldoradoVault(IXeldoradoCreatorFactory(creatorfactory).creatorVault(creator)).startliquidfill() >= 3) {
            airdropApprovedAmount -= amount.mul(members.length);
        }

        currentBalanceUpdate();
    }

    // only vault can call
    function addBalanceToVault(uint amount) public virtual override {
        require(msg.sender==vault,'Xeldorado: only vault allowed');
        require(amount <= FLOApprovedAmount,'Xeldorado: not adequate FLO balance');
        IERC20X(token).transfer(vault,amount);
        FLOApprovedAmount-=amount;
        currentBalanceUpdate();
        emit AmountAddedToVault(creator, amount);
    }

    // batch send allowances
    function sendAllowances(address[] memory members, uint[] memory amount) public virtual override lock {
        require(members.length==amount.length,'Xeldorado: unbalanced array');
        for(uint i;i<members.length;i++)
        {
            require(amount[i] <= allowances[members[i]], 'Xeldorado: amount exceeds grant');
            require(IERC20X(token).transfer(members[i], amount[i]), 'Xeldorado: grant transfer failed');
            allowances[members[i]] -= amount[i];
            TotalAllowances -= amount[i];
            emit allowancesRedeemed(creator, amount[i], members[i]);
        }
        currentBalanceUpdate();
    }

    // only allowance receving member can call
    function redeemAllowances(uint amount) public virtual override lock {
        require(amount <= allowances[msg.sender], 'Xeldorado: amount exceeds grant');
        require(IERC20X(token).transfer(msg.sender, amount), 'Xeldorado: grant transfer failed');
        allowances[msg.sender] -= amount;
        currentBalanceUpdate();
        TotalAllowances -= amount;
        emit allowancesRedeemed(creator, amount, msg.sender);
    }
    
    // only migration contract can call
    function migrateDAO(address toContract) public virtual override {
        bool votingPassed = ICreatorToken(token).migrationContractPassed();
        uint votingPhase = ICreatorToken(token).votingPhase();
        require((msg.sender == IXeldoradoFactory(IXeldoradoVault(vault).factory()).migrationContract() && votingPassed && votingPhase == 0 && (ICreatorToken(token).migrationContract() == IXeldoradoFactory(IXeldoradoVault(vault).factory()).migrationContract())), 'Xeldorado: only migrator allowed after creator approves migration and voting success and migration contract match with voted one');
        IERC20X(token).transfer(toContract, IERC20X(token).balanceOf(address(this)));
        currentBalanceUpdate();

        // update DAO address for all dependent contract
        IXeldoradoCreatorFactory(creatorfactory).updateCreatorDAOForMigration(creator, toContract);
        IXeldoradoVault(vault).updateCreatorDAO(toContract);
        emit migrationDAOCompleted(toContract);
    }

}