// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IStrategy.sol";
import "./interfaces/IXCMDispatcher.sol";

/// @title HubVault
/// @notice Main vault contract — users deposit tokens, vault routes to best yield via XCM
contract HubVault is IVault, ERC20, Ownable, ReentrancyGuard, Pausable {

    using SafeERC20 for IERC20;

    // ── State ──────────────────────────────────────────────────
    IERC20          public immutable asset;
    IStrategy       public strategyManager;
    IXCMDispatcher  public xcmDispatcher;

    VaultState      public vaultState;
    uint8           public activeStrategyId;
    uint256         public totalDeposited;

    // ── Constructor ────────────────────────────────────────────
    constructor(
        address _asset,
        address _strategyManager,
        address _xcmDispatcher,
        address initialOwner
    )
        ERC20("XCMYieldRouter Share", "XCMYR")
        Ownable(initialOwner)
    {
        asset           = IERC20(_asset);
        strategyManager = IStrategy(_strategyManager);
        xcmDispatcher   = IXCMDispatcher(_xcmDispatcher);
        vaultState      = VaultState.Idle;
    }

    // ── Modifiers ──────────────────────────────────────────────

    modifier onlyIdle() {
        if (vaultState != VaultState.Idle) revert VaultNotIdle(vaultState);
        _;
    }

    // ── User Functions ─────────────────────────────────────────

    /// @inheritdoc IVault
    function deposit(uint256 amount)
        external
        override
        nonReentrant
        whenNotPaused
        onlyIdle
    {
        if (amount == 0) revert ZeroAmount();

        uint256 shares = _computeShares(amount);

        // Effects before interactions (CEI pattern)
        totalDeposited += amount;

        // Interaction
        asset.safeTransferFrom(msg.sender, address(this), amount);

        // Mint shares to depositor
        _mint(msg.sender, shares);

        emit Deposited(msg.sender, amount, shares);
    }

    /// @inheritdoc IVault
    function withdraw(uint256 shares)
        external
        override
        nonReentrant
        whenNotPaused
        onlyIdle
    {
        if (shares == 0) revert ZeroAmount();
        if (balanceOf(msg.sender) < shares)
            revert InsufficientShares(shares, balanceOf(msg.sender));

        uint256 amount = convertToAssets(shares);

        // Effects before interactions
        totalDeposited -= amount;
        _burn(msg.sender, shares);

        // Interaction
        asset.safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, shares, amount);
    }

    // ── Keeper / Admin Functions ───────────────────────────────

    /// @inheritdoc IVault
    function rebalance()
        external
        override
        onlyOwner
        nonReentrant
        whenNotPaused
        onlyIdle
    {
        uint8 bestStrategyId = strategyManager.getBestStrategy();

        if (bestStrategyId == activeStrategyId)
            revert RebalanceNotNeeded(activeStrategyId);

        uint256 amount = totalAssets();
        if (amount == 0) revert ZeroTotalAssets();

        // Get destination from strategy manager
        IStrategy.Strategy memory strategy = strategyManager.getStrategy(bestStrategyId);

        uint8 oldStrategyId = activeStrategyId;

        // Update state BEFORE external call (CEI)
        _changeState(VaultState.Idle, VaultState.OutboundPending);
        activeStrategyId = bestStrategyId;

        // Approve dispatcher to spend tokens
        asset.forceApprove(address(xcmDispatcher), amount);

        // Dispatch XCM
        xcmDispatcher.sendToParachain(
            strategy.parachainId,
            strategy.strategyAddress,
            amount
        );

        emit Rebalanced(oldStrategyId, bestStrategyId, amount);
    }

    /// @inheritdoc IVault
    function emergencyPause() external override onlyOwner {
        _pause();
        emit EmergencyPaused(msg.sender);
    }

    /// @inheritdoc IVault
    function emergencyReset() external override onlyOwner {
        VaultState fromState = vaultState;
        vaultState = VaultState.Idle;
        emit EmergencyReset(msg.sender, fromState);
    }

    /// @notice Unpause vault
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Update strategy manager address
    function setStrategyManager(address newManager) external onlyOwner {
        strategyManager = IStrategy(newManager);
    }

    /// @notice Update XCM dispatcher address
    function setXCMDispatcher(address newDispatcher) external onlyOwner {
        xcmDispatcher = IXCMDispatcher(newDispatcher);
    }

    // ── View Functions ─────────────────────────────────────────

    /// @inheritdoc IVault
    function totalAssets() public view override returns (uint256) {
        return asset.balanceOf(address(this));
    }

    /// @inheritdoc IVault
    function totalShares() external view override returns (uint256) {
        return totalSupply();
    }

    /// @inheritdoc IVault
    function convertToShares(uint256 amount) public view override returns (uint256) {
        return _computeShares(amount);
    }

    /// @inheritdoc IVault
    function convertToAssets(uint256 shares) public view override returns (uint256) {
        uint256 supply = totalSupply();
        if (supply == 0) return shares;
        return (shares * totalAssets()) / supply;
    }

    /// @inheritdoc IVault
    function getVaultState() external view override returns (VaultState) {
        return vaultState;
    }

    /// @inheritdoc IVault
    function getActiveStrategyId() external view override returns (uint8) {
        return activeStrategyId;
    }

    // ── Internal Helpers ───────────────────────────────────────

    function _computeShares(uint256 amount) internal view returns (uint256) {
        uint256 supply = totalSupply();
        uint256 assets = totalAssets();
        if (supply == 0 || assets == 0) return amount; // 1:1 on first deposit
        return (amount * supply) / assets;
    }

    function _changeState(VaultState from, VaultState to) internal {
        vaultState = to;
        emit StateChanged(from, to);
    }
}
