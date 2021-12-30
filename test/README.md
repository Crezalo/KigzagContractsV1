# Smart Contract Address

1. Deployer 
   - Factory 
   - Route 
   - Exchange Token 
2. Buyer/consumer: multiple addresses 
   - Deploy  
     - WETH(Base Token) 
3. Creator: multiple addresses 
   - Deploy 
     - Vault 
     - DAO 
4. Fee To Setter 
5. Migration Contract 
6. Creator Admins: multiple addresses 

# Process to test E2E contracts manually: (Ak-> Address at index k from above) 

We will divide it into 3 phases

## Phase 1: Initialization 
1. Using A2 deploy WETH 
2. Using A1 deploy ET, Factory, Route 
3. Try updating and resetting all values in Factory via A4 
4. Using A1 Transfer 30000000000000000000 X tokens to A2 
5. Using A3  
   1. Call newCreator, pass fees 
   2. Call setCreatorAdmins for A6 
   3. Call getCreatorAdmins 
   4. Deploy Vault, with name and symbol 
   5. Deploy DAO 
   6. Call generateCreatorVault 
   7. Add NFT to the vault  
6.  Using A6 try adding NFTs to vault 
7.  Using A3, airdrop some token to A2, A6, A4 
8.  Approve large amount of allowance to Vault for WETH using A2 so that buying can be done fast 
9.  Using A3 
    1.  Initialise ICTO for 420 seconds 


## Phase 2: Trading/Functionality Tests 
1. Using A2 
   1. Bid in ICTO 
2. Using A1 transfer 30000000000000000000 x tokens to A2 
3. Using A2 
   1. Bid in ICTO
4. Using A3 try redeeming Creator Tokens from Vesting Vault 
5. Using A2 
   1. Swap Creator tokens for Base token in Pair (3 times) 
   2. Swap Base tokens for Creator token in Pair (3 times) 
6.  Using A2  
    1.  Redeem NFT (3 times) 
    2.  Swap NFT 
    3.  Return NFT 
7.  Using A3 add NFTs to Vault 
8.  Using A4, set noOfEtForDiscount to 100000000000000000000  
9.  Repeat Step 6
10. Using A3  
    1.  Add A4 as manager 
    2.  Remove A4 as manager  
11. Using A6  
    1.  Add A2, A4 as manager 
12. Using A4 call airdrop Proposal with some amount 
13. Vote using A2,A3,A4,A6 
14. Call UpdateAirdropAmount 
15. Using A6 
    1.  Perform Airdrop 
16. Using A6 call FLO Proposal with some amount 
17. Vote using A2,A3,A4,A6 
18. Call UpdateFLOAmount 
19. Using A3  
    1.  Call addFLOTokens in Vault 
    2.  Initialise FLO 
20. Approve large amount ofallowance to Vault for WETH using A2 so that buying can be done fast 
21. Using A3 
    1.  Initialise FLO for 420 seconds 
22. Using A2 
    1.  Bid in ICTO 
23. Using A3 try redeeming Creator Tokens from Vesting Vault 
24. Using A6 call Allowances Proposal with some amount for A2,A6 
25. Using A6 call Allowances Proposal with some amount for A2 
26. Vote using A2,A3,A4,A6 
27. Call UpdateAllowancesAmount 
28. Using A2 transfer allowance to A1,A4,A5 
29. Call sendAllowances to batch transfer to A1,A4,A5 
30. Using A1 
    1.  Call redeemAllowances to redeem some amount 
31. Using A6 call general Proposal  
32. Vote using A2,A3,A4,A6 
33. Using A3 
    1.  Call removeCreatorAdmins for A6 
    2.  Call getCreatorAdmins 
    3.  Call isCreatorAdmins for A6 
    4.  Call setCreatorAdmins for A6 
    5.  Call isCreatorAdmins for A6 
    6.  Call setCreatorBank  
    7.  Call UpdateCreatorSwapFee 
    8.  Call UpdateCreatorNFTFee 
    9.  Call UpdateCreatorCTOFee 

## Phase 3: Exit/Migration 
1. Using A4, 
   1. Call MigrationContract as A4 
   2. Call MigrationDuration as 420 seconds 
   3. Call MigrationContractVotingInitialise from CreatorToken 
2. Vote using A2,A3,A4,A6 
3. Call syncMigrationContractVoting from CreatorFactory 
4. Using A4(as migration Contract), 
   1. Call migrateVault 
   2. Call migrateDAO 
   3. Call migratePair 

 