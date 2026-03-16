"use client";

import { useState } from "react";
import { useAccount, useWriteContract, useWaitForTransactionReceipt, useReadContract } from "wagmi";
import { Card } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";
import { CONTRACT_ADDRESSES, ORACLE_ABI, VAULT_ABI } from "@/config/contracts";

const OWNER_ADDRESS = "0x2cD2DB7E8F6d061487D086015874f065b6ACd67a";

export function AdminPanel() {
  const { address }  = useAccount();
  const [stratId,  setStratId]  = useState("0");
  const [newYield, setNewYield] = useState("");

  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming } = useWaitForTransactionReceipt({ hash });

  const isOwner = address?.toLowerCase() === OWNER_ADDRESS.toLowerCase();
  const isLoading = isPending || isConfirming;

  if (!address || !isOwner) return null;

  function handleUpdateYield() {
    writeContract({
      address: CONTRACT_ADDRESSES.yieldOracle,
      abi: ORACLE_ABI,
      functionName: "updateYield",
      args: [Number(stratId), BigInt(newYield)],
    });
  }

  function handleRebalance() {
    writeContract({
      address: CONTRACT_ADDRESSES.hubVault,
      abi: VAULT_ABI,
      functionName: "rebalance",
    });
  }

  function handlePause() {
    writeContract({
      address: CONTRACT_ADDRESSES.hubVault,
      abi: VAULT_ABI,
      functionName: "emergencyPause",
    });
  }

  function handleReset() {
    writeContract({
      address: CONTRACT_ADDRESSES.hubVault,
      abi: VAULT_ABI,
      functionName: "emergencyReset",
    });
  }

  return (
    <Card title="🔐 Admin Panel" accent="purple">
      <div className="text-xs text-purple-400 mb-4 font-mono">
        Owner: {address.slice(0, 8)}...{address.slice(-6)}
      </div>

      {/* Update Yield */}
      <div className="space-y-2 mb-5">
        <div className="text-xs text-gray-400 font-semibold uppercase tracking-wider">
          Update Oracle Yield
        </div>
        <div className="flex gap-2">
          <select
            value={stratId}
            onChange={(e) => setStratId(e.target.value)}
            className="bg-gray-800 border border-gray-700 rounded-lg px-2 py-2 text-sm text-white"
          >
            <option value="0">Strategy 0 (Para A)</option>
            <option value="1">Strategy 1 (Para B)</option>
          </select>
          <input
            type="number"
            value={newYield}
            onChange={(e) => setNewYield(e.target.value)}
            placeholder="APY in bps (e.g. 800)"
            className="flex-1 bg-gray-800 border border-gray-700 rounded-lg px-3 py-2
                       text-sm text-white placeholder-gray-500 focus:outline-none focus:border-purple-500"
          />
        </div>
        <Button className="w-full" onClick={handleUpdateYield} loading={isLoading} disabled={!newYield}>
          Update Yield
        </Button>
      </div>

      {/* Rebalance */}
      <div className="space-y-2 mb-5">
        <div className="text-xs text-gray-400 font-semibold uppercase tracking-wider">
          Trigger Rebalance
        </div>
        <p className="text-xs text-gray-500">
          Calls StrategyManager → XCMDispatcher → weighMessage() → send()
        </p>
        <Button className="w-full" variant="secondary" onClick={handleRebalance} loading={isLoading}>
          Rebalance Now
        </Button>
      </div>

      {/* Emergency Controls */}
      <div className="space-y-2 border-t border-gray-700 pt-4">
        <div className="text-xs text-red-400 font-semibold uppercase tracking-wider">
          Emergency Controls
        </div>
        <div className="grid grid-cols-2 gap-2">
          <Button variant="danger" onClick={handlePause} loading={isLoading}>
            Pause Vault
          </Button>
          <Button variant="secondary" onClick={handleReset} loading={isLoading}>
            Reset State
          </Button>
        </div>
      </div>

      {hash && (
        <div className="mt-3 text-xs font-mono text-gray-400 break-all">
          Tx: <a href={`https://blockscout-testnet.polkadot.io/tx/${hash}`}
            target="_blank" rel="noopener noreferrer"
            className="text-purple-400 hover:underline"
          >{hash.slice(0, 24)}...</a>
        </div>
      )}
    </Card>
  );
}
