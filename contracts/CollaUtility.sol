// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";

interface IERC1155 {
    function mint(address, uint256, uint256, bytes memory) external;

    function registerToken() external returns (uint);

    function exists(uint) external returns (bool);

    function totalSupply(uint) external returns (uint); 

    function balanceOf(address, uint) external returns (uint);

    function burn(address, uint, uint) external;
}

interface CollaAirnode {
  function makeRequest(
    address,
    bytes32,
    address,
    address,
    bytes calldata
  ) external;
}

contract CollaUtility is AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 constant ADDRESS_LENGTH = 42; // Length of an Ethereum address including '0x'

    uint public mintPrice;
    address public feeReceiver;
    address public nftAddress;
    mapping(uint => uint) public maxSupply;
    uint public totalNFTSupply = 0;

    address public airnode;
    address public sponsor;
    address public sponsorWallet;
    bytes32 public endpointId;
    address public requester;

    address public hostWallet;
    address public devWallet;
    address public poolWallet;

    uint public percentHost = 10;
    uint public percentDev = 20;
    uint public percentPool = 70;

    event Minted(address from, uint tokenId, uint amount);
    event Forked(address from, uint tokenId, bytes data);

    constructor(address _nftAddress, uint _mintPrice, address _feeReceiver) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        nftAddress = _nftAddress;
        mintPrice = _mintPrice;
        feeReceiver = _feeReceiver;
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

        uint hostCut = msg.value * percentHost / 100;
        (bool success, ) = payable(hostWallet).call{value: hostCut}("");

        require(success, "Unable to send to host address");

        uint devCut = msg.value * percentDev / 100;
        (bool success2, ) = payable(devWallet).call{value: devCut}("");

        require(success2, "Unable to send to dev address");

        uint poolCut = msg.value * percentPool / 100;
        (bool success3, ) = payable(poolWallet).call{value: poolCut}("");

        require(success3, "Unable to send to pool address");

        CollaAirnode(requester).makeRequest(
          airnode,
          endpointId,
          sponsor,
          sponsorWallet,
          params
        );
    }

    function requestFulfill(
      bytes calldata data
    ) external onlyRole(MINTER_ROLE) {
      (string memory dataKey, bytes memory datas, address[] memory addresses) = decodeData(data);

      require(addresses.length > 0, "No addresses to mint");
        
      uint tokenId = IERC1155(nftAddress).registerToken();
      maxSupply[tokenId] = addresses.length;
      totalNFTSupply += addresses.length;

      bytes memory forkData = abi.encode("", datas);

      for (uint256 i = 0; i < addresses.length; i++) {
        IERC1155(nftAddress).mint(addresses[i], tokenId, 1, forkData);
        emit Forked(addresses[i], tokenId, forkData);
      }
    } 

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(feeReceiver).transfer(address(this).balance);
    }

    function claim(address from, uint tokenId, uint amount) external {
      uint balance = IERC1155(nftAddress).balanceOf(from, tokenId);
      require(balance >= amount && totalNFTSupply >= amount, "Amount exceeded for claim");

      IERC1155(nftAddress).burn(from, tokenId, amount);
      totalNFTSupply -= amount;
    }

    function balanceOf(address from, uint tokenId) external returns (uint) {
      return IERC1155(nftAddress).balanceOf(from, tokenId);
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

    function setParameters(string memory dataKey, string memory version, bytes memory data) public pure returns (bytes memory) {
      bytes memory parameters = abi.encode(
        bytes32("1SSB"),
        bytes32("data_key"), dataKey,
        bytes32("version"), version,
        bytes32("datas"), data
      );
      
      return parameters;
    }

    function setAirnode(
      address _airnode,
      address _sponsor,
      address _sponsorWallet,
      bytes32 _endpointId,
      address _requester
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
      airnode = _airnode;
      sponsor = _sponsor;
      sponsorWallet = _sponsorWallet;
      endpointId = _endpointId;
      requester = _requester;

      _grantRole(MINTER_ROLE, requester);
    }

    function setPercentage(
      uint _host,
      uint _dev,
      uint _pool
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
      percentHost = _host;
      percentDev = _dev;
      percentPool = _pool;
    }

    function setHostWallet(address _wallet) external onlyRole(DEFAULT_ADMIN_ROLE) {
      hostWallet = _wallet;
    }

    function setDevWallet(address _wallet) external onlyRole(DEFAULT_ADMIN_ROLE) {
      devWallet = _wallet;
    }

    function setPoolWallet(address _wallet) external onlyRole(DEFAULT_ADMIN_ROLE) {
      poolWallet = _wallet;
    }

    function decodeData(bytes calldata encodedData) public pure returns (string memory, bytes memory, address[] memory) {
        (string memory dataKey, bytes memory datas, string memory addresses) = abi.decode(encodedData, (string, bytes, string));
        
        address[] memory convertAddress = splitAndConvert(addresses);
        return (dataKey, datas, convertAddress);
    }


    function splitAndConvert(string memory concatenatedAddresses) public pure returns (address[] memory) {
        uint256 addressesCount = bytes(concatenatedAddresses).length / ADDRESS_LENGTH;
        address[] memory addresses = new address[](addressesCount);

        for (uint256 i = 0; i < addressesCount; i++) {
            string memory addressStr = substring(concatenatedAddresses, i * ADDRESS_LENGTH, (i + 1) * ADDRESS_LENGTH - 1);
            addresses[i] = parseAddress(addressStr);
        }

        return addresses;
    }

    function substring(string memory str, uint256 start, uint256 end) private pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(end - start + 1);
        for (uint256 i = start; i <= end; i++) {
            result[i - start] = strBytes[i];
        }
        return string(result);
    }

    function parseAddress(string memory _addressString) public pure returns (address) {
        bytes memory _addressBytes = bytes(_addressString);
        require(_addressBytes.length == 42, "Invalid address length");
        
        uint160 _parsedAddress = 0;
        
        for (uint256 i = 2; i < _addressBytes.length; i++) {
            _parsedAddress *= 16;
            
            uint8 _digit = uint8(_addressBytes[i]);
            if (_digit >= 48 && _digit <= 57) {
                _parsedAddress += _digit - 48;
            } else if (_digit >= 65 && _digit <= 70) {
                _parsedAddress += _digit - 55;
            } else if (_digit >= 97 && _digit <= 102) {
                _parsedAddress += _digit - 87;
            } else {
                revert("Invalid character in address string");
            }
        }
        
        return address(_parsedAddress);
    }
}