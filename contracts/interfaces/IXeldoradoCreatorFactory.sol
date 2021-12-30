// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

interface IXeldoradoCreatorFactory {
    event CreatorVaultCreated(address vault, address creator);
    event CreatorTokenCreated(address token, address creator);
    event CreatorVestingVaultCreated(address cvvault, address creator);
    event CreatorDAOCreated(address cdao, address creator);
    event CreatorVaultUpdated(address cVaultOld, address cVaultNew, address creator);
    event CreatorBankUpdated(address cVaultOld, address cVaultNew, address creator);
    event CreatorDAOUpdated(address cdaoOld, address cdaoNew, address creator);
    event DirectTransferApprovalRequested(address _creator);
    event CreatorAdminAdded(address _creator, address admin, address by);
    event CreatorAdminRemoved(address _creator, address admin, address by);
    // event DirectTransferApproved(address _creator);
    // event DirectTransferRejected(address _creator);
    
    function creatorToken(address _creator) external view returns(address);
    function creatorVault(address _creator) external view returns(address);
    function creatorVestingVault(address _creator) external view returns(address);
    function creatorBank(address _creator) external view returns(address);
    function creatorDAO(address _creator) external view returns(address);
    function creatorSwapFee(address _creator) external view returns(uint);
    function creatorCTOFee(address _creator) external view returns(uint);
    function creatorNFTFee(address _creator) external view returns(uint);
    function factory() external view returns(address);
    // function creatorDirectTransferApproval(address _creator) external view returns(uint);
    function getCreatorAdmins(address _creator) external view returns(address[] memory);
    function allCreators(uint) external view returns(address);
    function creatorExist(address _creator) external view returns(bool);
    function isCreatorAdmin(address _creator, address admin) external view returns(bool);

    function newCreator(address _creator, uint _creatorSwapFee, uint _creatorCTOFee, uint _creatorNFTFee) external;
    function generateCreatorVault(address _creator, string memory _name, string memory _symbol, address cvault, address cdao) external returns(address token);
    function syncMigrationContractVoting(address _creator) external;
    
    // only admin or creator can call
    // function requestDirectTransferApproval(address _creator) external;
    function setCreatorAdmins(address _creator, address[] memory admins) external;
    function removeCreatorAdmins(address _creator, uint index) external;
    function setCreatorBank(address _creator, address _bank) external;

    // only migration contract can call
    function updateCreatorVaultForMigration(address _creator, address toContract) external;
    function updateCreatorBankForMigration(address _creator, address toContract) external;
    function updateCreatorDAOForMigration(address _creator, address toContract) external;
    
    // only directNFTTransferApproverContract can call
    // function approveDirectTransfer(address _creator) external;
    // function rejectDirectTransfer(address _creator) external;

    // only creator can call
    function updateCreatorSwapFee(address _creator, uint _creatorSwapFee) external;
    function updateCreatorCTOFee(address _creator, uint _creatorCTOFee) external;
    function updateCreatorNFTFee(address _creator, uint _creatorNFTFee) external;
}
