// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import './CreatorToken_LT.sol';
import './CreatorDAO_LT.sol';
import './interfaces/IXeldoradoCreatorFactory_LT.sol';
import './XeldoradoVault_LT.sol';

contract XeldoradoCreatorFactory_LT is IXeldoradoCreatorFactory_LT{
    mapping(address => address) public override creatorToken;
    mapping(address => address) public override creatorVault;
    mapping(address => address) public override creatorDAO;
    mapping(address => uint) public override creatorSaleFee; // Sale of token as tickets // price or quantity of base tokens
    mapping(address => address[]) creatorAdmins; // creator is not added to admins
    address[] public override allCreators;

    address public override exchangeAdmin;
    uint votingDuration; //default value although creator can change in DAO contract // in seconds

    constructor() {
        exchangeAdmin = msg.sender;   
        votingDuration = 420; // in seconds
    }

    modifier onlyCreatorOrAdmin(address _creator) {
        require(msg.sender==_creator || isCreatorAdmin(_creator, msg.sender), 'Xeldorado: only creator or admins');
        _;
    }

    function getCreatorAdmins(address _creator) public virtual override view returns(address[] memory){
        return creatorAdmins[_creator];
    }
    
    function isCreatorAdmin(address _creator, address _admin) public view override returns (bool){
      for (uint i; i < creatorAdmins[_creator].length;i++){
          if (creatorAdmins[_creator][i]==_admin) return true;
      }
      return false;
    }
    
    function creatorExist(address _creator) public view override returns (bool){
      for (uint i; i < allCreators.length;i++){
          if (allCreators[i]==_creator) return true;
      }
      return false;
    }
    
    function newCreator(address _creator, string memory _name, string memory _symbol, address _basetoken, uint _creatorSaleFee, address _vault) public virtual override returns(address token, address dao) {
        allCreators.push(_creator);
        creatorSaleFee[_creator] = _creatorSaleFee;

        // deploying token contract
        token = _createToken(_creator, _name, _symbol, _basetoken);

        // deploying DAO contract
        dao = _createDAO(_creator, token, _basetoken);

        // deploying vault contract
        _initialiseVault(_vault, _creator, _name, _symbol, token, dao);
    }

    function _createToken(address _creator, string memory _name, string memory _symbol, address _basetoken) internal returns (address token){
        require(creatorToken[_creator] == address(0),'Xeldorado: Token exist');
        CreatorToken_LT ctoken = new CreatorToken_LT(_creator, _name, _symbol, _basetoken);
        token = address(ctoken);
        creatorToken[_creator] = token;
        emit CreatorTokenCreated(token,_creator);
    }

    function _createDAO(address _creator, address _token, address _basetoken) internal returns (address dao){
        require(creatorDAO[_creator] == address(0),'Xeldorado: DAO exist');
        CreatorDAO_LT cdao = new CreatorDAO_LT(_creator, votingDuration, _token, _basetoken);
        dao = address(cdao);
        creatorDAO[_creator] = dao;
        ICreatorToken_LT(_token).initialize(dao);
        emit CreatorDAOCreated(dao,_creator);
    }

    function _initialiseVault(address _vault, address _creator, string memory _name, string memory _symbol, address _token, address _dao) internal {
        require(creatorVault[_creator] == address(0),'Xeldorado: Vault exist');
        IXeldoradoVault_LT(_vault).initialise(_name, _symbol, _token, _dao);
        creatorVault[_creator] = _vault;
        emit CreatorVaultCreated(_vault,_creator);
    }

    // only creator can call
    function updateCreatorSaleFee(address _creator, uint _creatorSaleFee) public virtual override onlyCreatorOrAdmin(_creator) {
        creatorSaleFee[_creator] = _creatorSaleFee;
    }
    
    // only creator or admins can call
    // check if creatorAdmins already exists first before calling
    function setCreatorAdmins(address _creator, address[] memory admins) public virtual override onlyCreatorOrAdmin(_creator) {
        for(uint i;i<admins.length;i++)
        {
            creatorAdmins[_creator].push(admins[i]);
            emit CreatorAdminAdded(_creator, admins[i], msg.sender);
        }
    }

    // only creator or admins can call
    // get index from getCreatorAdmins function
    // use only one at a time
    function removeCreatorAdmins(address _creator, uint index) public virtual override onlyCreatorOrAdmin(_creator) {
        emit CreatorAdminRemoved(_creator, creatorAdmins[_creator][index], msg.sender);
        creatorAdmins[_creator][index]=creatorAdmins[_creator][creatorAdmins[_creator].length-1];
        creatorAdmins[_creator].pop();
    }
}