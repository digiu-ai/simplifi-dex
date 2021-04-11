# Contracts DEX
Smart contracts consists of 3 main contracts 

1) https://github.com/digiu-ai/simplifi-dex/blob/dex_refactor/contracts/Synthesis.sol
Synthesis responsible for minting and burning a pegged tokens 

2) https://github.com/digiu-ai/simplifi-dex/blob/dex_refactor/contracts/Portal.sol
Portal contract responsible for pegged token vault 

3) https://github.com/digiu-ai/simplifi-dex/blob/dex_refactor/contracts/Bridge.sol
Bridge contract responsible for offchain communications 


# Use cases

## Add liquidity

Precondition: the user has connected two wallets: 
BSC (Binance Chain Wallet) and Ethereum (Metamask) and he has both assets (ETH and BNB)

Result: user created a cross-chain pool

1. User clicks `Add Liquidity`;
2. The user selects the active one who wants to add. 
   By default selected ETH to Ethereum and BNB to BSC;
3. The system displays a list of assets for each chain;
4. User selects ETH;
5. The system displays the balance of the ETH wallet;
6. The system displays the `Confirm ETH` button;
7. User clicks `Confirm ETH`;
8. The system calls confirmation on the smart contract of the selected token;
9. The user selects the 2nd asset;
10. Makes it approve on the BSC chain;
11. The system displays the estimated user share in the pool;
12. User clicks `Add Liquidity`;
13. The system calls `synthesize` on the BSC `Portal` contract with params:
    - WBNB contract address;
    - BNB amount;
    - Ethereum wallet address where to transfer synthetic BNB.
14. BSC Portal accept BNB amount and call `Bridge` to `Mint synthetic BNB` on Ethereum chain;
14.`Bridge` calls method `mintSyntheticToken` on `Synthesis` contract on Ethereum chain to mint synthetic BNB on Ethereum chain;
15. `Synthesis` send minted synthetic BNB to user on Ethereum chain; 
16. The system calls the function `Add Liquidity` with pair 
    `ETH + synthetic BNB` on the Ethereum chain;
17. Success.

Link to sequence diagram http://is.gd/JYtC2v

# Cross-chain swap

Precondition: the user has connected two wallets:
BSC (Binance Chain Wallet) and Ethereum (Metamask) and he has ETH asset

Result: user received asset BNB on BSC

1. User clicks `Swap`;
2. The user selects the active one who wants to swap.
   By default selected ETH to Ethereum and BNB to BSC;
3. The system displays a list of assets for each chain;
4. User selects ETH;
5. The system displays the balance of the ETH wallet;
6. The system displays the `Confirm ETH` button;
7. User clicks `Confirm ETH`;
8. The system calls confirmation on the smart contract of the selected token;
9. The user selects the 2nd asset (BNB);
10. Makes it approve on the BSC chain;
11. The system displays the estimated amount of BNB;
12. User clicks `Swap`;
13. The system swap ETH to synthetic BNB 
14. The system calls method `burnSyntheticToken` on `Synthesize` Ethereum contract with params:
    - Synthetic BNB contract address;
    - Synthetic BNB amount;
    - BSC wallet address where to transfer original BNB.
15. `Synthesis` call `Bridge` to `Burn synthetic BNB` on Ethereum chain;
14. `Bridge` calls method `unsynthesize` on `Portal` contract on BSC; 
15. `Portal` send original BNB to user on BSC;
17. Success.

Link to sequence diagram http://is.gd/63CbQ6