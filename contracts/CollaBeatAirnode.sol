// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@api3/airnode-protocol/contracts/rrp/requesters/RrpRequesterV0.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface CollaBeatUtility {
  function mintFulfill(
      address[] memory,
      bytes calldata
    ) external;
}

contract CollaBeatAirnode is RrpRequesterV0, Ownable{
    uint256 constant ADDRESS_LENGTH = 42; // Length of an Ethereum address including '0x'
    mapping(bytes32 => bool) public incomingFulfillments;
    mapping(bytes32 => FulfilledData) public fulfilledData;
    mapping(bytes32 => address[]) public fulfilledAddress;

    address public airnode;
    address public sponsor;
    address public sponsorWallet;
    bytes32 public endpointId;

    address public utilityAddress;

    struct FulfilledData {
        string data_key;
        string version;
        int256 max_supply;
        bytes datas;
    }

    event FulfillLog(string data_key, string version, int256 max_supply, bytes datas, address[] addresses);

    constructor(
        address _rrpAddress, 
        address _airnode, 
        address _sponsor, 
        address _sponsorWallet, 
        bytes32 _endpointId
    ) RrpRequesterV0(_rrpAddress) {
        airnode = _airnode;
        sponsor = _sponsor;
        sponsorWallet = _sponsorWallet;
        endpointId = _endpointId;
    }

    function setAirnode(address _airnode) external onlyOwner {
        airnode = _airnode;
    }

    function setSponsor(address _sponsor) external onlyOwner {
        sponsor = _sponsor;
    }

    function setSponsorWallet(address _sponsorWallet) external onlyOwner {
        sponsorWallet = _sponsorWallet;
    }

    function setEndpointId(bytes32 _endpointId) external onlyOwner {
        endpointId = _endpointId;
    }

    function setUtilityAddress(address _utilityAddress) external onlyOwner {
        utilityAddress = _utilityAddress;
    }

    // To receive funds from the sponsor wallet and send them to the owner.
    receive() external payable {
        payable(owner()).transfer(address(this).balance);
    }

    // To withdraw funds from the sponsor wallet to the contract.
    function withdraw() external onlyOwner {
        airnodeRrp.requestWithdrawal(airnode, sponsorWallet);
    }

    function makeRequest(
        bytes calldata parameters
    ) external {
        bytes32 requestId = airnodeRrp.makeFullRequest(
            airnode,                        // airnode address
            endpointId,                     // endpointId
            sponsor,                        // sponsor's address
            sponsorWallet,                  // sponsorWallet
            address(this),                  // fulfillAddress
            this.fulfill.selector,          // fulfillFunctionId
            parameters                      // encoded API parameters
        );
        incomingFulfillments[requestId] = true;
    }

    function fulfill(bytes32 requestId, bytes calldata data)
        external
        onlyAirnodeRrp
    {
        require(incomingFulfillments[requestId], "No such request made");
        delete incomingFulfillments[requestId];
        (string memory data_key, string memory version, int256 max_supply, bytes memory datas, address[] memory addresses) = decodeData(data);
        
        fulfilledData[requestId] = FulfilledData({
            data_key: data_key, 
            version: version, 
            max_supply: max_supply,
            datas: datas
        });

        fulfilledAddress[requestId] = addresses;

        CollaBeatUtility(utilityAddress).mintFulfill(addresses, datas);

        emit FulfillLog(data_key, version, max_supply, datas, addresses);
    }

    function decodeData(bytes calldata encodedData) public pure returns (string memory, string memory, int256, bytes memory, address[] memory) {
        (string memory data_key, string memory version, int256 max_supply, bytes memory datas, string memory addresses) = abi.decode(encodedData, (string, string, int256, bytes, string));
        
        address[] memory convertAddress = splitAndConvert(addresses);
        return (data_key, version, max_supply, datas, convertAddress);
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