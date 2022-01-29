// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

interface ICreatorVault_LT {
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
    function initialise(address _creator, string memory _name, string memory _symbol, address _token) external;

    // caller will be buyer
    function buyNFT(uint[] memory _vaultIds) external;

    // only creator or admins can call
    function mintNFTUsingVaultContract(string[] memory _tokenURI) external;
    function listNFTsForSale(uint[] memory vaultIds, uint[] memory priceInBaseTokens) external;
    function updateNFTPrice(uint[] memory vaultIds, uint[] memory priceInBaseTokens) external;
}