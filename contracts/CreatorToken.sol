// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/ICreatorToken.sol";
import "./libraries/SafeMath.sol";

contract CreatorToken is ERC20, ICreatorToken {
    using SafeMath  for uint;

    address private admin;
    address private vault;
    uint private unlocked;
    mapping(address=> mapping (address=>uint)) alreadyVoted; // mapping migration contract to voter to vote with 0 for not voted, 1 for no and 2 for yes
    uint public override voteCount;
    uint public override votersTokenCount;
    address public override migrationContract;
    uint private votingPhase; // 0 for not started or completed and 1 for going on 
    uint private startTimeStamp;

    // eligible voters only
    // modifier onlyEligibleVoter() {
    //     uint balance = ICreatorToken(address(this)).balanceOf(msg.sender);
    //     require(balance > 0);
    //     _;
    // }

    modifier lock() {
        require(unlocked == 1, 'Xeldorado: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor(string memory name, string memory symbol, address _creatorVestingVault, address _vault, uint _totalCreatorTokenSupply, uint _percentCreatorOwnership) ERC20(name,symbol){
        _mint(_creatorVestingVault, _totalCreatorTokenSupply.mul(_percentCreatorOwnership).div(1000)); // 26685312 * 10 ** 16 for 24% 1111888
        _mint(_vault, _totalCreatorTokenSupply.sub(_totalCreatorTokenSupply.mul(_percentCreatorOwnership).div(1000))); // 84503488 * 10 ** 16 for 76% 1111888
        admin = msg.sender; // creator factory
        vault = _vault;
        unlocked = 1;
    }
    
    function burnTokens(address _of, uint _amount) public virtual override lock {
        require(msg.sender==vault,'Xeldorado: only vault can burn tokens');
        _burn(_of,_amount);
        emit tokensBurnt(address(this), _amount, _of);
    }

    function burnMyTokens(uint _amount) public virtual override lock {
        _burn(msg.sender,_amount);
        emit tokensBurnt(address(this), _amount, msg.sender);
    }
    
    function mintTokens(address _to, uint _amount) public virtual override lock {
        require(msg.sender==vault,'Xeldorado: only vault can burn tokens');
        _mint(_to,_amount);
        emit tokensMinted(address(this), _amount, _to);
    }

    // need to be started by creator or any of the token holders
    function migrationContractVotingInitialise(address _migrationContract) public virtual override lock {
        require(ICreatorToken(address(this)).balanceOf(msg.sender) > 0 , 'Xeldorado: not a token owner');
        require(votingPhase!=1,'Xeldorado: voting going on');
        voteCount = 0;
        votersTokenCount = 0;
        votingPhase = 1;
        migrationContract = _migrationContract;
        startTimeStamp = block.timestamp;
        emit migrationInitialised(migrationContract, address(this));
    }

    // need to be called directly by the voters
    function migrationContractVote(bool vote) public virtual override lock {
        require(votingPhase == 1, 'Xeldorado: Voting not started or completed');
        uint balance = ICreatorToken(address(this)).balanceOf(msg.sender);
        require(balance > 0, 'Xeldorado: only creator token holders');
        require(alreadyVoted[migrationContract][msg.sender]==0,'Xeldorado: already voted');
        if(vote) 
        {
            voteCount +=  1;
            votersTokenCount += balance;
            alreadyVoted[migrationContract][msg.sender] = 2;
        }
        else 
        {   
            alreadyVoted[migrationContract][msg.sender] = 1;
        }
        emit migrationContractVoted(migrationContract, address(this), msg.sender, vote);
    }

    // voterThreshold and voterTokenThreshold on scale of 100 to indicate % value
    // total token holder count will be supplied in the migration approver contract using off chain solution
    // voting for a fixed time period with duration in secodns
    function migrationContractPassed(uint voterThreshold, uint voterTokenThreshold, uint totalTokenHolders) public virtual override view returns(bool){
        bool tokenThpassed;
        if(votersTokenCount.mul(100).div(ICreatorToken(address(this)).totalSupply()) >= voterTokenThreshold) tokenThpassed = true;
        else tokenThpassed = false;
        bool voterThpassed;
        if(voteCount.mul(100).div(totalTokenHolders) >= voterThreshold) voterThpassed = true;
        else voterThpassed = false;
        return (tokenThpassed && voterThpassed);
    }

    function migrationVotingStatusSync(uint voterThreshold, uint voterTokenThreshold, uint totalTokenHolders, uint duration) public virtual override lock {
        require(msg.sender==admin,'Xeldorado: forbidden'); // only creator factory
        if(migrationContractPassed(voterThreshold, voterTokenThreshold, totalTokenHolders)) votingPhase = 0;
        if((block.timestamp.sub(startTimeStamp)).div(duration) > 1) votingPhase = 0;
    }
}