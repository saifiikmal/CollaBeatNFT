// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract x3ZeroERC1155 is Initializable, ERC1155Upgradeable, IERC2981Upgradeable, AccessControlUpgradeable, PausableUpgradeable, ERC1155BurnableUpgradeable, 
ERC1155SupplyUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    CountersUpgradeable.Counter private _tokenIdCounter;

    uint public maxSupplyPerTokenType = 30;
    uint public maxTokenId = 10000;
    address public royaltyRecipient;
    uint public royaltyFee;

    event Minted(address to, uint tokenId, bytes data);

    function initialize(string calldata _uri) external initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, tx.origin);
        _grantRole(PAUSER_ROLE, tx.origin);
        _grantRole(MINTER_ROLE, tx.origin);
        _grantRole(URI_SETTER_ROLE, tx.origin);

        __ERC1155_init(_uri);
        _setURI(_uri);
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


    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
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
    
    function mint(address to, uint tokenId, uint256 amount, bytes memory data)
        public
        onlyRole(MINTER_ROLE)
    {
        require(tokenId < maxTokenId + 1, "Exceeded max token id");
        require(totalSupply(tokenId) + amount < maxSupplyPerTokenType + 1, "Exceed max total supply token type");

        _mint(to, tokenId, amount, data);

        emit Minted(to, tokenId, data);
    }

    // EIP2981 standard royalties return.
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (royaltyRecipient, _salePrice * royaltyFee / 100);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155Upgradeable, ERC1155SupplyUpgradeable)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, IERC165Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return (
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId)
        );
    }
}
