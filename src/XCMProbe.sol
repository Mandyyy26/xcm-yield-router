// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./interfaces/IXCM.sol";

/// @title XCMProbe
/// @notice Spike contract to validate XCM precompile works on Polkadot Hub testnet
/// @dev NOT production code — for testing and research only
contract XCMProbe {

    IXcm public constant XCM = IXcm(XCM_PRECOMPILE_ADDRESS);

    // ── Storage for last results (so we can read them after tx) ──
    uint64 public lastRefTime;
    uint64 public lastProofSize;
    bool  public lastExecuteSuccess;

    // ── Events ──
    event WeightResult(uint64 refTime, uint64 proofSize);
    event ExecuteAttempted(bytes message, uint64 refTime, uint64 proofSize);

    // ─────────────────────────────────────────────────────────────
    //  Official test vector from Polkadot docs
    //  Encodes: WithdrawAsset → BuyExecution → DepositAsset
    // ─────────────────────────────────────────────────────────────
    bytes public constant TEST_MESSAGE =
        hex"050c000401000003008c86471301000003008c8647000d010101000000010100368e8759910dab756d344995f1d3c79374ca8f70066d3a709e48029f6bf0ee7e";

    // ─────────────────────────────────────────────────────────────
    //  STEP 1: Call weighMessage with the official test vector
    //  This is a VIEW call — costs no gas, safe to call anytime
    // ─────────────────────────────────────────────────────────────
    function probeWeigh() external view returns (uint64 refTime, uint64 proofSize) {
        IXcm.Weight memory w = XCM.weighMessage(TEST_MESSAGE);
        return (w.refTime, w.proofSize);
    }

    // ─────────────────────────────────────────────────────────────
    //  STEP 2: Call weighMessage and STORE results on-chain
    //  Use this to verify state is being written
    // ─────────────────────────────────────────────────────────────
    function probeWeighAndStore() external {
        IXcm.Weight memory w = XCM.weighMessage(TEST_MESSAGE);
        lastRefTime   = w.refTime;
        lastProofSize = w.proofSize;
        emit WeightResult(w.refTime, w.proofSize);
    }

    // ─────────────────────────────────────────────────────────────
    //  STEP 3: Attempt execute with test vector
    //  weighMessage first → use returned weight → call execute
    // ─────────────────────────────────────────────────────────────
    function probeExecute() external {
        // 1. Get weight estimate
        IXcm.Weight memory w = XCM.weighMessage(TEST_MESSAGE);

        // 2. Store for inspection
        lastRefTime   = w.refTime;
        lastProofSize = w.proofSize;

        // 3. Attempt execute with the estimated weight
        XCM.execute(TEST_MESSAGE, w);

        lastExecuteSuccess = true;
        emit ExecuteAttempted(TEST_MESSAGE, w.refTime, w.proofSize);
    }

    // ─────────────────────────────────────────────────────────────
    //  STEP 4: Custom message test
    //  Pass your own encoded bytes to test custom XCM messages
    // ─────────────────────────────────────────────────────────────
    function probeCustomMessage(bytes calldata message) external {
        IXcm.Weight memory w = XCM.weighMessage(message);
        lastRefTime   = w.refTime;
        lastProofSize = w.proofSize;
        emit WeightResult(w.refTime, w.proofSize);
    }

    // ── View helpers ──
    function getLastWeight() external view returns (uint64 refTime, uint64 proofSize) {
        return (lastRefTime, lastProofSize);
    }

    function getPrecompileAddress() external pure returns (address) {
        return XCM_PRECOMPILE_ADDRESS;
    }
}
