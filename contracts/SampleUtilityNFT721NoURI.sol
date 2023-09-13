// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";

interface IERC721 {
    function mint(address, uint256, bytes memory) external;

    function registerToken() external returns (uint);

    function ownerOf(uint) external returns (address);
}

contract SampleUtilityNFT721 is AccessControl {
    uint public mintPrice;
    address public feeReceiver;
    address public nftAddress;

    event Minted(address from, uint tokenId);

    constructor(address _nftAddress, uint _mintPrice, address _feeReceiver, uint8 _nonce, string memory _chainId) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        nftAddress = _nftAddress;
        mintPrice = _mintPrice;
        feeReceiver = _feeReceiver;
    }

    function mint() public payable {

        require(msg.value >= mintPrice, "Insufficient amount");

        uint tokenId = IERC721(nftAddress).registerToken();

        // bytes memory data = abi.encode("");
        bytes memory forkData = abi.encode("", "");
      
        IERC721(nftAddress).mint(msg.sender, tokenId, forkData);

        emit Minted(msg.sender, tokenId);
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

    function URIHash(bytes memory hash) private pure returns (string memory) {
        bytes32 hashByte = keccak256(hash);
        string memory hashStr = Strings.toHexString(uint(hashByte), 32);

        bytes memory strBytes = bytes(hashStr);
        bytes memory result = new bytes(64);
        for(uint i = 0; i < 64; i++) {
            result[i] = strBytes[i+2];
        }
        return string(result);
    }
}