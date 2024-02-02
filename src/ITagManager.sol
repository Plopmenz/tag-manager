// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITagManager {
    /// @notice Checks if an account holds a certain tag (satisfied a certain condition).
    /// @param account The account to check with.
    /// @param tag The tag to check for.
    function hasTag(address account, bytes32 tag) external view returns (bool);
}
