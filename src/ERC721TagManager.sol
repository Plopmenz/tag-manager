// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {AccessControl} from "../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

import {ITagManagerExtended, ITagManager} from "./ITagManagerExtended.sol";

contract ERC721TagManager is AccessControl, ITagManagerExtended {
    error AlreadyTagged(uint256 tokenId, bytes32 tag);
    error NotTagged(uint256 tokenId, bytes32 tag);

    error TokenNotBurned(uint256 tokenId);

    struct TagData {
        uint256 taggedAccountsCount;
        mapping(uint256 tokenId => bool) hasTag;
    }

    IERC721 private immutable collection;
    mapping(bytes32 tag => TagData tagData) private tags;
    mapping(address account => uint256 tokenId) private accountToId;

    constructor(IERC721 _collection, address _admin) {
        collection = _collection;
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /// @inheritdoc ITagManager
    function hasTag(address account, bytes32 tag) external view override returns (bool) {
        uint256 tokenId = accountToId[account];
        return collection.ownerOf(tokenId) == account && tags[tag].hasTag[tokenId];
    }

    /// @inheritdoc ITagManagerExtended
    function totalTagHavers(bytes32 tag) external view override returns (uint256) {
        return tags[tag].taggedAccountsCount;
    }

    /// @notice Adds a tag to a tokenId.
    /// @param tokenId The tokenId getting the tag.
    /// @param tag The tag to apply.
    /// @dev Only callable by a holder of the tag access control role. (which is not the same as having the tag!)
    function addTag(uint256 tokenId, bytes32 tag) external onlyRole(tag) {
        _addTag(tokenId, tag);

        // First of your NFTs to get an tag is set as your default (for convenience)
        address tokenOwner = collection.ownerOf(tokenId);
        if (accountToId[tokenOwner] != 0) {
            accountToId[tokenOwner] = tokenId;
        }
    }

    /// @notice Removes a tag from a tokenId.
    /// @param tokenId The tokenId getting the tag removed.
    /// @param tag The tag to remove.
    /// @dev Only callable by a holder of the tag access control role. (which is not the same as having the tag!)
    function removeTag(uint256 tokenId, bytes32 tag) external onlyRole(tag) {
        _removeTag(tokenId, tag);
    }

    /// @notice Removes a tag from a burned tokenId.
    /// @param tokenId The burned tokenId getting the tag removed.
    /// @param tag The tag to remove.
    /// @dev Different from removeTag as anyone can call this, but it only works on burned tokens.
    function removeTagFromBurnedToken(uint256 tokenId, bytes32 tag) external {
        // ownerOf call can throw a "token does not exist" error.
        try collection.ownerOf(tokenId) returns (address owner) {
            if (owner != address(0)) {
                revert TokenNotBurned(tokenId);
            }
        } catch {}

        _removeTag(tokenId, tag);
    }

    /// @notice Transfers role adminship to a different role.
    /// @param role The role whos admin variable is getting changed.
    /// @param adminRole The new admin role of this role.
    /// @dev Only callable by a holder of the (old) admin role.
    /// @dev This can be used by a default admin to create a new tag (managed by another tag).
    function setRoleAdmin(bytes32 role, bytes32 adminRole) public onlyRole(getRoleAdmin(role)) {
        _setRoleAdmin(role, adminRole);
    }

    function _addTag(uint256 tokenId, bytes32 tag) internal {
        TagData storage tagData = tags[tag];
        if (tagData.hasTag[tokenId]) {
            revert AlreadyTagged(tokenId, tag);
        }

        tagData.hasTag[tokenId] = true;
        ++tagData.taggedAccountsCount; // TokenID can only have 1 owner / account
    }

    function _removeTag(uint256 tokenId, bytes32 tag) internal {
        TagData storage tagData = tags[tag];
        if (!tagData.hasTag[tokenId]) {
            revert NotTagged(tokenId, tag);
        }

        tagData.hasTag[tokenId] = false;
        --tagData.taggedAccountsCount;
    }
}