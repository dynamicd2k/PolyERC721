//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./Ownable.sol";

/**
 * @title Mintable
 * @dev The Mintable contract enables admin of contract to control functions like minting, burn, auction, transfer
 */
contract Mintable is Ownable{

    bool _mintStatus= false;
    bool _burnStatus= false;
    bool _transferStatus= true;
    bool _auctionStatus= false;

    /**
     * @dev startMint : function to start/allow minting
     */
    function startMint() public onlyOwner{
        _mintStatus= true;
    }
    /**
     * @dev pauseMint : function to pause/stop minting
     */
    function pauseMint() public onlyOwner{
        _mintStatus= false;
    }
    /**
     * @dev allowBurn : function to start/allow burn
     */
    function allowBurn() public onlyOwner{
        _burnStatus= true;
    }

    /**
     * @dev restrictBrun : function to stop/restrict burn
     */
    function restrictBurn() public onlyOwner{
        _burnStatus= false;
    }

    /**
     * @dev enableTransfer : function to start/allow transfer
     */
    function enableTransfer()public onlyOwner{
        _transferStatus= true;
    }

    /**
     * @dev disableTransfer : function to stop transfer
     */
    function disableTransfer() public onlyOwner{
        _transferStatus= false;
    }

    /**
     * @dev enableAuction : function to start/allow auction
     */
    function enableAuction() public onlyOwner{
        _auctionStatus= true;
    }

    /**
     * @dev disableAuction : function to stop auction
     */
    function disableAuction() public onlyOwner{
        _auctionStatus= false;
    }
}