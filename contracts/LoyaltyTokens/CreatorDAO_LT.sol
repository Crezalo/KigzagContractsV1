// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import "./interfaces/ICreatorToken_LT.sol";
import "./interfaces/IXeldoradoCreatorFactory_LT.sol";
import "./interfaces/ICreatorDAO_LT.sol";
import "../libraries/SafeMath.sol";

// 2 categories of proposals
// Allowances proposal
// General purpose proposal

contract CreatorDAO_LT is ICreatorDAO_LT{
    using SafeMath  for uint;

    address public override creator;
    address public override token;
    address public override basetoken;
    mapping(address=>uint) public override allowances; 
    uint public override proposals;
    uint public override tokenBalance;
    uint public override baseTokenBalance;
    uint public override votingDuration; //time in seconds
    
    address[] public override communityManagers; 
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
        // for allowances 1: for No and 2: for Yes
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

    modifier onlyCreatorOrAdmins() {
        require(msg.sender==creator || IXeldoradoCreatorFactory_LT(creatorfactory).isCreatorAdmin(creator, msg.sender),'Xeldorado: only creator or admins');
        _;
    }

    modifier onlyHolders() {
        require(IERC20(token).balanceOf(msg.sender)>0 || msg.sender==creator,'Xeldorado: Only holders'); //in case creator might have no tokens
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

    // use to ensure TotalBalance of DAO >= Sum(Allowances)
    modifier checkBalanceOverFlow(){
        _;
        require(baseTokenBalance>=TotalAllowances,'Xeldorado: Approved Amount OverfLow');
    }

    constructor(address _creator, uint _votingDuration, address _token, address _basetoken) {
        creatorfactory = msg.sender; // CreatorFactory deploys
        creator = _creator; 
        unlocked = 1;
        proposals = 0;
        votingDuration = _votingDuration; // in seconds
        token = _token;
        basetoken = _basetoken;
        currentBalanceUpdate();
    }

    function CommunityManagerExists(address manager) public virtual override view returns(bool){
        for(uint i;i<communityManagers.length;i++){
            if(manager==communityManagers[i]){
                return true;
            }
        }
        return false;
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
        tokenBalance = IERC20(token).balanceOf(address(this));
        baseTokenBalance = IERC20(basetoken).balanceOf(address(this));
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

    // only creator or admins can call
    // tested for 1200 members in one go but can try even further
    function airdrop(uint amount, address[] memory members) public virtual override onlyCreatorOrAdmins lock {
        for(uint i;i<members.length;i++){
            ICreatorToken_LT(token).mintTokens(members[i], amount);
            emit Airdropped(creator, amount, members[i]);
        }
        currentBalanceUpdate();
    }

    //only holders can call
    // it allows multiple members for different allowances amount in same proposal 
    // for this proposedAllowancesAmount  for a member is shifted to generalProposalData
    // allowances will happen in base tokens
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
    // works for all 2 categories of proposal: Allowances, General Purpose
    // for Allowances: 1: no and 2: yes
    function generalProposalVote(uint proposalId, uint choice) public virtual override votingOver(proposalId) onlyHolders notVoted(proposalId) lock {
        require(choice>=1 && choice<=proposalIdToProposalData[proposalId].choices,'Xeldorado: out of choice');
        proposalIdToProposalVoteData[proposalId].voterValue[msg.sender] = choice;
        proposalIdToProposalVoteData[proposalId].voteCount[choice] += 1;
        proposalIdToProposalVoteData[proposalId].votersTokenCount[choice] += IERC20(token).balanceOf(msg.sender);
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

    // batch send allowances
    function sendAllowances(address[] memory members, uint[] memory amount) public virtual override lock {
        require(members.length==amount.length,'Xeldorado: unbalanced array');
        for(uint i;i<members.length;i++)
        {
            require(amount[i] <= allowances[members[i]], 'Xeldorado: amount exceeds grant');
            require(IERC20(basetoken).transfer(members[i], amount[i]), 'Xeldorado: grant transfer failed');
            allowances[members[i]] -= amount[i];
            TotalAllowances -= amount[i];
            emit allowancesRedeemed(creator, amount[i], members[i]);
        }
        currentBalanceUpdate();
    }

    // only allowance receving member can call
    function redeemAllowances(uint amount) public virtual override lock {
        require(amount <= allowances[msg.sender], 'Xeldorado: amount exceeds grant');
        require(IERC20(basetoken).transfer(msg.sender, amount), 'Xeldorado: grant transfer failed');
        allowances[msg.sender] -= amount;
        currentBalanceUpdate();
        TotalAllowances -= amount;
        emit allowancesRedeemed(creator, amount, msg.sender);
    }
}