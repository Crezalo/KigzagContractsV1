// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICreatorToken is IERC20 {
    event tokensMinted(address ctoken, uint amount, address to);
    event tokensBurnt(address ctoken, uint amount, address _of);
    event migrationInitialised(address migrationContract, address ctoken);
    event migrationContractVoted(address migrationContract, address ctoken, address voter, bool vote);

    function migrationContract() external view returns(address);
    function voteCount() external view returns(uint);
    function votersTokenCount() external view returns(uint);
    function migrationContractPassed(uint voterThreshold, uint voterTokenThreshold, uint totalTokenHolders) external view returns(bool);

    function burnTokens(address _of, uint _amount) external; // only vault allowed
    function burnMyTokens(uint _amount) external; // to be called directly from address whose token has to be burnt
    function mintTokens(address _to, uint _amount) external; // only vault allowed

    // need to be started by creator or any of the token holders
    function migrationContractVotingInitialise(address _migrationContract) external;

    // need to be called directly by the voters
    function migrationContractVote(bool vote) external;

    // only creator factory can access
    function migrationVotingStatusSync(uint voterThreshold, uint voterTokenThreshold, uint totalTokenHolders, uint duration) external;
}