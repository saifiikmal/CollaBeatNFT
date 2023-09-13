// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";

interface IERC1155 {
    function mint(address, uint256, uint256, bytes memory) external;

    function registerToken() external returns (uint);

    function exists(uint) external returns (bool);

    function totalSupply(uint) external returns (uint); 
}

interface CollaBeatAirnode {
  function makeRequest(bytes calldata) external;
}

contract CollaBeatUtility is AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint public mintPrice;
    address public feeReceiver;
    address public nftAddress;
    address public requester;
    mapping(uint => uint) public maxSupply;
    mapping(uint => Collaborator[]) public collaborators;

    event Minted(address from, uint tokenId, uint amount);
    event Forked(address from, uint tokenId, bytes data);

    struct Collaborator {
      address collabAddress;
      bool isClaim;
    }

    constructor(address _nftAddress, uint _mintPrice, address _feeReceiver) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        nftAddress = _nftAddress;
        mintPrice = _mintPrice;
        feeReceiver = _feeReceiver;
    }

    function mint(uint tokenId) public payable {

        require(msg.value >= mintPrice, "Insufficient amount");
        require(IERC1155(nftAddress).exists(tokenId), "Token ID not exists");
        require(maxSupply[tokenId] > IERC1155(nftAddress).totalSupply(tokenId), "Exceeded max supply");

        bool canClaim = false;

        for (uint i = 0; i < collaborators[tokenId].length; i++ ) {
          if (collaborators[tokenId][i].collabAddress == msg.sender) {
            if (collaborators[tokenId][i].isClaim) {
              canClaim = false;
            } else {
              canClaim = true;
            }
          }
        }

        require(canClaim, "Cannot claim this nft");
      
        IERC1155(nftAddress).mint(msg.sender, tokenId, 1, "");

        emit Minted(msg.sender, tokenId, 1);
    }

    function mintRequest(
      string memory data_key,
      string memory version,
      string memory nft_name, 
      string memory ipfs_address, 
      string memory cid
    ) public payable {
        require(msg.value >= mintPrice, "Insufficient amount");

        bytes memory data = abi.encode(nft_name, ipfs_address, cid);
        
        bytes memory params = setParameters(data_key, version, data);

        CollaBeatAirnode(requester).makeRequest(params);
    }

    function mintFulfill(
      address[] memory addresses,
      bytes calldata data
    ) external onlyRole(MINTER_ROLE) {
      uint tokenId = IERC1155(nftAddress).registerToken();
      maxSupply[tokenId] = addresses.length;

      bytes memory forkData = abi.encode("", data);

      for (uint256 i = 0; i < addresses.length; i++) {
        IERC1155(nftAddress).mint(addresses[i], tokenId, 1, forkData);
        emit Forked(addresses[i], tokenId, forkData);
      }
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

    function setRequester(address _requester) external onlyRole(DEFAULT_ADMIN_ROLE) {
        requester = _requester;
    }

    function setParameters(string memory data_key, string memory version, bytes memory data) public pure returns (bytes memory) {
      bytes memory parameters = abi.encode(
        bytes32("1SSB"),
        bytes32("data_key"), data_key,
        bytes32("version"), version,
        bytes32("datas"), data
      );
      
      return parameters;
    }
}