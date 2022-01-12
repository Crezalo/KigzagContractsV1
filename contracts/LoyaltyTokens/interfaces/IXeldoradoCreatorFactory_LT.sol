// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

interface IXeldoradoCreatorFactory_LT {
    event CreatorVaultCreated(address vault, address creator);
    event CreatorTokenCreated(address token, address creator);
    event CreatorDAOCreated(address cdao, address creator);
    event CreatorVaultUpdated(address cVaultOld, address cVaultNew, address creator);
    event CreatorDAOUpdated(address cdaoOld, address cdaoNew, address creator);
    event CreatorAdminAdded(address _creator, address admin, address by);
    event CreatorAdminRemoved(address _creator, address admin, address by);
    
    function creatorToken(address _creator) external view returns(address);
    function creatorVault(address _creator) external view returns(address);
    function creatorDAO(address _creator) external view returns(address);
    function creatorSaleFee(address _creator) external view returns(uint);
    function allCreators(uint) external view returns(address);
    function exchangeAdmin() external view returns(address);
    function fee() external view returns(uint);
    function discount() external view returns(uint);
    function noOFTokensForDiscount() external view returns(uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function exchangeToken() external view returns (address);
    function getCreatorAdmins(address _creator) external view returns(address[] memory);
    function isCreatorAdmin(address _creator, address admin) external view returns(bool);
    // function creatorExist(address _creator) external view returns(bool);

    function newCreator(address _creator, string memory _name, string memory _symbol, address _basetoken, uint _creatorSaleFee, address _vault) external returns(address token, address dao);
    
    // only admin or creator can call
    // function requestDirectTransferApproval(address _creator) external;
    function setCreatorAdmins(address _creator, address[] memory admins) external;
    function removeCreatorAdmins(address _creator, uint index) external;

    // only creator can call
    function updateCreatorSaleFee(address _creator, uint _creatorSaleFee) external;

    // only feeToSetter can call
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setFee(uint _fee) external;
    function setDiscount(uint _discount) external;
    function setExchangeToken(address _exchangeToken) external;
    function setNoOFTokensForDiscount(uint _noOFTokensForDiscount) external;

}
