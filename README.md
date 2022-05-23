# Homemade ERC721 token with permit.

This project demonstrates a homemade ERC721 token with functionalities as discussed below:

1. Permit: Enables allowing for spenders to be permitted to transfer,buy,sell or burn an NFT.

2. Mint: Any user with a valid EOA can call this contract function to mint an NFT to receivers address.

3. Transfer: Any holder of NFT can initiate a transfer of NFT to receiver if permitted.

4. Burn Token: Any holder of a NFT can initiate a burn if permitted. Token is sent to 0 address in this case.

5. Auction NFT: Holder of NFT can put a NFT on auction or pull the NFT off auction.

6. Buy NFT: A person with valid wallet can request the smart contract to buy a NFT that is available for auction at auction value by sending the auction value to current owner of NFT.

7. Sell NFT: A holder of Poly NFT can initiate a sell on NFT if the NFT is not staked.

8. Stake NFT: A holder of NFT can stake the NFT if not already staked.

9. Release: A staked NFT can be unstaked by calling this function if the lock period of the NFT is over.

Helpers:

ReleaseTime: To check release time of a staked NFT.
Onwer of Contract: To check the owner of contract.
Token Auction Status: Current auction status of a NFT.
Token Auction Value: Current auction buy value of a NFT.
Token staked status: Check if a token is staked.

To compile the contracts:

npx hardhat compile

To run test cases:

npx hardhat test


Some other hardhat shell commands:

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
node scripts/sample-script.js
npx hardhat help
```
