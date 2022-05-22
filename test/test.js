const { expect } = require('chai')
const { deployments, ethers } = require('hardhat')

before(async () => {
  ;[owner, addr1, addr2, addr3, addr4, addr5] = await ethers.getSigners()

  // get chainId
  chainId = await ethers.provider.getNetwork().then((n) => n.chainId)
  // await deployments.fixture();
  // Get the ContractFactory and Signers here.
  Poly = await ethers.getContractFactory('PolyERC721')
  poly = await Poly.deploy('POLY', 'POL', owner.address)
  await poly.deployed()
})

describe("Token Contract", function () {
    it("Deployment should assign the NFT name ", async function () {
      expect(await poly.nameOfNFT()).to.equal("POLY");
    });
    it("Should assign the symbol of NFT", async function () {
      expect(await poly.symbolOfNFT()).to.equal("POL");
    })
    it("Should assign owner of contract as admin", async function() {
        expect(await poly.ownerOfContract()).to.equal(owner.address);
    })
})

describe("Minter", function(){
    it("Minter should issue a token and assign owner", async function(){
        await poly.mintNFT(1, addr1.address);
        expect(await poly.ownerOfNFT(1)).to.equal(addr1.address);
    })
    it("Minter should issue a token with floor price set to 1 ETH", async function(){
        await poly.mintNFT(1, addr1.address);
        expect(await poly.checkTokenAuctionValue(1)).to.equal(1);
    })
    it("Minter should update owner balance of NFT as 1", async function(){
        await poly.mintNFT(10, addr3.address);
        expect(await poly.balanceOfNFTOwner(addr3.address)).to.equal(1);
    })
})

describe("Auction NFT", function(){
    it("Set NFT auction as enabled", async function(){
        await poly.mintNFT(1, addr1.address);
        await poly.connect(addr1).startAuctionNFT(1,9);
        expect(await poly.checkTokenAuctionStatus(1)).to.equal(true);
    })
    it("Only owner of token can set status for auction", async function(){
        await poly.mintNFT(1, addr1.address);
        await poly.connect(addr2).startAuctionNFT(1,10);
    })
    it("Auction price of the NFT is set", async function(){
        await poly.mintNFT(1, addr1.address);
        await poly.connect(addr1).startAuctionNFT(1, 9);
        expect(await poly.checkTokenAuctionValue(1)).to.equal(9);
    })
    it("End Auction of the NFT only by NFT owner", async function(){
        await poly.mintNFT(1, addr1.address);
        await poly.connect(addr1).endAuctionNFT(1);
        expect(await poly.checkTokenAuctionStatus(1)).to.equal(false);
    })
})

describe("Stake NFT", function(){
    it("Staked NFT is set to staked mapping", async function(){
        await poly.mintNFT(1, addr1.address);
        await poly.connect(addr1).stakeNFT(1,100);
        expect(await poly.isTokenStaked(1)).to.equal(true);
    })
    it("NFT can be staked only by owner", async function(){
        await poly.mintNFT(1, addr1.address);
        await poly.connect(addr2).stakeNFT(1,100);
    })
    it("Staked NFT cannot be auctioned so auction status is set to false", async function(){
        await poly.mintNFT(2, addr2.address);
        await poly.connect(addr2).stakeNFT(2,100);
        expect(await poly.checkTokenAuctionStatus(2)).to.equal(false);
    })
    it("Staked NFT will be set for release time", async function(){
        await poly.mintNFT(3, addr3.address);
        await poly.connect(addr3).startAuctionNFT(3,100);
        expect(await poly.releaseTime(2)).to.not.be.null;
    })
})

describe("Buy NFT", function(){
    it("Token can be bought only if token exists", async function(){
        await poly.mintNFT(1, addr1.address);
        await poly.connect(addr1).startAuctionNFT(1,10);
        await poly.connect(addr2).buyNFT(addr2.address,1, { value: ethers.utils.parseEther("10") });
        expect(await poly.ownerOfNFT(1)).to.equal(addr2.address);
    })
    it("Token cannot be bought if token does not exists", async function(){
        await poly.mintNFT(1, addr1.address);
        await poly.connect(addr1).startAuctionNFT(2,10);
        await poly.connect(addr2).buyNFT(addr2.address,2, { value: ethers.utils.parseEther("10") });
    })
    it("Token can be bought only if auction status is enabled for the token", async function(){
        await poly.mintNFT(1, addr1.address);
        await poly.connect(addr2).buyNFT(addr2.address,1, { value: ethers.utils.parseEther("10") });
    })
    it("Token cann be bought only if token is not staked", async function(){
        await poly.mintNFT(1, addr1.address);
        await poly.connect(addr1).startAuctionNFT(1,10);
        await poly.connect(addr2).buyNFT(addr2.address,1, { value: ethers.utils.parseEther("10") });
        expect(await poly.ownerOfNFT(1)).to.equal(addr2.address);
    })
})

