// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import './CreatorToken.sol';
import './CreatorVestingVault.sol';
import './interfaces/ICreatorDAO.sol';
import './interfaces/IXeldoradoCreatorFactory.sol';
import './interfaces/IXeldoradoVault.sol';
import './interfaces/IXeldoradoFactory.sol';

contract XeldoradoCreatorFactory is IXeldoradoCreatorFactory{
    mapping(address => address) public override creatorToken;
    mapping(address => address) public override creatorVault;
    mapping(address => address) public override creatorVestingVault;
    mapping(address => address) public override creatorBank;
    mapping(address => address) public override creatorDAO;
    mapping(address => uint) public override creatorSwapFee;
    mapping(address => uint) public override creatorCTOFee; // creatortokenoffering fee
    mapping(address => uint) public override creatorNFTFee;
    // mapping(address => uint) public override creatorDirectTransferApproval; // 0: starting state || 1: requested || 2: approved || 3: denied
    mapping(address => address[]) creatorAdmins; // creator is not added to admins
    address[] public override allCreators;

    address public override factory;

    constructor() {
        factory = msg.sender;   
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
    
    function newCreator(address _creator, uint _creatorSwapFee, uint _creatorCTOFee, uint _creatorNFTFee) public virtual override {
        require(_creatorSwapFee <= IXeldoradoFactory(factory).maxCreatorFee() && _creatorCTOFee <= IXeldoradoFactory(factory).maxCreatorFee() && _creatorNFTFee <= IXeldoradoFactory(factory).maxCreatorFee(), 'Xeldorado: creator fee limit'); // scale of 10000 //cannot charge more than max creator fee set eg 0.1%
        allCreators.push(_creator);
        creatorSwapFee[_creator] = _creatorSwapFee;
        creatorCTOFee[_creator] = _creatorCTOFee;
        creatorNFTFee[_creator] = _creatorNFTFee;
    }
    
    // only creator can call
    function updateCreatorSwapFee(address _creator, uint _creatorSwapFee) public virtual override {
        require(msg.sender==_creator,'Xeldorado: only creator allowed');
        require(_creatorSwapFee <= IXeldoradoFactory(factory).maxCreatorFee(), 'Xeldorado: creator fee limit'); // scale of 10000 //cannot charge more than max creator fee set eg 0.1% 
        creatorSwapFee[_creator] = _creatorSwapFee;
    }

    // only creator can call
    function updateCreatorCTOFee(address _creator, uint _creatorCTOFee) public virtual override {
        require(msg.sender==_creator,'Xeldorado: only creator allowed');
        require(_creatorCTOFee <= IXeldoradoFactory(factory).maxCreatorFee(), 'Xeldorado: creator fee limit'); // scale of 10000 //cannot charge more than max creator fee set eg 0.1% 
        creatorCTOFee[_creator] = _creatorCTOFee;
    }

    // only creator can call
    function updateCreatorNFTFee(address _creator, uint _creatorNFTFee) public virtual override {
        require(msg.sender==_creator,'Xeldorado: only creator allowed');
        require(_creatorNFTFee <= IXeldoradoFactory(factory).maxCreatorFee(), 'Xeldorado: creator fee limit'); // scale of 10000 //cannot charge more than max creator fee set eg 0.1% 
        creatorNFTFee[_creator] = _creatorNFTFee;
    }

    // only creator or admins can call
    // creator deploys the bank contract and then passes contract address of deployed bank
    // in the constructor of the bank contract itself creator's creatorToken, creatorVault and creatorPair are set
    // creator's bank contract will be administered by Banking Factory contract including setting of fees to exchange and creator
    // since operation for a creator are already started, only creator should be allowed to start Banking
    function setCreatorBank(address _creator, address _bank) public virtual override onlyCreatorOrAdmin(_creator) {
        require(creatorBank[_creator] == address(0),'Xeldorado: bank already set');
        creatorBank[_creator] = _bank;
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

    // only creator or admins can call
    // function requestDirectTransferApproval(address _creator) public virtual override onlyCreatorOrAdmin(_creator) {
    //     creatorDirectTransferApproval[_creator]=1;
    //     emit DirectTransferApprovalRequested(_creator);
    // }

    function generateCreatorVault(address _creator, string memory _name, string memory _symbol, address cvault, address cdao) public virtual override returns (address token){
        require(creatorVault[_creator] == address(0),'Xeldorado: Vault exist');
        CreatorVestingVault cvvault_o = new CreatorVestingVault(factory, cvault);
        address cvvault = address(cvvault_o);
        token = _mintCreatorToken(_creator, cvvault, _name, _symbol, cvault, cdao);
        IXeldoradoVault(cvault).initialize(token,cdao);
        creatorVault[_creator]=cvault;
        creatorVestingVault[_creator]=cvvault;
        creatorDAO[_creator]=cdao;
        token = token;
        emit CreatorVestingVaultCreated(cvvault,_creator);
        emit CreatorVaultCreated(cvault,_creator);
        emit CreatorDAOCreated(cdao,_creator);
    }
    
    function _mintCreatorToken(address _creator, address _creatorVestingVault, string memory _name, string memory _symbol, address _vault, address _cdao) internal returns (address token){
        require(creatorToken[_creator] == address(0),'Xeldorado: Token exist');
        require(_vault != address(0),'Xeldorado: address empty'); //  check is sufficient
        CreatorToken ctoken = new CreatorToken(_name, _symbol, _creatorVestingVault, _cdao, _vault, _creator, IXeldoradoFactory(factory).totalCreatorTokenSupply(), IXeldoradoFactory(factory).percentCreatorOwnership(), IXeldoradoFactory(factory).percentDAOOwnership());
        token = address(ctoken);
        ICreatorDAO(_cdao).initialise(token, _vault);
        creatorToken[_creator] = token;
        emit CreatorTokenCreated(token,_creator);
    }
    
    function syncMigrationContractVoting(address _creator) public virtual override {
        ICreatorToken(creatorToken[_creator]).migrationVotingStatusSync(IXeldoradoFactory(factory).migrationDuration());
    }

    // only Vault Contract can call
    function updateCreatorVaultForMigration(address _creator, address toContract) public virtual override {
        require(msg.sender == creatorVault[_creator], 'Xeldorado: only Vault allowed');
        emit CreatorVaultUpdated(creatorVault[_creator], toContract, _creator);
        creatorVault[_creator] = toContract;
    }

    // only Bank Contract can call
    function updateCreatorBankForMigration(address _creator, address toContract) public virtual override {
        require(msg.sender == creatorBank[_creator], 'Xeldorado: only Bank allowed');
        emit CreatorBankUpdated(creatorBank[_creator], toContract, _creator);
        creatorBank[_creator] = toContract;
    }

    // only DAO Contract can call
    function updateCreatorDAOForMigration(address _creator, address toContract) public virtual override {
        require(msg.sender == creatorDAO[_creator], 'Xeldorado: only DAO allowed');
        emit CreatorDAOUpdated(creatorDAO[_creator], toContract, _creator);
        creatorDAO[_creator] = toContract;
    }

    // only direct Transfer Approver can call
    // function approveDirectTransfer(address _creator) public virtual override {
    //     require(msg.sender==IXeldoradoFactory(factory).directNFTTransferApproverContract(),'Xeldorado: only Approver Contract');
    //     creatorDirectTransferApproval[_creator]=2;
    //     emit DirectTransferApproved(_creator);
    // }

    // only direct Transfer Approver can call
    // function rejectDirectTransfer(address _creator) public virtual override {
    //     require(msg.sender==IXeldoradoFactory(factory).directNFTTransferApproverContract(),'Xeldorado: only Approver Contract');
    //     creatorDirectTransferApproval[_creator]=3;
    //     emit DirectTransferRejected(_creator);
    // }
}