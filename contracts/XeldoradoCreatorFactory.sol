// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import './CreatorToken.sol';
import './XeldoradoVault.sol';
import './interfaces/IXeldoradoCreatorFactory.sol';

contract XeldoradoCreatorFactory is IXeldoradoCreatorFactory{
    mapping(address => address) public override creatorToken;
    mapping(address => address) public override creatorVault;
    mapping(address => uint) public override creatorFee;
    address[] public override allCreators;
    address public override factory;
    
    constructor() {
        factory = msg.sender;   
    }
    
    function newCreator(address _creator, uint _creatorFee) public virtual override {
        require(_creatorFee <= 5, 'Xeldorado: creator cannot charge more than 0.05%'); // scale of 10000
        allCreators.push(_creator);
        creatorFee[_creator] = _creatorFee;
    }
    
    function updateCreatorFee(address _creator, uint _creatorFee) public virtual override {
        require(_creatorFee <= 5, 'Xeldorado: creator cannot charge more than 0.05%');
        creatorFee[_creator] = _creatorFee;
    }
    
    function creatorExist(address _creator) public view override returns (bool){
      for (uint i; i < allCreators.length;i++){
          if (allCreators[i]==_creator) return true;
      }
      return false;
    }
    
    function generateCreatorVault(address _creator, string memory _name, string memory _symbol) public virtual override returns (address vault, address token){
        require(creatorVault[_creator] == address(0),'Xeldorado: Vault already exist');
        XeldoradoVault cvault = new XeldoradoVault(_creator, _name, _symbol);
        address ctoken = _mintCreatorToken(_creator, _name, _symbol, address(cvault));
        cvault.initialize(ctoken);
        creatorVault[_creator]=address(cvault);
        vault = creatorVault[_creator];
        token = ctoken;
        emit CreatorVaultCreated(vault,_creator);
    }
    
    function _mintCreatorToken(address _creator, string memory _name, string memory _symbol, address _vault) internal returns (address token){
        require(creatorToken[_creator] == address(0),'Xeldorado: Creator Token already exist');
        require(_vault != address(0),'Xeldorado: Vault address empty'); //  check is sufficient
        CreatorToken ctoken = new CreatorToken(_name, _symbol, _creator, _vault);
        creatorToken[_creator] = address(ctoken);
        token = creatorToken[_creator];
        emit CreatorTokenMinted(creatorToken[_creator],_creator);
    }
    
}