// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface ICreatorNFT_LT is IERC721Metadata {
    function creator() external view returns(address);
    
    // only vault can call
    function createToken(string memory tokenURI,address _vault) external returns (uint); 
    function createBatchToken(string[] memory tokenURI, address _vault) external returns(uint start, uint end); 
}