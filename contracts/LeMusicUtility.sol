// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";

interface IERC1155{
    function mint(address, uint256, string memory, bytes memory) external;
    
    function mint(address, uint256, uint256, bytes memory) external;
}

contract LeMusicUtility is AccessControl {
    uint public mintPrice;
    uint public collabPrice;
    address public feeReceiver;
    address public nftAddress;

    event Minted(address from, uint amount, string tokenURI);
    event Collab(address from, uint tokenId, uint amount);

    constructor(address _nftAddress, uint _mintPrice, uint _collabPrice, address _feeReceiver) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        nftAddress = _nftAddress;
        mintPrice = _mintPrice;
        feeReceiver = _feeReceiver;
        collabPrice = _collabPrice;
    }

    function mint(uint amount, string memory tokenURI) public payable {

        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
          require(msg.value >= mintPrice * amount, "Insufficient amount");
        }

        IERC1155(nftAddress).mint(msg.sender, amount, tokenURI, "");

        emit Minted(msg.sender, amount, tokenURI);
    }

    function collab(uint tokenId, uint amount) public payable {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
          require(msg.value >= collabPrice * amount, "Insufficient amount");
        }

        IERC1155(nftAddress).mint(msg.sender, tokenId, amount, "");

        emit Collab(msg.sender, tokenId, amount);
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(feeReceiver).transfer(address(this).balance);
    }

    function setFeeReceiver(address _feeReceiver) external onlyRole(DEFAULT_ADMIN_ROLE) {
        feeReceiver = _feeReceiver;
    }

    function setNftAddress(address _nftAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        nftAddress = _nftAddress;
    }

    function setMintPrice(uint price) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintPrice = price;
    }

    function setCollabPrice(uint price) external onlyRole(DEFAULT_ADMIN_ROLE) {
        collabPrice = price;
    }
}