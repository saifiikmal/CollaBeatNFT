// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./x3ZeroERC721.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract x3ZeroERC721Factory is AccessControl {
    using Counters for Counters.Counter;

    Counters.Counter private _nftCounter;
    address public libraryAddress;
    address[] public nftAddresses;

    event NFTCreated(address _nftAddress);

    constructor(address _libraryAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        libraryAddress = _libraryAddress;
    }

    function setLibraryAddress(address _libraryAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        libraryAddress = _libraryAddress;
    }

    function createNFT(string calldata _name, string calldata _symbol) external onlyRole(DEFAULT_ADMIN_ROLE) returns (address){
        address clone = Clones.clone(libraryAddress);
        x3ZeroERC721(clone).initialize(_name, _symbol);

        nftAddresses.push(clone);
        _nftCounter.increment();

        emit NFTCreated(clone);

        return clone;
    }

    function totalNFTs() public view returns (uint) {
      return _nftCounter.current();
    }

    function getLatestNFT() public view returns (address) {
      uint current = _nftCounter.current() - 1;
      return nftAddresses[current];
    }
}