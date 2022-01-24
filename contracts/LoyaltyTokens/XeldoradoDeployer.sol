// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import "./XeldoradoVault_LT.sol";
import "./CreatorDAO_LT.sol";
import "./interfaces/IXeldoradoCreatorFactory_LT.sol";

// separate deployer contract to optimise on code size 
// creating Vault and DAO objects in constructor reduces code size

contract XeldoradoDeployer {
    address public vault;
    address public dao;
    address public token;
    constructor(address creatorfactory, string memory _name, string memory _symbol, uint _creatorSaleFeeNative, uint _creatorSaleFeeUSD){
        XeldoradoVault_LT _vault = new XeldoradoVault_LT();
        vault = address(_vault);
        CreatorDAO_LT _dao = new CreatorDAO_LT();
        dao = address(_dao);
        token = IXeldoradoCreatorFactory_LT(creatorfactory).newCreator(msg.sender, dao, vault, _name, _symbol, _creatorSaleFeeNative, _creatorSaleFeeUSD);
    }
}