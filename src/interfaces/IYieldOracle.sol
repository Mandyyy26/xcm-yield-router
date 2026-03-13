// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title IYieldOracle
/// @notice Interface for YieldOracle — admin-controlled APY feed with safety guards
interface IYieldOracle {

    // ═══════════════════════════════════════════════════════════
    //  EVENTS
    // ═══════════════════════════════════════════════════════════

    /// @notice Emitted when a yield value is updated
    event YieldUpdated(uint8 indexed strategyId, uint256 oldYield, uint256 newYield, uint256 timestamp);

    /// @notice Emitted when max staleness duration is changed
    event MaxStalenessUpdated(uint256 oldValue, uint256 newValue);

    /// @notice Emitted when max delta per update is changed
    event MaxDeltaUpdated(uint256 oldValue, uint256 newValue);

    // ═══════════════════════════════════════════════════════════
    //  ERRORS
    // ═══════════════════════════════════════════════════════════

    error StaleYieldData(uint8 strategyId, uint256 lastUpdated);
    error DeltaExceedsLimit(uint256 delta, uint256 maxDelta);
    error YieldTooHigh(uint256 provided, uint256 max);
    error UnauthorizedCaller(address caller);

    // ═══════════════════════════════════════════════════════════
    //  ADMIN FUNCTIONS
    // ═══════════════════════════════════════════════════════════

    /// @notice Update the yield for a strategy
    /// @param strategyId Strategy to update
    /// @param newYield New APY in basis points
    function updateYield(uint8 strategyId, uint256 newYield) external;

    /// @notice Set how long before a yield reading is considered stale
    function setMaxStaleness(uint256 newStaleness) external;

    /// @notice Set max APY change allowed per single update (basis points)
    function setMaxDelta(uint256 newMaxDelta) external;

    // ═══════════════════════════════════════════════════════════
    //  VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════

    /// @notice Returns current yield — reverts if stale
    function getYield(uint8 strategyId) external view returns (uint256);

    /// @notice Returns true if yield data is older than maxStaleness
    function isStale(uint8 strategyId) external view returns (bool);

    /// @notice Returns the timestamp of last update for a strategy
    function lastUpdated(uint8 strategyId) external view returns (uint256);
}
