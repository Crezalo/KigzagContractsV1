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
    mapping(address=>uint) public override nativeTokenAllowances; 
    mapping(address=>uint) public override usdAllowances;
    uint public override proposals;
    uint public override nativeTokenBalance;
    uint public override usdBalance;
    uint public override votingDuration; //time in seconds
    
    address[] public override communityManagers; 
    uint[] public override allowancesProposalIds; 
    uint public override nativeTotalAllowances;
    uint public override usdTotalAllowances;

    struct generalProposalData{
        uint choices;
        address proposer;
        string link;
        uint startTimeStamp;
        uint category; // 1 for allowances  // 2 for general proposal

        // required in case of Allowances for managers
        bool nativeAllowance; // false for usd 
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
        require(block.timestamp.sub(proposalIdToProposalData[proposalId].startTimeStamp)<(votingDuration),'Xeldorado: voting duration over');
        _;
    } 

    // use to ensure voting is complete for a proposal
    modifier votingNotOver(uint proposalId) {
        require(block.timestamp.sub(proposalIdToProposalData[proposalId].startTimeStamp)>(votingDuration),'Xeldorado: voting duration not over');
        _;
    } 

    // use to ensure TotalBalance of DAO >= Sum(Allowances)
    modifier checkBalanceOverFlow(){
        _;
        require(nativeTokenBalance>=nativeTotalAllowances,'Xeldorado: Native Approved Amount OverfLow');
        require(usdBalance>=usdTotalAllowances,'Xeldorado: USD Approved Amount OverfLow');
    }

    constructor() {
        unlocked = 1;
        proposals = 0;
    }

    // only creator factory can initialise
    function initialise(address _creator, uint _votingDuration, address _token) public virtual override {
        require(token==address(0),'Xeldorado: initialised');
        creatorfactory = msg.sender; // function called via creator factory
        creator = _creator; 
        unlocked = 1;
        proposals = 0;
        votingDuration = _votingDuration; // in seconds
        token = _token;
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

    function proposalManagerAllowanesInfo(uint proposalId, uint index) public virtual override view returns(address manager, uint amount, bool nativeAllowance) {
        manager = proposalIdToProposalData[proposalId].managers[index];
        amount = proposalIdToProposalData[proposalId].proposedAllowancesAmount[manager];
        nativeAllowance = proposalIdToProposalData[proposalId].nativeAllowance;
    }

    function proposalVoteDataInfo(uint proposalId, uint choice) public virtual override view returns(uint, uint){
        return (proposalIdToProposalVoteData[proposalId].voteCount[choice], proposalIdToProposalVoteData[proposalId].votersTokenCount[choice]);
    }

    function currentBalanceUpdate() public virtual override {
        // balance of network/native token
        nativeTokenBalance = IERC20(IXeldoradoCreatorFactory_LT(creatorfactory).networkWrappedToken()).balanceOf(address(this));

        // balance of usdc + dai
        usdBalance = IERC20(IXeldoradoCreatorFactory_LT(creatorfactory).usdc()).balanceOf(address(this)).add(IERC20(IXeldoradoCreatorFactory_LT(creatorfactory).dai()).balanceOf(address(this)));
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

    // only holders can call
    // proposal can either be in USD or native token decided by _nativeAllowance
    // it allows multiple members for different allowances amount in same proposal 
    // for this proposedAllowancesAmount  for a member is shifted to generalProposalData
    // allowances will happen in base tokens
    function allowancesProposal(uint[] memory amount, address[] memory managers, bool _nativeAllowance) public virtual override onlyHolders lock {
        require(managers.length==amount.length,'Xeldorado: unbalanced array');
        proposalIdToProposalData[proposals].proposer = msg.sender;
        proposalIdToProposalData[proposals].category = 1;
        proposalIdToProposalData[proposals].choices = 2;
        proposalIdToProposalData[proposals].nativeAllowance = _nativeAllowance;
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
        proposalIdToProposalData[proposals].category = 2;
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
            if(proposalIdToProposalData[proposalId].nativeAllowance){
                nativeTokenAllowances[proposalIdToProposalData[proposalId].managers[i]] += proposalIdToProposalData[proposalId].proposedAllowancesAmount[proposalIdToProposalData[proposalId].managers[i]];
                nativeTotalAllowances += proposalIdToProposalData[proposalId].proposedAllowancesAmount[proposalIdToProposalData[proposalId].managers[i]];
            }
            else{
                usdAllowances[proposalIdToProposalData[proposalId].managers[i]] += proposalIdToProposalData[proposalId].proposedAllowancesAmount[proposalIdToProposalData[proposalId].managers[i]];
                usdTotalAllowances += proposalIdToProposalData[proposalId].proposedAllowancesAmount[proposalIdToProposalData[proposalId].managers[i]];
            }
            emit allowancesUpdated(address(this), address(this) ,proposalIdToProposalData[proposalId].managers[i], proposalIdToProposalData[proposalId].proposedAllowancesAmount[proposalIdToProposalData[proposalId].managers[i]], proposalIdToProposalData[proposalId].nativeAllowance);
            proposalIdToProposalData[proposalId].proposedAllowancesAmount[proposalIdToProposalData[proposalId].managers[i]]=0;
        }
    }

    // msg.sender's allowances will be deducted to add allowances to _to[]
    // managers who have been voted to get allowances can transfer their allowances to folks they employ
    // TotalAllowances will remain same just shuffle inside Allowances mapping
    function setAllowances(address[] memory _to, uint[] memory _amount, bool _nativeAllowance) public virtual override lock {
        for(uint i;i<_amount.length;i++){
            if(_nativeAllowance) {
                require(_amount[i]<nativeTokenAllowances[msg.sender],'Xeldorado: not enough allowances');
                nativeTokenAllowances[msg.sender] -= _amount[i];
                nativeTokenAllowances[_to[i]] += _amount[i];
            }
            else{
                require(_amount[i]<usdAllowances[msg.sender],'Xeldorado: not enough allowances');
                usdAllowances[msg.sender] -= _amount[i];
                usdAllowances[_to[i]] += _amount[i];
            }
            emit allowancesUpdated(address(this), msg.sender, _to[i], _amount[i], _nativeAllowance);
        }
    }

    // batch send allowances
    // tokenId -> 1 for nativeToken, 2 for usdc, 3 for dai
    function sendAllowances(address[] memory members, uint[] memory amount, uint[] memory tokenId) public virtual override lock {
        require(members.length==amount.length && amount.length==tokenId.length,'Xeldorado: unbalanced array');
        for(uint i;i<members.length;i++)
        {
            if(tokenId[i]==1){ // native token
                require(amount[i] <= nativeTokenAllowances[members[i]], 'Xeldorado: amount exceeds grant');
                require(IERC20(IXeldoradoCreatorFactory_LT(creatorfactory).networkWrappedToken()).transfer(members[i], amount[i]), 'Xeldorado: grant transfer failed');
                nativeTokenAllowances[members[i]] -= amount[i];
                nativeTotalAllowances -= amount[i];
            }
            else if(tokenId[i]==2){ // usdc
                require(amount[i] <= usdAllowances[members[i]], 'Xeldorado: amount exceeds grant');
                require(IERC20(IXeldoradoCreatorFactory_LT(creatorfactory).usdc()).transfer(members[i], amount[i]), 'Xeldorado: grant transfer failed');
                usdAllowances[members[i]] -= amount[i];
                usdTotalAllowances -= amount[i];
            }
            else if(tokenId[i]==3){ // dai
                require(amount[i] <= usdAllowances[members[i]], 'Xeldorado: amount exceeds grant');
                require(IERC20(IXeldoradoCreatorFactory_LT(creatorfactory).dai()).transfer(members[i], amount[i]), 'Xeldorado: grant transfer failed');
                usdAllowances[members[i]] -= amount[i];
                usdTotalAllowances -= amount[i];
            }
            else{
                require(0==1,'Xeldorado: invalid tokenId');
            }
            emit allowancesRedeemed(creator, amount[i], members[i], tokenId[i]);
        }
        currentBalanceUpdate();
    }

    // only allowance receving member can call
    function redeemAllowances(uint amount, uint tokenId) public virtual override lock {
        if(tokenId==1){ // native token
            require(amount <= nativeTokenAllowances[msg.sender], 'Xeldorado: amount exceeds grant');
            require(IERC20(IXeldoradoCreatorFactory_LT(creatorfactory).networkWrappedToken()).transfer(msg.sender, amount), 'Xeldorado: grant transfer failed');
            nativeTokenAllowances[msg.sender] -= amount;
            nativeTotalAllowances -= amount;
        }
        else if(tokenId==2){ // usdc
            require(amount <= usdAllowances[msg.sender], 'Xeldorado: amount exceeds grant');
            require(IERC20(IXeldoradoCreatorFactory_LT(creatorfactory).usdc()).transfer(msg.sender, amount), 'Xeldorado: grant transfer failed');
            usdAllowances[msg.sender] -= amount;
            usdTotalAllowances -= amount;
        }
        else if(tokenId==3){ // dai
            require(amount <= usdAllowances[msg.sender], 'Xeldorado: amount exceeds grant');
            require(IERC20(IXeldoradoCreatorFactory_LT(creatorfactory).dai()).transfer(msg.sender, amount), 'Xeldorado: grant transfer failed');
            usdAllowances[msg.sender] -= amount;
            usdTotalAllowances -= amount;
        }
        else{
            require(0==1,'Xeldorado: invalid tokenId');
        }
        emit allowancesRedeemed(creator, amount, msg.sender, tokenId);
        currentBalanceUpdate();
    }
}