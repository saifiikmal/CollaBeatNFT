// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract x3ZeroERC721 is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, 
PausableUpgradeable, AccessControlUpgradeable, ERC721BurnableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    CountersUpgradeable.Counter private _tokenIdCounter;

    string public tokenBaseURI;

    event Minted(address to, uint tokenId, bytes data);

    function initialize(string calldata _name, string calldata _symbol) external initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, tx.origin);
        _grantRole(PAUSER_ROLE, tx.origin);
        _grantRole(MINTER_ROLE, tx.origin);
        _grantRole(URI_SETTER_ROLE, tx.origin);

        __ERC721_init(_name, _symbol);
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

    function mint(address to, uint tokenId, bytes memory data)
        public
        onlyRole(MINTER_ROLE)
    {
        _safeMint(to, tokenId);
        emit Minted(to, tokenId, data);
    }

    function setBaseURI(string calldata baseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenBaseURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return tokenBaseURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721Upgradeable) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
