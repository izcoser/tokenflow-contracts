// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenFlow is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    event BatchEvent(uint256 tokenId, string action);

    // Stores the entire history of a tokenURI's data.
    mapping(uint256 tokenId => string[] history) private tokenIdToHistory;

    constructor() ERC721("TokenFlow", "TF") Ownable(msg.sender) {}

    function safeMint(
        address to,
        uint256 tokenId,
        string memory uri
    ) external onlyOwner {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // Update tokenURI.
    function updateTokenURI(
        uint256 tokenId,
        string memory uri
    ) external onlyOwner {
        tokenIdToHistory[tokenId].push(tokenURI(tokenId));
        _setTokenURI(tokenId, uri);
    }

    function getHistory(
        uint256 tokenId
    ) external view returns (string[] memory) {
        return tokenIdToHistory[tokenId];
    }

    function emitBatchEvent(
        uint256 tokenId,
        string memory action
    ) external onlyOwner {
        emit BatchEvent(tokenId, action);
    }

    // Overrides required by Solidity.

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
