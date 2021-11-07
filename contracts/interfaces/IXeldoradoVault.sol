// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.4;

interface IXeldoradoVault {
    event NFTadded(address _nft, uint _tokenId);
    event NFTRedeemed(address _nft, uint _tokenId);
    event liquidityFillStarted(address _token, address _basetoken, uint _minpriceofbasetoken);
    event liquidityFillEnded(address _pair);
    event NFTReturned(address owner, uint vaultId);
    event biddingCreatorToken(address _buyer,uint _amount, uint _bidpriceofbasetoken);
    event migrationVaultRequestCreated();    
    event migrationVaultRequestApproved(address toContract);

    // function admin() external view returns(address);
    function creator() external view returns(address);
    function creatorVestingVault() external view returns(address);
    function token() external view returns(address);
    function basetoken() external view returns(address);
    function vaultIdTonftContract(uint) external view returns(address);
    function vaultIdToTokenId(uint) external view returns(uint);
    function vaultIdTodrirectNFTTrasnfer(uint) external view returns(bool);
    function allNFTs() external view returns(uint);
    function redeemedNFTs(uint) external view returns(uint);
    function allRedeemedNFTs() external view returns(uint);
    function minpriceofbasetoken() external view returns(uint);
    function pair() external view returns(address); 
    function startliquidfill() external view returns(uint);
    function initialBalance() external view returns(uint);
    function FLOBalance() external view returns(uint); 
    function ICTOmin() external view returns(uint); 
    
    function initialize(address _token, address _creatorVestingVault) external;
    function addMintedNFTERC(address _nft, uint _tokenId) external;
    function addNFTByCreateNewCollection(string memory _tokenURI) external;
    function addNFTByCreateNewCollection_Batch(string[] memory _tokenURI) external;
    function singleNFTPrice() external view returns(uint);
    function redeemNFT(address _to, uint _vaultId, uint _xfee, address _feeTo) external;
    function ReturnOfRedeemedNFT(address _to, uint _vaultId, uint _xfee, address _feeTo) external;
    function initializeLiquidityOffering(address _basetoken, uint _minpriceofbasetoken, address _pair, uint _min) external ;
    function addTokensForFLO(uint amount) external;
    function initializeFurtherLiquidityOffering(uint _min) external ;
    function endLiquidityFilling() external;
    function bidCreatorToken(address _buyer, uint _amount, uint _bidpriceofbasetoken, uint _xfee, uint _cfee, address _feeTo) external;
    function viewLiquidityFiling() external view returns (uint percent);
    function approveDirectNFTTransfer(uint vaultId) external;
    function directTransferNFT(uint _vaultId, address _to) external;
    function migrateNFTToV2_createRequest() external;
    function migrationApprove(address toContract) external;
}