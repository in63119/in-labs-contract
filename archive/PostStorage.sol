// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

contract PostStorage is ERC721URIStorage, Ownable, ERC2771Context {
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 private _nextPostId;
    mapping(address => EnumerableSet.UintSet) private _ownedPostIds;
    mapping(uint256 => string) private _postURIs;

    struct Post {
        uint256 id;
        string uri;
    }

    constructor(
        address _trustedForwarder
    ) ERC721("PostStorage", "POST") Ownable(msg.sender) ERC2771Context(_trustedForwarder) {}

    function post(address recipient, string memory uri) public onlyOwner returns (uint256) {
        uint256 postId = ++_nextPostId;

        _safeMint(recipient, postId);
        _setTokenURI(postId, uri);

        return postId;
    }

    function burn(uint256 postId) external {
        address owner = ownerOf(postId);
        _checkAuthorized(owner, _msgSender(), postId);

        _burn(postId);
    }

    function getPosts(address owner) external view returns (Post[] memory posts) {
        uint256 length = _ownedPostIds[owner].length();
        posts = new Post[](length);

        for (uint256 i = 0; i < length; i++) {
            uint256 postId = _ownedPostIds[owner].at(i);
            posts[i] = Post({id: postId, uri: postURI(postId)});
        }
    }

    function postURI(uint256 postId) public view returns (string memory) {
        _requireOwned(postId);

        string memory storedTokenURI = _postURIs[postId];
        string memory base = _baseURI();

        if (bytes(base).length == 0) {
            return storedTokenURI;
        }
        if (bytes(storedTokenURI).length > 0) {
            return string.concat(base, storedTokenURI);
        }

        return super.tokenURI(postId);
    }

    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = super._update(to, tokenId, auth);

        if (from != address(0)) {
            _ownedPostIds[from].remove(tokenId);
        }

        if (to != address(0)) {
            _ownedPostIds[to].add(tokenId);
        } else {
            delete _postURIs[tokenId];
        }

        return from;
    }

    function _setTokenURI(uint256 tokenId, string memory newTokenURI) internal override {
        super._setTokenURI(tokenId, newTokenURI);
        _postURIs[tokenId] = newTokenURI;
    }

    function _msgSender() internal view override(Context, ERC2771Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }

    function _contextSuffixLength() internal view override(Context, ERC2771Context) returns (uint256) {
        return super._contextSuffixLength();
    }
}
