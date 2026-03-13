// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IStrategy.sol";
import "./interfaces/IYieldOracle.sol";

/// @title StrategyManager
/// @notice Registry and selector for yield strategies across parachains
contract StrategyManager is IStrategy, Ownable {

    // ── State ──────────────────────────────────────────────────
    mapping(uint8 => Strategy) private _strategies;
    uint8[] private _strategyIds;
    IYieldOracle public oracle;

    // ── Constructor ────────────────────────────────────────────
    constructor(address initialOwner, address _oracle) Ownable(initialOwner) {
        oracle = IYieldOracle(_oracle);
    }

    // ── Admin Functions ────────────────────────────────────────

    /// @inheritdoc IStrategy
    function registerStrategy(
        uint8 strategyId,
        uint32 parachainId,
        address strategyAddress,
        uint256 initialAPY
    ) external onlyOwner {
        if (_strategies[strategyId].parachainId != 0)
            revert StrategyAlreadyExists(strategyId);
        if (parachainId == 0)
            revert InvalidParachainId();
        if (initialAPY == 0)
            revert InvalidAPY(initialAPY);

        _strategies[strategyId] = Strategy({
            parachainId:     parachainId,
            strategyAddress: strategyAddress,
            currentAPY:      initialAPY,
            active:          true
        });
        _strategyIds.push(strategyId);

        emit StrategyRegistered(strategyId, parachainId, strategyAddress);
    }

    /// @inheritdoc IStrategy
    function updateAPY(uint8 strategyId, uint256 newAPY) external {
        // Callable by owner or oracle contract
        if (msg.sender != owner() && msg.sender != address(oracle))
            revert IStrategy.StrategyNotFound(strategyId);
        if (!_strategies[strategyId].active)
            revert StrategyInactive(strategyId);

        uint256 oldAPY = _strategies[strategyId].currentAPY;
        _strategies[strategyId].currentAPY = newAPY;

        emit APYUpdated(strategyId, oldAPY, newAPY);
    }

    /// @inheritdoc IStrategy
    function deactivateStrategy(uint8 strategyId) external onlyOwner {
        if (_strategies[strategyId].parachainId == 0)
            revert StrategyNotFound(strategyId);
        _strategies[strategyId].active = false;
        emit StrategyDeactivated(strategyId);
    }

    // ── View Functions ─────────────────────────────────────────

    /// @inheritdoc IStrategy
    function getBestStrategy() external view returns (uint8 bestId) {
        uint256 highestAPY = 0;
        bool found = false;

        for (uint256 i = 0; i < _strategyIds.length; i++) {
            uint8 id = _strategyIds[i];
            Strategy memory s = _strategies[id];

            if (!s.active) continue;

            // Use oracle yield if available, fallback to stored APY
            uint256 apy;
            try oracle.getYield(id) returns (uint256 oracleYield) {
                apy = oracleYield;
            } catch {
                apy = s.currentAPY;
            }

            if (apy > highestAPY) {
                highestAPY = apy;
                bestId     = id;
                found      = true;
            }
        }

        if (!found) revert NoActiveStrategies();
    }

    /// @inheritdoc IStrategy
    function getStrategy(uint8 strategyId) external view returns (Strategy memory) {
        if (_strategies[strategyId].parachainId == 0)
            revert StrategyNotFound(strategyId);
        return _strategies[strategyId];
    }

    /// @inheritdoc IStrategy
    function getAPY(uint8 strategyId) external view returns (uint256) {
        if (_strategies[strategyId].parachainId == 0)
            revert StrategyNotFound(strategyId);
        return _strategies[strategyId].currentAPY;
    }

    /// @notice Update oracle address
    function setOracle(address newOracle) external onlyOwner {
        oracle = IYieldOracle(newOracle);
    }
}
