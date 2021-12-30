// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

interface IXeldoradoVault {
    event NFTadded(address _nft, uint _tokenId);
    event NFTRedeemed(address _nft, uint _tokenId);
    event NFTReturned(address owner, uint vaultId);
    event NFTSwapped(address owner, uint inVaultId, uint outVaultId);
    event liquidityFillStarted(address _token, address _basetoken, uint _minpriceofbasetoken);
    event liquidityFillEnded(address _pair);
    event biddingCreatorToken(address _buyer,uint _amount, uint _bidpriceofbasetoken); 
    // event migrationVaultCompleted(address toContract);
    event migrationVaultBatchCompleted(address toContract, uint start, uint end);
    // event directTransferNFTCompleted(uint vaultId, address to);

    function creator() external view returns(address);
    function factory() external view returns(address);
    function creatorDAO() external view returns(address);
    function token() external view returns(address);
    function basetoken() external view returns(address);
    function vaultIdTonftContract(uint) external view returns(address);
    function vaultIdToTokenId(uint) external view returns(uint);
    function allNFTs() external view returns(uint);
    // function redeemedNFTs(uint) external view returns(uint);
    function allRedeemedNFTs() external view returns(uint);
    function minpriceofbasetoken() external view returns(uint);
    function pair() external view returns(address); 
    function nftContract() external view returns(address); 
    function startliquidfill() external view returns(uint);
    function initialBalance() external view returns(uint);
    function FLOBalance() external view returns(uint); 
    function ICTOduration() external view returns(uint); 
    function dependenciesUpdated() external view returns(bool); 
    
    function initialize(address _token, address _creatorVestingVault) external;
    function singleNFTPrice() external view returns(uint);
    function redeemNFT(address _to, uint[] memory _vaultIds) external;
    function returnOfRedeemedNFT(address _to, uint[] memory _vaultIds) external;
    function swapNFT(address _swapper, uint[] memory _inVaultIds, uint[] memory _outVaultIds) external;
    function endLiquidityFilling() external;
    function bidCreatorToken(address _buyer, uint _amount, uint _bidpriceofbasetoken) external;
    function viewLiquidityFiling() external view returns (uint percent);

    // only creator or admins can call
    function addMintedNFTToVault(address[] memory _nftContracts, uint[] memory _tokenIds) external;
    function mintNFTUsingVaultContract(string[] memory _tokenURI) external;
    function initializeLiquidityOffering(address _basetoken, uint _minpriceofbasetoken, uint _min) external;
    function addTokensForFLO(uint amount) external;
    function initializeFurtherLiquidityOffering(uint _min) external;
    // function directTransferNFT(uint[] memory vaultIds, address _to) external;

    // only migration contract can call
    // function migrateVault(address toContract) external;
    function migrateVaultBatchTransfer(address toContract, uint start, uint end) external;

    // only pair can call
    function updatePair(address toContract) external;

    // only DAO can call
    function updateCreatorDAO(address toContract) external;
}