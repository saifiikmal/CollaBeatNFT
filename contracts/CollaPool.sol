// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";

interface CollaUtility {
  function balanceOf(address, uint) external returns (uint);

  function totalNFTSupply() external returns (uint);

  function claim(address, uint, uint) external;
}

contract CollaPool is AccessControl {

  constructor() {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function claim(address utilityAddress, uint tokenId) public {
    // get balance of nft
    uint balance = CollaUtility(utilityAddress).balanceOf(msg.sender, tokenId);

    // get totalNFT supply
    uint total = CollaUtility(utilityAddress).totalNFTSupply();

    require(balance > 0 && total > 0 && address(this).balance > 0, "Nothing to claim");

    CollaUtility(utilityAddress).claim(msg.sender, tokenId, balance);

    uint claimTotal = (balance / total) * address(this).balance;

    (bool success, ) = payable(msg.sender).call{value: claimTotal}(
        ""
    );
    require(success);

  }

  receive() payable external {}
}