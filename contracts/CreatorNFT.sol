//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


contract CreatorNFT is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address public creator;

    constructor(address _creator, string memory _name, string memory _symbol) ERC721(_name, _symbol){
        creator = _creator;
    }   

    function createToken(string memory tokenURI,address _vault) public returns (uint){
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        
        _mint(_vault, newItemId);
        _setTokenURI(newItemId,tokenURI);
        return newItemId;
    }
}
