// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICreatorToken is IERC20 {
    event tokensMinted(address ctoken, uint amount, address to);
    event tokensBurnt(address ctoken, uint amount, address _of);
    event migrationInitialised(address migrationContract, address ctoken);
    event migrationContractVoted(address migrationContract, address ctoken, address voter, bool vote);

    function migrationContract() external view returns(address);
    function creator() external view returns(address);
    function voteCount(uint) external view returns(uint);
    function votersTokenCount(uint) external view returns(uint);
    function votingPhase() external view returns(uint);
    function migrationContractPassed() external view returns(bool);

    // only vault can call
    function burnTokens(address _of, uint _amount) external; 
    function mintTokens(address _to, uint _amount) external; 
    function updateVaultAddress(address _vault) external;

    // caller's token will be burnt
    function burnMyTokens(uint _amount) external;

    // need to be started by creator or any of the token holders
    function migrationContractVotingInitialise(address _migrationContract) external;

    // need to be called directly by the voters
    function migrationContractVote(bool vote) external;

    // only creator factory can call
    function migrationVotingStatusSync(uint duration) external;
}