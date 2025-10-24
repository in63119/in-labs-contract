// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract PasskeyStorage is ERC721URIStorage, Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 private _nextTokenId;
    mapping(address => EnumerableSet.UintSet) private _ownedTokenIds;
    mapping(uint256 => string) private _tokenURIs;

    constructor() ERC721("PasskeyStorage", "PASSKEY") Ownable(msg.sender) {}

    function registerPasskey(address recipient, string memory uri) public onlyOwner returns (uint256) {
        uint256 tokenId = ++_nextTokenId;

        _safeMint(recipient, tokenId);
        _setTokenURI(tokenId, uri);

        return tokenId;
    }

    function burn(uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        _checkAuthorized(owner, _msgSender(), tokenId);

        _burn(tokenId);
    }

    function getOwnerPasskeys(
        address owner
    ) external view returns (uint256[] memory tokenIds, string[] memory tokenURIs) {
        uint256 length = _ownedTokenIds[owner].length();
        tokenIds = new uint256[](length);
        tokenURIs = new string[](length);

        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = _ownedTokenIds[owner].at(i);
            tokenIds[i] = tokenId;
            tokenURIs[i] = tokenURI(tokenId);
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);

        string memory storedTokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        if (bytes(base).length == 0) {
            return storedTokenURI;
        }
        if (bytes(storedTokenURI).length > 0) {
            return string.concat(base, storedTokenURI);
        }

        return super.tokenURI(tokenId);
    }

    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = super._update(to, tokenId, auth);

        if (from != address(0)) {
            _ownedTokenIds[from].remove(tokenId);
        }

        if (to != address(0)) {
            _ownedTokenIds[to].add(tokenId);
        } else {
            delete _tokenURIs[tokenId];
        }

        return from;
    }

    function _setTokenURI(uint256 tokenId, string memory newTokenURI) internal override {
        _tokenURIs[tokenId] = newTokenURI;
        emit MetadataUpdate(tokenId);
    }
}
