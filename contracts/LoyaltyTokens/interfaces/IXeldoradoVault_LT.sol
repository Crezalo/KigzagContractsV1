// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

interface IXeldoradoVault_LT {
    event NFTadded(address _nft, uint _tokenId, uint vaultid);
    event NFTListed(uint vaultId, uint price);
    event NFTListingUpdate(uint vaultId, uint price);
    event NFTSold(address _nft, uint _tokenId, uint vaultId, uint price);

    function creator() external view returns(address);
    function token() external view returns(address);
    function vaultIdTonftContract(uint) external view returns(address);
    function vaultIdToTokenId(uint) external view returns(uint);
    function vaultIdTonftPrice(uint) external view returns(uint);
    function allNFTs() external view returns(uint);
    function allOnSaleNFTs() external view returns(uint);
    function allSoldNFTs() external view returns(uint);
    function nftContract() external view returns(address); 

    // only creator factory can initialise
    function initialise(string memory _name, string memory _symbol, address _token) external;

    function buyNFT(address _to, uint[] memory _vaultIds) external;

    // only creator or admins can call
    function mintNFTUsingVaultContract(string[] memory _tokenURI) external;
    function listNFTsForSale(uint[] memory vaultIds, uint[] memory priceInBaseTokens) external;
    function updateNFTPrice(uint[] memory vaultIds, uint[] memory priceInBaseTokens) external;
}