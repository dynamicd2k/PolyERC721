//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "./ERC721Permit.sol";
import "./Ownable.sol";
import "./Mintable.sol";

contract PolyERC721 is Ownable, Mintable, ERC721Permit{
// Token name
    string private _nameNFT;

    // Token symbol
    string private _symbolNFT;

    //Admin address
    address private _admin;

    //Last minted token
    uint256 totalTokens=0;

    // Mapping from token ID to owner address
    mapping(uint256 => address)  _owners;

    // Mapping owner address to token count
    mapping(address => uint256)  _balancesNFT;

    //Mapping token id to token auction status
    mapping(uint256 =>bool) _tokenAuctionStatus;

    //Mapping token id to token auction value
    mapping(uint256=>uint256) _tokenAuctionValue;

    //Mapping token id to staking/locking status
    mapping(uint256=>bool) _staked;

    //Mapping the token id to release time
    mapping(uint256=>uint256) _releaseTime;

    event TransferNFT(address, address, uint256);
    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory nftName, string memory nftSymbol, address owner) {
        _nameNFT = nftName;
        _symbolNFT = nftSymbol;
        _admin= owner;
        startMint();
    }
    /**
     * @dev mintNFT : function to mint NFT to to address
     * @param tokenId - id of token to be minted.
     * @param to - address of token receiver 
     */
        function mintNFT(uint256 tokenId, address to) public returns(bool) {
        require(to != address(0), "ERC721: mint to the zero address not allowed");
        require(_mintStatus!= false, "Minting is paused, please check back once contract owner allows minting");
        _balancesNFT[to] += 1;
        _owners[tokenId] = to;
        _tokenAuctionValue[tokenId]=1;          //Floor price of all tokens is 1ETH
        totalTokens= totalTokens+1;
        emit TransferNFT(address(this), to, totalTokens);
        return true;

    }

    /**
     * @dev transferNFT : function to transfer NFT to receiver
     * @param from - address of token sender
     * @param to - address of token receiver 
     * @param tokenId - id of token to be transferred
     */
        function transferNFT(
        address from,
        address to,
        uint256 tokenId
    ) public returns(bool) {
        require(_exists(tokenId)!=address(0), "ERC721Metadata: URI query for nonexistent token");
        require(ownerOfNFT(tokenId) == msg.sender, "ERC721: transfer initiated from non-owner");
        require(to != address(0), "ERC721: transfer to the zero address");
        require(_transferStatus!= false, "Transfer of NFT is paused, check back once contract owner allows minting");

        _balancesNFT[from] -= 1;
        _balancesNFT[to] += 1;
        _owners[tokenId] = to;

        emit TransferNFT(from, to, tokenId);
        return true;
    }

    //Note: signature is created on the frontend by the wallet holding the private key
    //for this assignment, signature is generated in test case file using ethers.
     /**
     * @dev permitSpender : function to permit spender to transfer NFT
     * @param tokenId - id of token to be pemritted
     * @param signature - signed transaction from wallet/private key of owner of token
     */
    function permitSpender(uint256 tokenId, bytes memory signature) public returns(bool){
        require(_exists(tokenId)!=address(0), "ERC721Metadata: URI query for nonexistent token");
        require(ownerOfNFT(tokenId)==msg.sender, "Only owner of the token can permit on the token");
        uint8 nonce= nonces(tokenId);
        incrementNonce(tokenId);
        bytes32 digest = buildDigest(msg.sender, tokenId, nonce);
        permit(msg.sender, tokenId, signature, digest);
        return checkPermit(msg.sender,tokenId);
    }

    /// @notice Builds the permit digest to sign
    /// @param spender the token spender
    /// @param tokenId the tokenId
    /// @param nonce the nonce to make a permit for
    /// @return the digest (following eip712) to sign
    function buildDigest(
        address spender,
        uint256 tokenId,
        uint8 nonce
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode("\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encode(
                        spender,
                        tokenId,
                        nonce
                    )
                )
        )
        );
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOfNFTOwner(address owner) public view virtual  returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balancesNFT[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOfNFT(uint256 tokenId) public view virtual  returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function nameOfNFT() public view virtual  returns (string memory) {
        return _nameNFT;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbolOfNFT() public view virtual  returns (string memory) {
        return _symbolNFT;
    }
    
    /**
    * @dev getTotalTokens- retrieve total number of minted tokens
     */
    function getTotalTokens() public view returns(uint256){
        return totalTokens;
    }

     /**
    * @dev burnStatus- retrieve current burn status
     */
    function burnStatus() public view returns(bool){
        return _burnStatus;
    }
     /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual  returns (string memory) {
        require(_exists(tokenId)!=address(0), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = "";
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId)) : "";
    }
    
    /**
     * @dev burnToken : function to burn NFT to address(0)
     * @param tokenId - id of token to be burned
     */
    function burnToken(uint256 tokenId) public returns(bool){
        require(burnStatus()!=false, "Burn action is not allowed now. Please check back once contract owner allows minting");
        require(msg.sender== ownerOfNFT(tokenId), "Only owner of the token can burn the tokens");
        _balancesNFT[ownerOfNFT(tokenId)]= _balancesNFT[ownerOfNFT(tokenId)]-1;
        _owners[tokenId]= address(0);
        totalTokens= totalTokens-1;
        emit TransferNFT(owner, address(0), tokenId);
        return true;
    }

     /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev startAuctionNFT : function to start NFT auction
     * @param tokenId - id of token to be auctioned
     * @param value - auction value
     */
    function startAuctionNFT(uint256 tokenId, uint256 value) public returns(bool){
        require(_exists(tokenId)!=address(0), "ERC721Metadata: URI query for nonexistent token");
        require(ownerOfNFT(tokenId)==msg.sender, 'Only owner can set NFT for auction');
        _tokenAuctionStatus[tokenId]= true;
        _tokenAuctionValue[tokenId]= value;
        return true;
    }

    /**
     * @dev startAuctionNFT : function to end NFT auction
     * @param tokenId - id of token to end auctioned
     */
    function endAuctionNFT(uint256 tokenId) public returns(bool){
        require(_exists(tokenId)!=address(0), "ERC721Metadata: URI query for nonexistent token");
        require(ownerOfNFT(tokenId)==msg.sender, 'Only owner of token can end NFT auction');
        _tokenAuctionStatus[tokenId]= false;
        return true;
    }

    /**
     * @dev buyNFT : function to buy NFT
     * @param to - address to send the NFT
     * @param tokenId - id of token to be bought
     */
    function buyNFT(address to, uint256 tokenId) public payable returns(bool){
        require(_exists(tokenId)!=address(0), "ERC721Metadata: URI query for nonexistent token");
        require(msg.value >=_tokenAuctionValue[tokenId], "ERC20Metadata: Insufficient funds");
        require(_tokenAuctionStatus[tokenId]== true, "Token not available to be purchased");
        require(_staked[tokenId]== false, "Token staked, not available to be purchased");
        payable(ownerOfNFT(tokenId)).transfer(msg.value);
        _balancesNFT[_owners[tokenId]] -= 1;
        _balancesNFT[to] += 1;
        _owners[tokenId] = to;
        emit TransferNFT(msg.sender, to, tokenId);
        return true;
    }

    /**
     * @dev sellNFT : function to sell NFT
     * @param tokenId - id of token to be sold
     */
    function sellNFT(uint256 tokenId) public payable returns(bool){
        require(_exists(tokenId)!=address(0), "ERC721Metadata: URI query for nonexistent token");
        require(ownerOfNFT(tokenId)==msg.sender, "Only token owner can sell the NFT");
        require(_staked[tokenId]== false, "Token staked, not available to be sold");
        _balancesNFT[msg.sender]= _balancesNFT[msg.sender]-1;
        _owners[tokenId]= _admin;
        return true;
    }

    /**
     * @dev stakeNFT : function to stake NFT
     * @param tokenId - id of token to be staked
     * @param lockPeriodInDays- Number of days to lock the NFT
     */
    function stakeNFT(uint256 tokenId, uint256 lockPeriodInDays) public returns(bool){
        require(_exists(tokenId)!=address(0), "ERC721Metadata: URI query for nonexistent token");
        require(ownerOfNFT(tokenId)== msg.sender,"Only owner can stake NFT");
        require(_staked[tokenId]== false, "Token staked already");
        _tokenAuctionStatus[tokenId]= false;
        _releaseTime[tokenId]=block.timestamp+lockPeriodInDays*24*60*60*1000;
        _staked[tokenId]= true;
        return true;
    }

     /**
     * @dev release : function to release NFT
     * @param tokenId - id of token to be released
     */
    function release(uint256 tokenId) public returns(bool){
        require(_exists(tokenId)!=address(0), "ERC721Metadata: URI query for nonexistent token");
        require(block.timestamp>=releaseTime(tokenId), "TokenTimelock: current time is before release time");
        _staked[tokenId]=false;
        return true;
    }
    
     /**
     * @dev releaseTime : function to view releaseTime of NFT
     * @param tokenId - id of token
     */
    function releaseTime(uint256 tokenId) public view returns (uint256) {
        return _releaseTime[tokenId];
    }

     /**
     * @dev ownerOfContract : function to address of contract owner
     */
    function ownerOfContract() public view returns(address){
        return _admin;
    }

    /**
     * @dev checkTokenAuctionValue : function to view token auction value
     */
    function checkTokenAuctionValue(uint256 tokenId) public view returns(uint256){
        return _tokenAuctionValue[tokenId];
    }
    
    /**
     * @dev checkTokenAuctionStatus : function to view token auction status
     */
    function checkTokenAuctionStatus(uint256 tokenId) public view returns(bool){
        return _tokenAuctionStatus[tokenId];
    }

     /**
     * @dev isTokenStaked : function to view token staked status
     */
    function isTokenStaked(uint256 tokenId) public view returns(bool){
        return _staked[tokenId];
    }
    }