// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@api3/airnode-protocol/contracts/rrp/requesters/RrpRequesterV0.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface CollaUtility {
  function requestFulfill(
      bytes calldata
    ) external;
}

contract CollaAirnode is RrpRequesterV0, Ownable{
    mapping(bytes32 => bool) public incomingFulfillments;
    mapping(bytes32 => bytes) public fulfilledData;
    mapping(bytes32 => address) public requestCallers;

    constructor(
        address _rrpAddress
    ) RrpRequesterV0(_rrpAddress) {}


    // To receive funds from the sponsor wallet and send them to the owner.
    receive() external payable {
        payable(owner()).transfer(address(this).balance);
    }

    // To withdraw funds from the sponsor wallet to the contract.
    function withdraw(address airnode, address sponsorWallet) external onlyOwner {
        airnodeRrp.requestWithdrawal(airnode, sponsorWallet);
    }

    function makeRequest(
        address airnode,
        bytes32 endpointId,
        address sponsor,
        address sponsorWallet,
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
        requestCallers[requestId] = msg.sender;
    }

    function fulfill(bytes32 requestId, bytes calldata data)
        external
        onlyAirnodeRrp
    {
        require(incomingFulfillments[requestId], "No such request made");
        require(requestCallers[requestId] != address(0), "No such requester");
        delete incomingFulfillments[requestId];
        
        fulfilledData[requestId] = data;

        CollaUtility(requestCallers[requestId]).requestFulfill(data);

        delete requestCallers[requestId];
    }
}