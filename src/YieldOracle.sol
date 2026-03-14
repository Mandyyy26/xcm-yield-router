// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IYieldOracle.sol";

/// @title YieldOracle
/// @notice Admin-controlled APY feed with staleness and delta safety guards
contract YieldOracle is IYieldOracle, Ownable {

    // ── Constants ──────────────────────────────────────────────
    uint256 public constant MAX_REASONABLE_APY = 10_000; // 100% APY max (basis points × 100)

    // ── Config ─────────────────────────────────────────────────
    uint256 public maxStaleness = 1 days;
    uint256 public maxDeltaBps  = 500;   // max 5% change per update
    

    // ── State ──────────────────────────────────────────────────
    mapping(uint8 => uint256) private _yields;
    mapping(uint8 => uint256) private _lastUpdated;
    mapping(address => bool) public authorizedUpdaters;


    // ── Modifier ──────────────────────────────────────────────────
    modifier onlyAuthorized() {
    if (msg.sender != owner() && !authorizedUpdaters[msg.sender])
        revert UnauthorizedCaller(msg.sender);
    _;
}

    // ── Constructor ────────────────────────────────────────────
    constructor(address initialOwner) Ownable(initialOwner) {}

    // ── Admin Functions ────────────────────────────────────────

    /// @inheritdoc IYieldOracle
    function updateYield(uint8 strategyId, uint256 newYield) external onlyAuthorized {
        if (newYield > MAX_REASONABLE_APY) revert YieldTooHigh(newYield, MAX_REASONABLE_APY);

        uint256 current = _yields[strategyId];

        // Delta guard — only applies after first update
        if (_lastUpdated[strategyId] != 0) {
            uint256 delta = newYield > current
                ? newYield - current
                : current - newYield;

            if (delta > maxDeltaBps) revert DeltaExceedsLimit(delta, maxDeltaBps);
        }

        uint256 oldYield = current;
        _yields[strategyId]      = newYield;
        _lastUpdated[strategyId] = block.timestamp;

        emit YieldUpdated(strategyId, oldYield, newYield, block.timestamp);
    }

    /// @inheritdoc IYieldOracle
    function setMaxStaleness(uint256 newStaleness) external onlyOwner {
        emit MaxStalenessUpdated(maxStaleness, newStaleness);
        maxStaleness = newStaleness;
    }

    /// @inheritdoc IYieldOracle
    function setMaxDelta(uint256 newMaxDelta) external onlyOwner {
        emit MaxDeltaUpdated(maxDeltaBps, newMaxDelta);
        maxDeltaBps = newMaxDelta;
    }

    function setAuthorizedUpdater(address updater, bool authorized) external onlyOwner{
        authorizedUpdaters[updater] = authorized;
    }

    // ── View Functions ─────────────────────────────────────────

    /// @inheritdoc IYieldOracle
    function getYield(uint8 strategyId) external view returns (uint256) {
        if (isStale(strategyId)) revert StaleYieldData(strategyId, _lastUpdated[strategyId]);
        return _yields[strategyId];
    }

    /// @inheritdoc IYieldOracle
    function isStale(uint8 strategyId) public view returns (bool) {
        uint256 last = _lastUpdated[strategyId];
        if (last == 0) return true; // never updated = stale
        return (block.timestamp - last) > maxStaleness;
    }

    /// @inheritdoc IYieldOracle
    function lastUpdated(uint8 strategyId) external view returns (uint256) {
        return _lastUpdated[strategyId];
    }
}
