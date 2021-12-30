// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

interface ICreatorDAO{
    event AmountAddedToVault(address creator, uint amount);
    event Airdropped(address creator, uint amount, address member);
    event migrationDAOCompleted(address _newDAO);
    event allowancesUpdated(address dao, address from, address to, uint amount);
    event allowancesRedeemed(address dao, uint amount, address member);
    event proposalCreated(uint category, address dao, address proposer, uint proposalId);
    event managerAdded(address dao, address manager);
    event managerRemoved(address dao, address manager);

    function creator() external view returns(address);
    function token() external view returns(address);
    function vault() external view returns(address);
    function proposals() external view returns(uint);
    function Balance() external view returns(uint);
    function airdropApprovedAmount() external view returns(uint);
    function FLOApprovedAmount() external view returns(uint);
    function allowances(address) external view returns(uint);
    function proposedAirdropAmount() external view returns(uint);
    function proposedFLOAmount() external view returns(uint);
    function votingDuration() external view returns(uint);
    function communityManagers(uint index) external view returns(address);
    function airdropProposalIds(uint index) external view returns(uint);
    function FLOProposalIds(uint index) external view returns(uint);
    function allowancesProposalIds(uint index) external view returns(uint);
    function TotalAllowances() external view returns(uint);

    function proposal(uint proposalId) external view returns(address, string memory, uint, uint);
    function proposalManagerAllowancesInfoLength(uint proposalId) external view returns(uint);
    function proposalManagerAllowanesInfo(uint proposalId, uint index) external view returns(address, uint);
    function proposalVoteDataInfo(uint proposalId, uint choice) external view returns(uint, uint);
    function proposalStatus(uint proposalId) external view returns(uint);
    function CommunityManagerExists(address manager) external view returns(bool);

    // anyone can call
    function currentBalanceUpdate() external;
    function updateAirdropApprovedAmount() external;
    function updateFLOApprovedAmount() external;
    function updateManagerAllowances(uint proposalId) external;
    function sendAllowances(address[] memory members, uint[] memory amount) external;
    
    // only allowance transferer can call
    // usually mangers can call but in practise anyone can call
    function setAllowances(address[] memory _to, uint[] memory _amount) external; 

    // only allowance redeemer can call
    function redeemAllowances(uint amount) external;

    // only holders can call
    function airdropProposal(uint amount) external;
    function FLOProposal(uint amount) external;
    function allowancesProposal(uint[] memory amount, address[] memory managers) external;
    function generalProposal(string memory linkToProposal, uint _choices) external;
    function generalProposalVote(uint proposalId, uint choice) external;
    
    // only creator factor can initialise
    function initialise(address _token, address _vault) external;
    
    // only creator or admins can call
    function airdrop(uint amount, address[] memory members) external;
    function addCommunityManager(address[] memory managers) external;
    function removeCommunityManager(uint index) external;
    function updateVotingDuration(uint _votingDuration) external;
    
    // only vault can call
    function updateVaultAddress(address _newVault) external;
    function addBalanceToVault(uint amount) external;

    // only migration contract can call
    function migrateDAO(address toContract) external;
}