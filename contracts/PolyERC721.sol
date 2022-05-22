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
        totalTokens=totalTokens+1;
        startMint();
    }

        function mintNFT(uint256 tokenId, address to) public returns(bool) {
        require(to != address(0), "ERC721: mint to the zero address not allowed");
        require(_mintStatus!= false, "Minting is paused, please check back once contract owner allows minting");
        _balancesNFT[to] += 1;
        _owners[tokenId] = to;
        _tokenAuctionValue[tokenId]=1;          //Floor price of all tokens is 1ETH

        emit TransferNFT(address(this), to, totalTokens);
        return true;

    }

        function transferNFT(
        address from,
        address to,
        uint256 tokenId
    ) public returns(bool) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(ownerOfNFT(tokenId) == from, "ERC721: transfer initiated from non-owner");
        require(to != address(0), "ERC721: transfer to the zero address");
        require(_transferStatus!= false, "Transfer of NFT is paused, check back once contract owner allows minting");
        require(checkPermit(to, tokenId)==true, "To address not permitted to make this transaction");

        _balancesNFT[from] -= 1;
        _balancesNFT[to] += 1;
        _owners[tokenId] = to;

        emit TransferNFT(from, to, tokenId);
        return true;
    }

    //Note: signature is created on the frontend by the wallet holding the private key
    //for this assignment, signature is hardcoded in test case.
    function permitSpender(uint256 tokenId, bytes memory signature) public returns(bool){
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(ownerOfNFT(tokenId)==msg.sender, "Only owner of the token can permit on the token");
        uint256 nonce= nonces(tokenId);
        incrementNonce(tokenId);
        bytes32 digest = buildDigest(msg.sender, tokenId, nonce);
        permit(msg.sender, tokenId, signature, digest);
        return true;
    }

      /// @notice Builds the permit digest to sign
    /// @param spender the token spender
    /// @param tokenId the tokenId
    /// @param nonce the nonce to make a permit for
    /// @return the digest (following eip712) to sign
    function buildDigest(
        address spender,
        uint256 tokenId,
        uint256 nonce
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
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
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual  returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = "";
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId)) : "";
    }
    
    function burnToken(uint256 tokenId) public returns(bool){
        require(_burnStatus!=false, "Burn action is not allowed now. Please check back once contract owner allows minting");
        require(msg.sender== ownerOfNFT(tokenId), "Only owner of the token can burn the tokens");
        _balancesNFT[ownerOfNFT(tokenId)]--;
        _owners[tokenId]= address(0);
        emit TransferNFT(owner, address(0), tokenId);
        return true;
    }
    //  /**
    //  * @dev Destroys `tokenId`.
    //  * The approval is cleared when the token is burned.
    //  *
    //  * Requirements:
    //  *
    //  * - `tokenId` must exist.
    //  *
    //  * Emits a {Transfer} event.
    //  */
    // function _burn(uint256 tokenId) internal  {
    //     _balancesNFT[ownerOfNFT(tokenId)] -= 1;
    //     _owners[tokenId]= address(0);

    //     emit TransferNFT(owner, address(0), tokenId);

    // }

     /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function startAuctionNFT(uint256 tokenId, uint256 value) public returns(bool){
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(ownerOfNFT(tokenId)==msg.sender, 'Only owner can set NFT for auction');
        _tokenAuctionStatus[tokenId]= true;
        _tokenAuctionValue[tokenId]= value;
        return true;
    }

    function endAuctionNFT(uint256 tokenId) public returns(bool){
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(ownerOfNFT(tokenId)==msg.sender, 'Only owner of token can end NFT auction');
        _tokenAuctionStatus[tokenId]= false;
        return true;
    }

    function buyNFT(address to, uint256 tokenId) public payable returns(bool){
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
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

    function sellNFT(uint256 tokenId) public payable returns(bool){
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(ownerOfNFT(tokenId)==msg.sender, "Only token owner can sell the NFT");
        require(_staked[tokenId]== false, "Token staked, not available to be sold");
        _balancesNFT[msg.sender]--;
        // address tokenOwner= ownerOfNFT(tokenId);
        _owners[tokenId]= _admin;
        // payable(address(this)).transfer(checkTokenAuctionValue(tokenId));
        return true;
    }

    function stakeNFT(uint256 tokenId, uint256 lockPeriodInDays) public returns(bool){
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(ownerOfNFT(tokenId)== msg.sender,"Only owner can stake NFT");
        require(_staked[tokenId]== false, "Token staked already");
        _tokenAuctionStatus[tokenId]= false;
        _releaseTime[tokenId]=block.timestamp+lockPeriodInDays*24*60*60*1000;
        _staked[tokenId]= true;
        return true;
    }

    function release(uint256 tokenId) public returns(bool){
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(block.timestamp>=releaseTime(tokenId), "TokenTimelock: current time is before release time");
        _staked[tokenId]=false;
        return true;
    }

    function releaseTime(uint256 tokenId) public view returns (uint256) {
        return _releaseTime[tokenId];
    }

    function ownerOfContract() public view returns(address){
        return _admin;
    }

    function checkTokenAuctionValue(uint256 tokenId) public view returns(uint256){
        return _tokenAuctionValue[tokenId];
    }

    function checkTokenAuctionStatus(uint256 tokenId) public view returns(bool){
        return _tokenAuctionStatus[tokenId];
    }

    function isTokenStaked(uint256 tokenId) public view returns(bool){
        return _staked[tokenId];
    }
    }