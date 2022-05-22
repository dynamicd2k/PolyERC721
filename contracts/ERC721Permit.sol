//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "hardhat/console.sol";
// import "@nomiclabs/buidler/console.sol";

// import './IERC712WithPermit.sol';

/**
 * @dev This implementation of Permits links the nonce to the tokenId instead of the owner
 *      This way, it is possible for a same account to create several usable permits at the same time,
 *      for different ids
 *      This implementation overrides _transfer and increments the nonce linked to a tokenId
 *      every time it is transfered
 **/
 abstract contract ERC721Permit {

    //mapping nonces to tokenid
     mapping (uint256=>uint256) private _nonces;

    //mapping to permit addresses
     mapping (address=>mapping(uint256=>bool)) internal _permit;

     //domain separator and chain id are saved immutably for cheaper access
     //chain id is also saved to recompute domain separator in case of a fork

    //  bytes32 private immutable _domainSeparator;
    //  uint256 private immutable _domainChainId;

    //  constructor(){
    //     uint256 chainId;

    //     assembly{
    //         chainId := chainid();
    //     }

    //     _domainChainId = chainId;
    //     _domainSeparator = _calculateDomainSeparator(chainId);
    //  }

    //  function DOMAIN_SEPARATOR() public view returns(bytes32){
    //      uint256 chainId;
    //      assembly{
    //          chainId := chainid();
    //      }

    //      return (chainId == _domainChainId)?_domainSeparator: _calculateDomainSeparator(chainId);
    //  }

    //  function _calculateDomainSeparator(uint256 chainId) internal view returns (bytes32){
    //      return keccak256(abi.encode(keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
    //      ),
    //      keccak256(bytes(nameOfNFT())), //ERC721 token name
    //      keccak256(bytes('1')),          //Version
    //      chainId,
    //      address(this)
    //      ));
    //  }

    /// @notice Allows to retrieve current nonce for token
    /// @param tokenId token id
    /// @return current token nonce

     function nonces(uint256 tokenId) public view returns(uint256){
         return _nonces[tokenId];
     }
    
    /// @dev Anyone can call this to approve `spender`, even a third-party
    /// @param spender the actor to approve
    /// @param tokenId the token id
    /// @param signature permit

    function permit(address spender, uint256 tokenId, bytes memory signature, bytes32 digest) public returns(bool){

        address recoveredAddress;

        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length != 65){
            recoveredAddress= address(0);
        }

        //Divide the signature to r,s,v variables
        assembly{
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        //Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if(v<27){
            v +=27;
        }

        if(v!=27 && v!=28){
            return false;
        } else{
            recoveredAddress= ecrecover(digest, v, r, s);
        }

        require(recoveredAddress != address(0), 'ERC721: Permit address is zero address, aborted.');
        require(recoveredAddress == spender, 'Invalid permit signature');
        _permit[recoveredAddress][tokenId]= true;
        return true;
    }

    function checkPermit(address spender, uint256 tokenId) public view returns(bool){
        return _permit[spender][tokenId];
    }

  

    /// @dev helper to easily increment a nonce for a given tokenId
    /// @param tokenId the tokenId to increment the nonce for
    function incrementNonce(uint256 tokenId) internal{
        _nonces[tokenId]++;
    }
     }
 
