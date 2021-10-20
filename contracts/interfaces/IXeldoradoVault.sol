// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

interface IXeldoradoVault {
    event NFTadded(address _nft, uint _tokenId);
    event NFTRedeemed(address _nft, uint _tokenId);
    event liquidityFillStarted(address _token, address _basetoken, uint _minpriceofbasetoken);
    event liquidityFillEnded(address _pair);
    event NFTReturned(address owner, uint vaultId);
    
    function admin() external view returns(address);
    function creator() external view returns(address);
    function token() external view returns(address);
    function basetoken() external view returns(address);
    function vaultIdTonftContract(uint) external view returns(address);
    function vaultIdToTokenId(uint) external view returns(uint);
    function allNFTs() external view returns(uint);
    function redeemedNFTs(uint) external view returns(uint);
    function minpriceofbasetoken() external view returns(uint);
    function pair() external view returns(address); 
    function startliquidfill() external view returns(uint);
    function initialBalance() external view returns(uint);
    
    function initialize(address _token) external;
    function addMintedNFTERC(address _nft, uint _tokenId) external;
    function addNFTByCreateNewCollection(string memory _tokenURI) external;
    function singleNFTPrice() external view returns(uint);
    function singleNFTReturnPrice() external view returns(uint);
    function redeemNFT(address _to, uint _vaultId) external;
    function ReturnOfRedeemedNFT(address _to, uint _vaultId) external;
    function initializeLiquidityOffering(address _basetoken, uint _minpriceofbasetoken, address _pair, uint _days) external ;
    function endLiquidityFilling() external;
    function bidCreatorToken(address _buyer, uint _amount, uint _bidpriceofbasetoken, uint _xfee, uint _cfee, address _feeTo) external returns(bool success);
    function viewLiquidityFiling() external returns (uint percent);
}