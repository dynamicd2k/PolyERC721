//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./Ownable.sol";

contract Mintable is Ownable{

    bool _mintStatus= false;
    bool _burnStatus= false;
    bool _transferStatus= true;
    bool _auctionStatus= false;

    function startMint() public onlyOwner{
        _mintStatus= true;
    }

    function pauseMint() public onlyOwner{
        _mintStatus= false;
    }

    function allowBurn() public onlyOwner{
        _burnStatus= true;
    }

    function restrictBurn() public onlyOwner{
        _burnStatus= false;
    }

    function enableTransfer()public onlyOwner{
        _transferStatus= true;
    }

    function disableTransfer() public onlyOwner{
        _transferStatus= false;
    }

    function enableAuction() public onlyOwner{
        _auctionStatus= true;
    }

    function disableAuction() public onlyOwner{
        _auctionStatus= false;
    }
}