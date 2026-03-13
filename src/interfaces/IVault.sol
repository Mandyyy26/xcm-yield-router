// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title IVault
/// @notice Interface for the HubVault — main entry point for users
interface IVault {

    // ═══════════════════════════════════════════════════════════
    //  ENUMS
    // ═══════════════════════════════════════════════════════════

    /// @notice Tracks the current state of vault funds
    enum VaultState {
        Idle,            // funds sitting in vault, not deployed
        OutboundPending, // XCM sent, waiting for destination confirmation
        Allocated        // funds deployed to active strategy
    }

    // ═══════════════════════════════════════════════════════════
    //  EVENTS
    // ═══════════════════════════════════════════════════════════

    /// @notice Emitted when a user deposits tokens
    event Deposited(address indexed user, uint256 amount, uint256 sharesIssued);

    /// @notice Emitted when a user withdraws tokens
    event Withdrawn(address indexed user, uint256 shares, uint256 amountReturned);

    /// @notice Emitted when vault rebalances to a new strategy
    event Rebalanced(uint8 indexed oldStrategyId, uint8 indexed newStrategyId, uint256 amount);

    /// @notice Emitted when vault state changes
    event StateChanged(VaultState indexed oldState, VaultState indexed newState);

    /// @notice Emitted when emergency pause is triggered
    event EmergencyPaused(address indexed by);

    /// @notice Emitted when admin resets vault to Idle after stuck XCM
    event EmergencyReset(address indexed by, VaultState fromState);

    // ═══════════════════════════════════════════════════════════
    //  ERRORS
    // ═══════════════════════════════════════════════════════════

    error ZeroAmount();
    error InsufficientShares(uint256 requested, uint256 available);
    error VaultNotIdle(VaultState current);
    error RebalanceNotNeeded(uint8 currentStrategyId);
    error VaultPaused();
    error ZeroTotalAssets();

    // ═══════════════════════════════════════════════════════════
    //  USER FUNCTIONS
    // ═══════════════════════════════════════════════════════════

    /// @notice Deposit tokens into vault and receive shares
    /// @param amount Amount of tokens to deposit
    function deposit(uint256 amount) external;

    /// @notice Withdraw tokens by burning shares
    /// @param shares Number of shares to burn
    function withdraw(uint256 shares) external;

    // ═══════════════════════════════════════════════════════════
    //  KEEPER / ADMIN FUNCTIONS
    // ═══════════════════════════════════════════════════════════

    /// @notice Rebalance vault to the highest-yield strategy
    function rebalance() external;

    /// @notice Pause all vault operations in emergency
    function emergencyPause() external;

    /// @notice Reset vault state to Idle (if XCM gets stuck)
    function emergencyReset() external;

    // ═══════════════════════════════════════════════════════════
    //  VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════

    /// @notice Total tokens managed by vault (deployed + held)
    function totalAssets() external view returns (uint256);

    /// @notice Total shares in circulation
    function totalShares() external view returns (uint256);

    /// @notice Convert a token amount to equivalent shares
    function convertToShares(uint256 amount) external view returns (uint256);

    /// @notice Convert shares to equivalent token amount
    function convertToAssets(uint256 shares) external view returns (uint256);

    /// @notice Current vault state
    function getVaultState() external view returns (VaultState);

    /// @notice Currently active strategy ID
    function getActiveStrategyId() external view returns (uint8);
}
