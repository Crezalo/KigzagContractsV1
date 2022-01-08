//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import './interfaces/ICreatorNFT_LT.sol';

contract CreatorNFT_LT is ERC721URIStorage, ICreatorNFT_LT {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address public override creator;
    address vault;
    
    constructor(address _creator, string memory _name, string memory _symbol) ERC721(_name, _symbol){
        creator = _creator;
        vault = msg.sender;
    }   

    function createToken(string memory tokenURI,address _vault) public virtual override returns (uint){
        require(msg.sender==vault,'Xeldorado: only vault can create tokens');
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        
        _mint(_vault, newItemId);
        _setTokenURI(newItemId,tokenURI);
        return newItemId;
    }
    
    function createBatchToken(string[] memory tokenURI, address _vault) public virtual override returns(uint start, uint end){
        require(msg.sender==vault,'Xeldorado: only vault can ctreate tokens');
        start = _tokenIds.current() + 1;
        for(uint i;i<tokenURI.length;i++){
            _tokenIds.increment();
            _mint(_vault, _tokenIds.current());
            _setTokenURI(_tokenIds.current(),tokenURI[i]);
        }
        end = _tokenIds.current();
    }
}
