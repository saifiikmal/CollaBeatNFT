// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";

interface IERC1155 {
    function mint(address, uint256, uint256, bytes memory) external;

    function setURI(uint, string memory) external;

    function registerToken() external returns (uint);

    function exists(uint) external returns (bool);
}

contract CollaBeatUtility is AccessControl {
    uint public mintPrice;
    address public feeReceiver;
    address public nftAddress;
    uint8 public nonce;
    string public chainId;

    event Minted(address from, uint tokenId, uint amount);
    event Forked(address from, string dataKey, string cid);

    constructor(address _nftAddress, uint _mintPrice, address _feeReceiver, uint8 _nonce, string memory _chainId) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        nftAddress = _nftAddress;
        mintPrice = _mintPrice;
        feeReceiver = _feeReceiver;
        nonce = _nonce;
        chainId = _chainId;
    }

    function mint(uint tokenId, uint32 amount) public payable {

        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
          require(msg.value >= mintPrice, "Insufficient amount");
        }
        require(IERC1155(nftAddress).exists(tokenId), "Token ID not exists");
      
        IERC1155(nftAddress).mint(msg.sender, tokenId, amount, "");

        emit Minted(msg.sender, tokenId, amount);
    }

    function fork(string memory cid) public payable {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
          require(msg.value >= mintPrice, "Insufficient amount");
        }

        uint tokenId = IERC1155(nftAddress).registerToken(); 

        string memory _strAddress = Strings.toHexString(uint160(nftAddress), 20);
        string memory _strTokenId = Strings.toString(tokenId);
        string memory _strNonce = Strings.toString(nonce);
        string memory newTokenURI = URIHash(abi.encodePacked(_strAddress, _strTokenId, chainId, _strNonce));
        
        IERC1155(nftAddress).setURI(tokenId, newTokenURI);

        IERC1155(nftAddress).mint(msg.sender, tokenId, 1, "");

        emit Forked(msg.sender, newTokenURI, cid);
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

    function setNonce(uint8 _nonce) external onlyRole(DEFAULT_ADMIN_ROLE) {
        nonce = _nonce;
    }

    function setChainId(string calldata _chainId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        chainId = _chainId;
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