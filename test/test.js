const { expect } = require('chai')
const { deployments, ethers } = require('hardhat')
const { keccak256 } = require('@ethersproject/keccak256')
const { toUtf8Bytes } = require('ethers/lib/utils')

const zeroAddr = 0

before(async () => {
  ;[owner, addr1, addr2, addr3, addr4, addr5, addr6, addr7, addr8, addr9, addr10] = await ethers.getSigners()

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
        await expect(poly.connect(addr2).startAuctionNFT(1,10)).to.be.revertedWith("Only owner can set NFT for auction");
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
        await poly.mintNFT(6, addr6.address);
        await poly.connect(addr6).stakeNFT(6,100);
        expect(await poly.isTokenStaked(6)).to.equal(true);
    })
    it("NFT can be staked only by owner", async function(){
        await poly.mintNFT(1, addr1.address);
        await expect(poly.connect(addr2).stakeNFT(1,100)).to.be.revertedWith("Only owner can stake NFT");
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
        await poly.connect(addr1).startAuctionNFT(1,10);
        await expect(poly.connect(addr2).buyNFT(addr2.address,11, { value: ethers.utils.parseEther("10") })).to.be.revertedWith("ERC721Metadata: URI query for nonexistent token");
    })
    it("Token can be bought only if auction status is enabled for the token", async function(){
        await poly.mintNFT(1, addr1.address);
        await poly.connect(addr2).buyNFT(addr2.address,1, { value: ethers.utils.parseEther("10") });
    })
    it("Token can be bought only if token is not staked", async function(){
        await poly.mintNFT(1, addr1.address);
        await poly.connect(addr1).startAuctionNFT(1,10);
        await poly.connect(addr2).buyNFT(addr2.address,1, { value: ethers.utils.parseEther("10") });
        expect(await poly.ownerOfNFT(1)).to.equal(addr2.address);
    })
})

describe('Sell NFT', function () {
  it('Token can be sold only if it exists', async function () {
    await poly.mintNFT(1, addr1.address)
    await expect(poly.connect(addr1).sellNFT(11)).to.be.revertedWith("ERC721Metadata: URI query for nonexistent token")
  })
  it('Token can be sold only by the owner', async function () {
    await poly.mintNFT(1, addr1.address)
    await poly.connect(addr1).sellNFT(1)
    expect(await poly.ownerOfNFT(1)).to.equal(owner.address)
  })
  it('Token cannot be sold by non owner', async function () {
    await poly.mintNFT(1, addr1.address)
    await expect(poly.connect(addr2).sellNFT(1)).to.be.revertedWith("Only token owner can sell the NFT")
  })
  it('Token owner changes to contract owner once the token is sold', async function () {
    await poly.mintNFT(1, addr1.address)
    await poly.connect(addr1).sellNFT(1)
    expect(await poly.ownerOfNFT(1)).to.equal(owner.address)
  })
})

describe("Burn", function(){
    it("Burn should send the token to address(0)", async function(){
        await poly.mintNFT(1, addr1.address);
        await poly.allowBurn();
        await poly.connect(addr1).burnToken(1);
        expect(await poly.ownerOfNFT(1)).to.not.equal(addr1.address);
    })
    it("After token is burn, total number of tokens should reduce by 1 ", async function(){
        // await poly.allowBurn();
        await poly.mintNFT(1, addr1.address);
        const numberOfTokensBeforeBurn= await poly.getTotalTokens();
        await poly.connect(addr1).burnToken(1);
        expect(await poly.getTotalTokens()).to.equal(numberOfTokensBeforeBurn-1);
    })
    it("Only if burn is allowed, tokens are allowed to be burn", async function(){
        await poly.mintNFT(1, addr1.address);
        await poly.restrictBurn();
        // expect(await poly.burnStatus()).to.equal(true);
        await expect( poly.connect(addr1).burnToken(1)).to.be.revertedWith("Burn action is not allowed now. Please check back once contract owner allows minting");
    })
    it("Only owner of NFT should be allowed to burn it", async function(){
        await poly.mintNFT(1, addr1.address);
        await poly.allowBurn();
        await expect( poly.connect(addr2).burnToken(1)).to.be.revertedWith("Only owner of the token can burn the tokens");
    })
})

describe('Transfer', function () {
  it('Transfer should send token from owner to receiver', async function () {
    await poly.mintNFT(9, addr9.address)
    await poly.connect(addr9).transferNFT(addr9.address, addr7.address, 9)
    expect(await poly.ownerOfNFT(9)).to.equal(addr7.address)
  })
  it('Transfer should reduce token balance in senders account', async function () {
    expect(await poly.balanceOfNFTOwner(addr9.address)).to.equal(0)
  })
  it('Transfer should increase token balance for receiver', async function () {
    expect(await poly.balanceOfNFTOwner(addr7.address)).to.equal(1)
  })
  it('Transfer should fail if the transfer is intiated by non holder of NFT', async function () {
    await poly.mintNFT(5, addr5.address)
    await expect(
      poly.connect(addr4).transferNFT(addr5.address, addr4.address, 5),
    ).to.be.revertedWith('ERC721: transfer initiated from non-owner')
  })
  it('Transfer should fail for a non existent token', async function () {
    await expect(
      poly.connect(addr3).transferNFT(addr3.address, addr2.address, 20),
    ).to.be.revertedWith('ERC721Metadata: URI query for nonexistent token')
  })
})

describe('Permit', () => {
    // helper to sign using (spender, tokenId, nonce) EIP 712
    async function sign(requestData, signer) {
        // sign Permit
        const signature = await signer.signMessage(requestData);
        // console.log(signature);
        return signature;
    }
    function buildDigest(
         spender,
         tokenId,
         nonce
    ) {
        const requestData=spender+tokenId+nonce;
        const rD= ethers.utils.arrayify(requestData);
        const diges= ethers.utils.hashMessage(rD);
        return diges;
    }

    function recoverAddress (requestHash, signature){
        const rA= ethers.utils.verifyMessage(requestHash, signature);
        return rA;
    }

    it("Permit spender only if token exists", async function(){
        await poly.mintNFT(1, addr1.address);
        await expect(await poly.nonces(10)).to.equal(0);
    })
    it("Permit only if token is held by the permit signer", async function(){
        const nonce = await poly.nonces(1);
        const digest= await buildDigest(addr1.address, 1, nonce);
        const signature= await sign(digest, addr2);
        const recoveredAdd= recoverAddress(digest, signature);
        expect(recoveredAdd).to.not.equal(addr1.address);
    })
    it("Only if transaction digest is signed by correct owner of token/spender", async function(){
        const nonce = await poly.nonces(1);
        const digest= await buildDigest(addr1.address, 1, nonce);
        const signature= await sign(digest, addr1);
        const recoveredAdd= recoverAddress(digest, signature);
        expect(recoveredAdd).to.equal(addr1.address);
    })
})
