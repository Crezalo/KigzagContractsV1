// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

interface IXeldoradoCreatorFactory {
    event CreatorVaultCreated(address vault, address creator);
    event CreatorTokenMinted(address token, address creator);
    
    function creatorToken(address _creator) external view returns(address);
    function creatorVault(address _creator) external view returns(address);
    function creatorVestingVault(address _creator) external view returns(address);
    function creatorFee(address _creator) external view returns(uint);
    function allCreators(uint) external view returns(address);
    // function factory() external view returns(address);
    function creatorExist(address _creator) external view returns(bool);
    
    function newCreator(address _creator, uint _creatorFee) external;
    function updateCreatorFee(address _creator, uint _creatorFee) external;
    function generateCreatorVault(address _creator, string memory _name, string memory _symbol, address cvault) external returns(address token);
    function syncMigrationContractVoting(address _creator, uint totalTokenHolders) external;
}
