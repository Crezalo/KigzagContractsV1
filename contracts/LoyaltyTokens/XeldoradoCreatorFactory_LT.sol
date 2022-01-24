// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import './CreatorToken_LT.sol';
import './interfaces/IXeldoradoCreatorFactory_LT.sol';
import './interfaces/ICreatorDAO_LT.sol';
import './interfaces/IXeldoradoVault_LT.sol';

contract XeldoradoCreatorFactory_LT is IXeldoradoCreatorFactory_LT{
    mapping(address => address) public override creatorToken;
    mapping(address => address) public override creatorVault;
    mapping(address => address) public override creatorDAO;
    // Sale of token as tickets 
    // price or quantity of base tokens 
    // will have 2 values-
    // at index: 0 native token price
    // at index: 1 USD token price
    mapping(address => uint[]) private creatorSaleFee; 
    mapping(address => address[]) creatorAdmins; // creator is not added to admins
    address[] public override allCreators;

    address public override exchangeAdmin;
    uint public override fee;
    uint public override discount;
    uint public override noOFTokensForDiscount;
    address public override feeTo;
    address public override feeToSetter;
    address public override exchangeToken;
    address public override networkWrappedToken;
    address public override usdc;
    address public override dai;
    uint votingDuration; //default value although creator can change in DAO contract // in seconds

    constructor(address _feeTo, address _feeToSetter, address _exchangeToken, address _networkWrappedToken, address _usdc, address _dai) {
        exchangeAdmin = msg.sender;   
        votingDuration = 420; // in seconds
        fee = 50; // on scale of 10000
        discount = 25; // on scale of 10000
        feeTo = _feeTo;
        feeToSetter = _feeToSetter;
        exchangeToken = _exchangeToken;
        networkWrappedToken = _networkWrappedToken;
        usdc = _usdc;
        dai = _dai;
        noOFTokensForDiscount = 50 * 10**18;
    }

    function setFeeTo(address _feeTo) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
    
    function setFee(uint _fee) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        fee = _fee;
        // set to 50 (i.e. 0.5% on the scale of 10000)
    }
    
    function setDiscount(uint _discount) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        discount = _discount;
        // set to 50 (i.e. 0.5% on the scale of 10000)
    }

    function setExchangeToken(address _exchangeToken) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        exchangeToken = _exchangeToken;
    }
    
    function setNoOFTokensForDiscount(uint _noOFTokensForDiscount) public virtual override {
        require(msg.sender == feeToSetter, 'Xeldorado: FORBIDDEN');
        noOFTokensForDiscount = _noOFTokensForDiscount;
        // set to 50 (i.e. 0.5% on the scale of 10000)
    }

    modifier onlyCreatorOrAdmin(address _creator) {
        require(msg.sender==_creator || isCreatorAdmin(_creator, msg.sender), 'Xeldorado: only creator or admins');
        _;
    }

    function getCreatorAdmins(address _creator) public virtual override view returns(address[] memory){
        return creatorAdmins[_creator];
    }

    function getCreatorSaleFee(address _creator) public virtual override view returns(uint[] memory){
        return creatorSaleFee[_creator];
    }
    
    function isCreatorAdmin(address _creator, address _admin) public view override returns (bool){
      for (uint i; i < creatorAdmins[_creator].length;i++){
          if (creatorAdmins[_creator][i]==_admin) return true;
      }
      return false;
    }
    
    function newCreator(address _creator, address _dao, address _vault, string memory _name, string memory _symbol, uint _creatorSaleFeeNative, uint _creatorSaleFeeUSD) public virtual override returns(address token) {
        allCreators.push(_creator);
        creatorSaleFee[_creator].push(_creatorSaleFeeNative);
        creatorSaleFee[_creator].push(_creatorSaleFeeUSD);

        // deploying token contract
        token = _createToken(_creator, _name, _symbol);

        // initialising deployed DAO contract
        _initialiseDAO(_dao, _creator, token);

        // initialising deployed vault contract
        _initialiseVault(_vault, _creator, _name, _symbol, token);
    }

    function _createToken(address _creator, string memory _name, string memory _symbol) internal returns (address token){
        require(creatorToken[_creator] == address(0),'Xeldorado: Token exist');
        CreatorToken_LT ctoken = new CreatorToken_LT(_creator, _name, _symbol);
        token = address(ctoken);
        creatorToken[_creator] = token;
        emit CreatorTokenCreated(token,_creator);
    }

    function _initialiseDAO(address dao, address _creator, address _token) internal {
        require(creatorDAO[_creator] == address(0),'Xeldorado: DAO exist');
        ICreatorDAO_LT(dao).initialise(_creator, votingDuration,  _token);
        creatorDAO[_creator] = dao;
        ICreatorToken_LT(_token).initialize(dao);
        emit CreatorDAOCreated(dao,_creator);
    }

    function _initialiseVault(address _vault, address _creator, string memory _name, string memory _symbol, address _token) internal {
        require(creatorVault[_creator] == address(0),'Xeldorado: Vault exist');
        IXeldoradoVault_LT(_vault).initialise(_creator, _name, _symbol, _token);
        creatorVault[_creator] = _vault;
        emit CreatorVaultCreated(_vault,_creator);
    }

    // only creator or admins can call
    function updateCreatorSaleFeeNative(address _creator, uint _creatorSaleFeeNative) public virtual override onlyCreatorOrAdmin(_creator) {
        creatorSaleFee[_creator][0] = _creatorSaleFeeNative;
    }
    
    // only creator or admins can call
    function updateCreatorSaleFeeUSD(address _creator, uint _creatorSaleFeeUSD) public virtual override onlyCreatorOrAdmin(_creator) {
        creatorSaleFee[_creator][1] = _creatorSaleFeeUSD;
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