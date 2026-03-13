// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title IStrategy
/// @notice Interface for StrategyManager — registry and selector of yield strategies
interface IStrategy {

    // ═══════════════════════════════════════════════════════════
    //  STRUCTS
    // ═══════════════════════════════════════════════════════════

    /// @notice Represents a yield strategy on a destination parachain
    struct Strategy {
        uint32 parachainId;       // Parachain ID on Polkadot (e.g. 1000, 2000)
        address strategyAddress;  // Contract address on destination chain
        uint256 currentAPY;       // APY in basis points (e.g. 850 = 8.5%)
        bool active;              // Whether strategy is eligible for allocation
    }

    // ═══════════════════════════════════════════════════════════
    //  EVENTS
    // ═══════════════════════════════════════════════════════════

    /// @notice Emitted when a new strategy is registered
    event StrategyRegistered(uint8 indexed strategyId, uint32 parachainId, address strategyAddress);

    /// @notice Emitted when a strategy's APY is updated
    event APYUpdated(uint8 indexed strategyId, uint256 oldAPY, uint256 newAPY);

    /// @notice Emitted when a strategy is deactivated
    event StrategyDeactivated(uint8 indexed strategyId);

    // ═══════════════════════════════════════════════════════════
    //  ERRORS
    // ═══════════════════════════════════════════════════════════

    error StrategyNotFound(uint8 strategyId);
    error StrategyAlreadyExists(uint8 strategyId);
    error StrategyInactive(uint8 strategyId);
    error NoActiveStrategies();
    error InvalidParachainId();
    error InvalidAPY(uint256 apy);

    // ═══════════════════════════════════════════════════════════
    //  ADMIN FUNCTIONS
    // ═══════════════════════════════════════════════════════════

    /// @notice Register a new strategy
    /// @param strategyId Unique identifier (0 or 1 for MVP)
    /// @param parachainId Polkadot parachain ID
    /// @param strategyAddress Contract on destination chain
    /// @param initialAPY Starting APY in basis points
    function registerStrategy(
        uint8 strategyId,
        uint32 parachainId,
        address strategyAddress,
        uint256 initialAPY
    ) external;

    /// @notice Update APY for a strategy (called by YieldOracle)
    /// @param strategyId Strategy to update
    /// @param newAPY New APY in basis points
    function updateAPY(uint8 strategyId, uint256 newAPY) external;

    /// @notice Deactivate a strategy (exclude from selection)
    function deactivateStrategy(uint8 strategyId) external;

    // ═══════════════════════════════════════════════════════════
    //  VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════

    /// @notice Returns the strategy ID with the highest APY
    function getBestStrategy() external view returns (uint8 strategyId);

    /// @notice Returns full details of a strategy
    function getStrategy(uint8 strategyId) external view returns (Strategy memory);

    /// @notice Returns APY for a specific strategy
    function getAPY(uint8 strategyId) external view returns (uint256);
}
