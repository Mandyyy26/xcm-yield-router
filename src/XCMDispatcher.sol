// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IXCMDispatcher.sol";
import "./interfaces/IXCM.sol";
import "./libraries/XcmEncoder.sol";

/// @title XCMDispatcher
/// @notice Builds and dispatches XCM messages via the Polkadot Hub XCM precompile
/// @dev Core Polkadot-native integration — calls weighMessage() + execute()/send()
contract XCMDispatcher is IXCMDispatcher, Ownable, ReentrancyGuard {

    // ── XCM Precompile ─────────────────────────────────────────
    IXcm public constant XCM = IXcm(XCM_PRECOMPILE_ADDRESS);

    // ── Config ─────────────────────────────────────────────────
    uint64  public maxRefTime   = 1_500_000_000;  // 1.5x buffer over 979,880,000
    uint64  public maxProofSize = 20_000;          // 1.8x buffer over 10,943
    uint256 public cooldown     = 10 minutes;
    address public vault;                          // only vault can dispatch

    // ── State ──────────────────────────────────────────────────
    uint256 public lastDispatchTime;
    mapping(uint32 => DispatchResult) private _lastDispatch;
    bool public dispatchPaused;

    // ── Constructor ────────────────────────────────────────────
    constructor(address initialOwner, address _vault) Ownable(initialOwner) {
        vault = _vault;
    }

    // ── Modifiers ──────────────────────────────────────────────

    modifier onlyVault() {
        if (msg.sender != vault) revert UnauthorizedCaller(msg.sender);
        _;
    }

    modifier checkCooldown() {
        if (block.timestamp < lastDispatchTime + cooldown)
            revert DispatchCooldownActive(lastDispatchTime + cooldown);
        _;
    }

    modifier whenDispatchNotPaused() {
    if (dispatchPaused) revert DispatchPaused();
    _;
}

    // ── Core Functions ─────────────────────────────────────────

    /// @inheritdoc IXCMDispatcher
    function estimateWeight(
        uint32 parachainId,
        address recipient,
        uint256 amount
    ) external override returns (XCMWeight memory weight) {
        bytes memory message = XcmEncoder.encodeTransferMessage(recipient, amount);
        IXcm.Weight memory w = XCM.weighMessage(message);

        // Suppress unused param warning
        parachainId;

        emit WeightQueried(parachainId, w.refTime, w.proofSize);
        return XCMWeight({ refTime: w.refTime, proofSize: w.proofSize });
    }

    /// @inheritdoc IXCMDispatcher
    function sendToParachain(
        uint32 parachainId,
        address recipient,
        uint256 amount
    )
        external
        override
        onlyVault
        nonReentrant
        checkCooldown
        whenDispatchNotPaused
        returns (DispatchResult memory result)
    {
        if (amount == 0) revert ZeroAmount();
        if (parachainId == 0) revert InvalidParachainId(parachainId);

        // ── Step 1: Encode XCM message ────────────────────────
        bytes memory message = XcmEncoder.encodeTransferMessage(recipient, amount);

        // ── Step 2: Estimate weight (weighMessage) ────────────
        IXcm.Weight memory weight = XCM.weighMessage(message);

        emit WeightQueried(parachainId, weight.refTime, weight.proofSize);

        // ── Step 3: Validate weight against safety limits ─────
        if (weight.refTime > maxRefTime) {
            emit DispatchRejected(
                parachainId,
                weight.refTime,
                maxRefTime,
                "refTime exceeds limit"
            );
            revert WeightExceedsLimit(weight.refTime, maxRefTime);
        }
        if (weight.proofSize > maxProofSize) {
            emit DispatchRejected(
                parachainId,
                weight.proofSize,
                maxProofSize,
                "proofSize exceeds limit"
            );
            revert WeightExceedsLimit(weight.proofSize, maxProofSize);
        }

        // ── Step 4: Execute/Send XCM ──────────────────────────
        // Use execute() for local + cross-chain operations (main entrypoint per docs)
        XCM.execute(message, IXcm.Weight({
            refTime:   weight.refTime,
            proofSize: weight.proofSize
        }));

        // ── Step 5: Update state + emit ───────────────────────
        lastDispatchTime = block.timestamp;

        bytes32 msgId = keccak256(abi.encodePacked(
            parachainId, recipient, amount, block.timestamp
        ));

        result = DispatchResult({
            success:   true,
            refTime:   weight.refTime,
            proofSize: weight.proofSize,
            messageId: msgId
        });

        _lastDispatch[parachainId] = result;

        emit XCMDispatched(
            parachainId,
            recipient,
            amount,
            weight.refTime,
            weight.proofSize,
            block.timestamp
        );

        return result;
    }

    // ── Admin Functions ────────────────────────────────────────

    /// @inheritdoc IXCMDispatcher
    function setMaxWeight(uint64 newMaxRefTime, uint64 newMaxProofSize)
        external
        override
        onlyOwner
    {
        maxRefTime   = newMaxRefTime;
        maxProofSize = newMaxProofSize;
    }

    /// @inheritdoc IXCMDispatcher
    function setCooldown(uint256 newCooldown) external override onlyOwner {
        cooldown = newCooldown;
    }

    /// @notice Update vault address
    function setVault(address newVault) external onlyOwner {
        vault = newVault;
    }

    ///@notice pause Dispatch
    function pauseDispatch() external onlyOwner {
        dispatchPaused = true;
    }

    ///@notice unpause Dispatch
    function unpauseDispatch() external onlyOwner {
        dispatchPaused = false;
    }

    // ── View Functions ─────────────────────────────────────────

    /// @inheritdoc IXCMDispatcher
    function lastDispatch(uint32 parachainId)
        external
        view
        override
        returns (DispatchResult memory)
    {
        return _lastDispatch[parachainId];
    }

    /// @inheritdoc IXCMDispatcher
    function nextDispatchAllowed() external view override returns (uint256) {
        return lastDispatchTime + cooldown;
    }

    /// @inheritdoc IXCMDispatcher
    function maxWeight() external view override returns (XCMWeight memory) {
        return XCMWeight({ refTime: maxRefTime, proofSize: maxProofSize });
    }
}
