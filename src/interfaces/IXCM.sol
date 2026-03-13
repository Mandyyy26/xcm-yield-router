// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @dev The on-chain address of the XCM precompile
address constant XCM_PRECOMPILE_ADDRESS = address(0xA0000);

/// @title XCM Precompile Interface
/// @notice Low-level interface for interacting with pallet_xcm
interface IXcm {

    /// @notice Weight v2 used for XCM execution measurement
    struct Weight {
        uint64 refTime;    // Computational time on reference hardware
        uint64 proofSize;  // Size of proof required for execution
    }

    /// @notice Execute an XCM message locally with the caller's origin
    /// @param message SCALE-encoded Versioned XCM message
    /// @param weight Maximum allowed Weight for execution
    function execute(bytes calldata message, Weight calldata weight) external;

    /// @notice Send an XCM message to another parachain
    /// @param destination SCALE-encoded destination MultiLocation
    /// @param message SCALE-encoded Versioned XCM message
    function send(bytes calldata destination, bytes calldata message) external;

    /// @notice Estimate Weight required to execute a given XCM message
    /// @param message SCALE-encoded Versioned XCM message
    /// @return weight Estimated refTime and proofSize
    function weighMessage(bytes calldata message)
        external
        view
        returns (Weight memory weight);
}
