// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";

interface IERC1155 {
    function mint(address, uint256, uint256, bytes memory) external;

    function registerToken() external returns (uint);

    function exists(uint) external returns (bool);
}

contract Web3WallUtility is AccessControl {
    uint public mintPrice;
    address public feeReceiver;
    address public nftAddress;

    event Minted(address from, uint tokenId, uint amount);
    event Forked(address from, uint tokenId, bytes data);

    constructor(address _nftAddress, uint _mintPrice, address _feeReceiver) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        nftAddress = _nftAddress;
        mintPrice = _mintPrice;
        feeReceiver = _feeReceiver;
    }

    function mint(string memory name, string memory image) public payable {
        require(msg.value >= mintPrice, "Insufficient amount");

        uint tokenId = IERC1155(nftAddress).registerToken(); 

        bytes memory data = abi.encode(name, image);
        bytes memory forkData = abi.encode("", data);
        
        IERC1155(nftAddress).mint(msg.sender, tokenId, 1, forkData);

        emit Forked(msg.sender, tokenId, forkData);
    }

    function mintCopy(uint tokenId) public payable {
        require(msg.value >= mintPrice, "Insufficient amount");
        require(IERC1155(nftAddress).exists(tokenId), "Token ID not exists");

        IERC1155(nftAddress).mint(msg.sender, tokenId, 1, "");

        emit Minted(msg.sender, tokenId, 1);
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

}