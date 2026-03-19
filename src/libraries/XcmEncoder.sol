// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

library XcmEncoder {

    // ── Destination (used by send() if needed) ─────────────────
    function encodeParachainDestination(uint32 parachainId)
        internal pure returns (bytes memory)
    {
        return abi.encodePacked(
            bytes1(0x03),                    // VersionedLocation V4
            bytes1(0x01),                    // parents = 1
            bytes1(0x01),                    // X1 interior
            bytes1(0x00),                    // Parachain junction
            _encodeCompactU32(parachainId)
        );
    }

    // ── Main message encoder ───────────────────────────────────
    // Pattern: WithdrawAsset → BuyExecution → DepositAsset
    function encodeTransferMessage(address recipient, uint256 amount)
        internal pure returns (bytes memory)
    {
        bytes32 accountId = bytes32(uint256(uint160(recipient)));
        bytes memory amountCompact   = _encodeCompactU128(amount);
        bytes memory feeCompact      = _encodeCompactU128(amount / 10); // 10% for fees

        return abi.encodePacked(
            // VersionedXcm::V4
            bytes1(0x04),
            // Vec length: 3 instructions
            bytes1(0x0c),

            // ── 1. WithdrawAsset ──────────────────────────────
            bytes1(0x00),       // WithdrawAsset opcode
            bytes1(0x04),       // AssetFilter: vec len 1
            bytes1(0x00),       // AssetId: Concrete
            bytes1(0x02),       // MultiLocation: parents=0, X1
            bytes1(0x04),       // X1 junction count = 1
            bytes1(0x06),       // PalletInstance junction
            bytes1(0x32),       // pallet index 50 = Balances
            bytes1(0x01),       // Fungibility: Fungible
            amountCompact,

            // ── 2. BuyExecution ───────────────────────────────
            bytes1(0x04),       // BuyExecution opcode
            bytes1(0x00),       // AssetId: Concrete
            bytes1(0x02),       // MultiLocation: parents=0, X1
            bytes1(0x04),       // X1
            bytes1(0x06),       // PalletInstance
            bytes1(0x32),       // index 50
            bytes1(0x01),       // Fungible
            feeCompact,
            bytes1(0x00),       // WeightLimit: Unlimited

            // ── 3. DepositAsset ───────────────────────────────
            bytes1(0x05),       // DepositAsset opcode
            bytes1(0x01),       // AssetFilter: Wild
            bytes1(0x00),       // Wild::All
            bytes1(0x00),       // MultiLocation: parents=0
            bytes1(0x01),       // X1
            bytes1(0x01),       // AccountId32 junction
            bytes1(0x00),       // Network: None
            accountId           // 32-byte recipient
        );
    }

    // ── SCALE compact u128 ─────────────────────────────────────
    function _encodeCompactU128(uint256 v) internal pure returns (bytes memory) {
        if (v <= 63) {
            return abi.encodePacked(uint8(v << 2));
        } else if (v <= 16383) {
            uint16 e = uint16((v << 2) | 1);
            return abi.encodePacked(uint8(e), uint8(e >> 8));
        } else if (v <= 1073741823) {
            uint32 e = uint32((v << 2) | 2);
            return abi.encodePacked(
                uint8(e), uint8(e >> 8), uint8(e >> 16), uint8(e >> 24)
            );
        } else {
            // Big integer mode
            return abi.encodePacked(bytes1(0x33), uint128(v));
        }
    }

    // ── SCALE compact u32 ──────────────────────────────────────
    function _encodeCompactU32(uint32 v) internal pure returns (bytes memory) {
        if (v <= 63) {
            return abi.encodePacked(uint8(v << 2));
        } else if (v <= 16383) {
            uint16 e = uint16((v << 2) | 1);
            return abi.encodePacked(uint8(e), uint8(e >> 8));
        } else {
            uint32 e = (v << 2) | 2;
            return abi.encodePacked(
                uint8(e), uint8(e >> 8), uint8(e >> 16), uint8(e >> 24)
            );
        }
    }

    function addressToAccountId32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }
}
