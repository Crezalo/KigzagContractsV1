// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import './CreatorNFT_LT.sol';
import './interfaces/ICreatorToken_LT.sol';
import './interfaces/IXeldoradoVault_LT.sol';
import './interfaces/IXeldoradoCreatorFactory_LT.sol';
import './interfaces/ICreatorDAO_LT.sol';
import '../libraries/SafeMath.sol';

contract XeldoradoVault_LT is IXeldoradoVault_LT{
    using SafeMath  for uint;
    
    address public override creator;
    address public override dao;
    address public override token;
    mapping(uint=>address) public override vaultIdTonftContract;    
    mapping(uint=>uint) public override vaultIdToTokenId;
    mapping(uint=>uint) public override vaultIdTonftPrice; // in creator tokens // in quantity as 10^18 decimals
    uint public override allNFTs;
    uint public override allOnSaleNFTs;
    uint public override allSoldNFTs;
    
    CreatorNFT_LT private nftcontract;
    address public override nftContract;
    
    uint private unlocked;

    address creatorfactory;
    
    modifier lock() {
        require(unlocked == 1, 'Xeldorado: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    modifier onlyCreatorOrAdmins() {
        require(msg.sender==creator || IXeldoradoCreatorFactory_LT(creatorfactory).isCreatorAdmin(creator, msg.sender),'Xeldorado: only creator or admins');
        _;
    }
    
    constructor () {
        creator = msg.sender; // Creator 
        allNFTs=0;
        unlocked = 1;
    }

    // only creator factory can initialise
    function initialise(string memory _name, string memory _symbol, address _token, address _dao) public virtual override {
        require(token==address(0),'Xeldorado: initialised');
        creatorfactory = msg.sender; // function called via creator factory
        nftcontract = new CreatorNFT_LT(creator,_name,_symbol);
        nftContract = address(nftcontract);
        token = _token;
        dao = _dao;
    }
    
    // only creator or admins can call
    function mintNFTUsingVaultContract(string[] memory _tokenURI) public virtual override onlyCreatorOrAdmins lock {
        (uint start, uint end) = nftcontract.createBatchToken(_tokenURI, address(this));
        
        for(uint i;i<end-start+1;i++)
        {
            vaultIdTonftContract[allNFTs] = address(nftcontract);
            vaultIdToTokenId[allNFTs] = start+i;
            allNFTs +=  1;
            emit NFTadded(vaultIdTonftContract[allNFTs-1], vaultIdToTokenId[allNFTs-1], allNFTs-1);
        }
    }

    function listNFTsForSale(uint[] memory vaultIds, uint[] memory priceInCreatorTokenss) public virtual override onlyCreatorOrAdmins lock {
        require(vaultIds.length==priceInCreatorTokenss.length,'Xeldorado: unbalanced array');
        for(uint i=0;i<vaultIds.length;i++){
            require(vaultIdTonftPrice[vaultIds[i]] == 0 ,'Xeldorado: already listed');
            require(IERC721(vaultIdTonftContract[vaultIds[i]]).ownerOf(vaultIdToTokenId[vaultIds[i]]) == address(this) ,'Xeldorado: already sold');
            vaultIdTonftPrice[vaultIds[i]] = priceInCreatorTokenss[i];
            allOnSaleNFTs +=1;
            emit NFTListed(vaultIds[i], priceInCreatorTokenss[i]);
        }
    }

    function updateNFTPrice(uint[] memory vaultIds, uint[] memory priceInCreatorTokenss) public virtual override onlyCreatorOrAdmins lock {
        require(vaultIds.length==priceInCreatorTokenss.length,'Xeldorado: unbalanced array');
        for(uint i=0;i<vaultIds.length;i++){
            require(vaultIdTonftPrice[vaultIds[i]] != 0 ,'Xeldorado: not listed');
            vaultIdTonftPrice[vaultIds[i]] = priceInCreatorTokenss[i];
            if(priceInCreatorTokenss[i] == 0){
                allOnSaleNFTs -= 1;
            }
            emit NFTListingUpdate(vaultIds[i], priceInCreatorTokenss[i]);
        }
    }
    
    function buyNFT(address _to, uint[] memory _vaultIds) public virtual override lock {
        for(uint i;i<_vaultIds.length;i++)
        {
            require(IERC721(vaultIdTonftContract[_vaultIds[i]]).ownerOf(vaultIdToTokenId[_vaultIds[i]]) == address(this), 'Xeldorado: Already bought!');
            require(vaultIdTonftPrice[_vaultIds[i]]!=0,'Xeldorado: not for sale');
            IERC721(vaultIdTonftContract[_vaultIds[i]]).transferFrom(address(this), _to, vaultIdToTokenId[_vaultIds[i]]);
            ICreatorToken_LT(token).transferFrom(_to, dao, vaultIdTonftPrice[_vaultIds[i]]);
            ICreatorDAO_LT(dao).currentBalanceUpdate();
            allSoldNFTs += 1;
            allOnSaleNFTs -= 1;
            emit NFTSold(vaultIdTonftContract[_vaultIds[i]], vaultIdToTokenId[_vaultIds[i]], _vaultIds[i],  vaultIdTonftPrice[_vaultIds[i]]);
        }
    }
}