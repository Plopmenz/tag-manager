// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ITagManager} from "./ITagManager.sol";

interface ITagManagerExtended is ITagManager {
    /// @notice Checks how many accounts hold a tag.
    /// @param tag The tag to check.
    function totalTagHavers(bytes32 tag) external view returns (uint256);
}