describe('Sell NFT', function () {
  it('Token can be sold only if it exists', async function () {
    await poly.mintNFT(1, addr1.address)
    await poly.connect(addr1).sellNFT(3)
  })
  it('Token can be sold only by the owner', async function () {
    await poly.mintNFT(1, addr1.address)
    await poly.connect(addr1).sellNFT(1)
    expect(await poly.ownerOfNFT(1)).to.equal(owner.address)
  })
  it('Token cannot be sold only by non owner', async function () {
    await poly.mintNFT(1, addr1.address)
    await poly.connect(addr2).sellNFT(1)
  })
  it('Token owner changes to contract owner once the token is sold', async function () {
    await poly.mintNFT(1, addr1.address)
    await poly.connect(addr1).sellNFT(1)
    expect(await poly.ownerOfNFT(1)).to.equal(owner.address)
  })
})

// describe("Transfer", function(){
//     it("Transfer should send token from owner to receiver", async function(){
//         await poly.mintNFT(1, addr1.address);
//         await poly.transferNFT(addr1.address, addr4.address, 1);
//         expect(await poly.ownerOfNFT(1)).to.equal(addr4);
//         expect(await poly.balanceOfNFTOwner(addr1)).to.equal(0);
//         expect(await poly.balanceOfNFTOwner(addr4)).to.equal(1);
//     })
//     it("Transfer should fail if the address does not hold any nft", async function(){
//         const result= await poly.transferNFT(addr5, addr1, 15);
//         console.log(result);
//         // expect(result).to.equal("ERC721Metadata: URI query for nonexistent token");
//     })
//     it("Transfer should fail for a non owner transfer request initiation", async function(){
//         const result= await poly.connect(addr2).transferNFT(addr3, addr2, 3);
//         expect(result).to.equal("ERC721: transfer initiated from non-owner");
//     })

// })

// describe("Burn", function(){
//     it("Burn should send the token to address(0)", async function(){
//         await poly.mintNFT(1, addr1.address);
//         await poly.allowBurn();
//         await poly.connect(addr1).burnToken(1);
//         expect(await poly.ownerOfNFT(1)).to.equal(0);
//     })
//     // it("Only owner of NFT should be allowed to burn it", async function(){
//     //     await poly.mintNFT(1, addr1.address);
//     //     await poly.connect(addr2).burnToken(1);
//     // })
//     // it("Only if burn is allowed, tokens are allowed to be burn", async function(){
//     //     const result= await poly.connect(addr1).burnTokens(1);
//     //     expect(result).to.equal("Burn action is not allowed now. Please check back once contract owner allows minting");
//     // })
//     // it("If burn is allowed, tokens should burn", async function(){
//     //     await poly.connect(allowBurn());
//     //     expect(poly._burnStatus).to.equal(true);
//     //     const result= await poly.connect(addr1).burnTokens(1);
//     //     expect(result).to.equal(true);
//     // })
// })

// describe('Permit', () => {
//     // helper to sign using (spender, tokenId, nonce, deadline) EIP 712
//     async function sign(spender, tokenId, nonce) {
//         const typedData = {
//             types: {
//                 Permit: [
//                     { name: 'spender', type: 'address' },
//                     { name: 'tokenId', type: 'uint256' },
//                     { name: 'nonce', type: 'uint256' },
//                 ],
//             },
//             primaryType: 'Permit',
//             domain: {
//                 name: await contract.name(),
//                 version: '1',
//                 chainId: chainId,
//                 verifyingContract: contract.address,
//             },
//             message: {
//                 spender,
//                 tokenId,
//                 nonce,
//             },
//         };

//         // sign Permit
//         const signature = await deployer._signTypedData(
//             typedData.domain,
//             { Permit: typedData.types.Permit },
//             typedData.message,
//         );

//         return signature;
//     }
// })
