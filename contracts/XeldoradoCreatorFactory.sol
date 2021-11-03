// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import './CreatorToken.sol';
// import './XeldoradoVault.sol';
import './CreatorVestingVault.sol';
import './interfaces/IXeldoradoCreatorFactory.sol';
import './interfaces/IXeldoradoVault.sol';
// import './libraries/XeldoradoLibrary1.sol';

contract XeldoradoCreatorFactory is IXeldoradoCreatorFactory{
    mapping(address => address) public override creatorToken;
    mapping(address => address) public override creatorVault;
    mapping(address => address) public override creatorVestingVault;
    mapping(address => uint) public override creatorFee;
    address[] public override allCreators;
    
    function newCreator(address _creator, uint _creatorFee) public virtual override {
        require(_creatorFee <= 5, 'Xeldorado: creator fee limit'); // scale of 10000 //cannot charge more than 0.05%
        allCreators.push(_creator);
        creatorFee[_creator] = _creatorFee;
    }
    
    function updateCreatorFee(address _creator, uint _creatorFee) public virtual override {
        require(_creatorFee <= 5, 'Xeldorado: creator fee limit'); // scale of 10000 //cannot charge more than 0.05%
        creatorFee[_creator] = _creatorFee;
    }
    
    function creatorExist(address _creator) public view override returns (bool){
      for (uint i; i < allCreators.length;i++){
          if (allCreators[i]==_creator) return true;
      }
      return false;
    }
    
    function generateCreatorVault(address _creator, string memory _name, string memory _symbol, address cvault) public virtual override returns (address token){
        require(creatorVault[_creator] == address(0),'Xeldorado: Vault exist');
        CreatorVestingVault cvvault_o = new CreatorVestingVault();
        address cvvault = address(cvvault_o);
        token = _mintCreatorToken(_creator, cvvault, _name, _symbol, cvault);
        IXeldoradoVault(cvault).initialize(token,address(cvvault));
        creatorVault[_creator]=cvault;
        creatorVestingVault[_creator]=cvvault;
        token = token;
        emit CreatorVaultCreated(cvault,_creator);
    }
    
    function _mintCreatorToken(address _creator, address _creatorVestingVault, string memory _name, string memory _symbol, address _vault) internal returns (address token){
        require(creatorToken[_creator] == address(0),'Xeldorado: Token exist');
        require(_vault != address(0),'Xeldorado: address empty'); //  check is sufficient
        // token = XeldoradoLibrary.CreatorFactory_mintCreatorToken_Internal(_name, _symbol, _creatorVestingVault, _vault);
        CreatorToken ctoken = new CreatorToken(_name, _symbol, _creatorVestingVault, _vault);
        token = address(ctoken);
        creatorToken[_creator] = token;
        emit CreatorTokenMinted(token,_creator);
    }
    
}