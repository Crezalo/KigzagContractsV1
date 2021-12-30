// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/ICreatorToken.sol";
import "./interfaces/IXeldoradoVault.sol";
import "./interfaces/IXeldoradoCreatorFactory.sol";
import "./libraries/SafeMath.sol";

contract CreatorToken is ERC20, ICreatorToken {
    using SafeMath  for uint;

    address private creatorfactory;
    address private vault;
    uint private unlocked;
    mapping(address=> mapping (address=>uint)) alreadyVoted; // mapping migration contract to voter to vote with 0 for not voted, 1 for no and 2 for yes
    mapping(uint=>uint) public override voteCount; // it will have 2 entries 
    mapping(uint=>uint) public override votersTokenCount;
    address public override migrationContract;
    address public override creator;
    uint public override votingPhase; // 0 for not started or completed and 1 for going on 
    uint private startTimeStamp;
    address private creatorVestingVault;

    modifier lock() {
        require(unlocked == 1, 'Xeldorado: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    modifier onlyHolders() {
        require(ICreatorToken(address(this)).balanceOf(msg.sender) > 0 , 'Xeldorado: not a token owner');
        _;
    }

    constructor(string memory name, string memory symbol, address _creatorVestingVault, address _creatorDAO, address _vault, address _creator, uint _totalCreatorTokenSupply, uint _percentCreatorOwnership, uint _percentDAOOwnership) ERC20(name,symbol){
        _mint(_creatorVestingVault, _totalCreatorTokenSupply.mul(_percentCreatorOwnership).div(1000)); // 240000 * 10 ** 18 for 24% 1000000*10^18
        _mint(_creatorDAO, _totalCreatorTokenSupply.mul(_percentDAOOwnership).div(1000)); //  60000 * 10 ** 18 for 6% 1000000*10^18
        _mint(_vault, _totalCreatorTokenSupply.sub(_totalCreatorTokenSupply.mul(_percentCreatorOwnership.add(_percentDAOOwnership)).div(1000))); // 700000 * 10 ** 18 for 70% 1000000*10^18
        creatorfactory = msg.sender; // creator factory
        vault = _vault;
        creator = _creator;
        unlocked = 1;
        creatorVestingVault = _creatorVestingVault;
    }
    
    function burnTokens(address _of, uint _amount) public virtual override {
        require(msg.sender==vault,'Xeldorado: only vault can burn tokens');
        _burn(_of,_amount);
        emit tokensBurnt(address(this), _amount, _of);
    }

    function burnMyTokens(uint _amount) public virtual override lock {
        _burn(msg.sender,_amount);
        emit tokensBurnt(address(this), _amount, msg.sender);
    }
    
    function mintTokens(address _to, uint _amount) public virtual override {
        require(msg.sender==vault,'Xeldorado: only vault can mint tokens');
        _mint(_to,_amount);
        emit tokensMinted(address(this), _amount, _to);
    }

    // need to be started by creator or any of the token holders
    function migrationContractVotingInitialise(address _migrationContract) public virtual override onlyHolders lock {
        require(votingPhase!=1,'Xeldorado: voting going on');
        votingPhase = 1;
        migrationContract = _migrationContract;
        startTimeStamp = block.timestamp;
        voteCount[1] = 0;
        voteCount[2] = 0;
        votersTokenCount[1] = 0;
        votersTokenCount[2] = 0;
        emit migrationInitialised(migrationContract, address(this));
    }

    // need to be called directly by the voters
    function migrationContractVote(bool vote) public virtual override onlyHolders lock {
        require(votingPhase == 1, 'Xeldorado: Voting not started or completed');
        require(alreadyVoted[migrationContract][msg.sender]==0,'Xeldorado: already voted');
        if(vote) 
        {
            voteCount[2] +=  1;
            votersTokenCount[2] += ICreatorToken(address(this)).balanceOf(msg.sender);
            alreadyVoted[migrationContract][msg.sender] = 2;
        }
        else 
        {   
            voteCount[1] +=  1;
            votersTokenCount[1] += ICreatorToken(address(this)).balanceOf(msg.sender);
            alreadyVoted[migrationContract][msg.sender] = 1;
        }
        emit migrationContractVoted(migrationContract, address(this), msg.sender, vote);
    }

    // although we do count number of voters for a choice ultimately voterTokenCount is considered
    function migrationContractPassed() public virtual override view returns(bool){
        if(votersTokenCount[2] > votersTokenCount[1]) return true; // passed
        return false; // failed
    }

    // close voting after the duration ends
    function migrationVotingStatusSync(uint duration) public virtual override lock {
        require(msg.sender==creatorfactory,'Xeldorado: forbidden'); // only creator factory
        if((block.timestamp.sub(startTimeStamp)).div(duration) > 1) votingPhase = 0;
    }

    // will be called during migration via vault
    function updateVaultAddress(address _vault) public virtual override {
        require(msg.sender==vault, 'Xeldorado: only vault can update');
        vault=_vault;
    }
}