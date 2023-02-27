// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract CollaBeatNFT is ERC1155, IERC2981, AccessControl, Pausable, ERC1155Burnable, ERC1155Supply, ERC1155URIStorage {
    using Counters for Counters.Counter;
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;

    uint public maxSupplyPerTokenType = 30;
    uint public maxTokenId = 10000;
    address public royaltyRecipient;
    uint public royaltyFee;

    constructor(string memory tokenBaseURI) ERC1155("") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        _setBaseURI(tokenBaseURI);
    }

    function setMaxSupplyPerTokenType(uint max) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxSupplyPerTokenType = max;
    }

    function setMaxTokenId(uint max) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxTokenId = max;
    }

    function setRoyaltyReceiver(address recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        royaltyRecipient = recipient;
    }

    function setRoyaltyFee(uint fee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        royaltyFee = fee;
    }

    function uri(uint256 tokenId) public view override(ERC1155, ERC1155URIStorage) returns (string memory) {
        return ERC1155URIStorage.uri(tokenId);
    }

    function setBaseURI(string memory tokenBaseURI) public onlyRole(URI_SETTER_ROLE) {
        _setBaseURI(tokenBaseURI);
    }

    function setURI(uint tokenId, string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(tokenId, newuri);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function currentTokenId() external view returns (uint) {
      return _tokenIdCounter.current();
    }

    function nextTokenId() external view returns (uint) {
      return _tokenIdCounter.current() + 1;
    }

    function registerToken() external onlyRole(MINTER_ROLE) returns (uint) {
      _tokenIdCounter.increment();
      return _tokenIdCounter.current();
    }
    
    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyRole(MINTER_ROLE)
    {
        require(id < maxTokenId + 1, "Exceeded max token id");
        require(totalSupply(id) + amount < maxSupplyPerTokenType + 1, "Exceed max total supply token type");

        _mint(account, id, amount, data);
    }

    // EIP2981 standard royalties return.
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (royaltyRecipient, (_salePrice * royaltyFee) / 100);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, IERC165, AccessControl)
        returns (bool)
    {
        return (
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId)
        );
    }
}
