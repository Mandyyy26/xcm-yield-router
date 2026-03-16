"use client";

import { useReadContracts, useReadContract } from "wagmi";
import { formatEther } from "viem";
import { useAccount } from "wagmi";
import { Card } from "@/components/ui/Card";
import { VaultStateBadge } from "@/components/ui/Badge";
import { CONTRACT_ADDRESSES, VAULT_ABI } from "@/config/contracts";

export function VaultStatus() {
  const { address } = useAccount();

  // ── Call 1: Static vault data (no conditional) ──
  const { data, isLoading } = useReadContracts({
    contracts: [
      { address: CONTRACT_ADDRESSES.hubVault as `0x${string}`, abi: VAULT_ABI, functionName: "totalAssets"       },
      { address: CONTRACT_ADDRESSES.hubVault as `0x${string}`, abi: VAULT_ABI, functionName: "totalSupply"       },
      { address: CONTRACT_ADDRESSES.hubVault as `0x${string}`, abi: VAULT_ABI, functionName: "vaultState"        },
      { address: CONTRACT_ADDRESSES.hubVault as `0x${string}`, abi: VAULT_ABI, functionName: "activeStrategyId"  },
      { address: CONTRACT_ADDRESSES.hubVault as `0x${string}`, abi: VAULT_ABI, functionName: "rebalanceNonce"    },
    ] as const,
    query: { refetchInterval: 5000 },
  });

  // ── Call 2: User-specific data (separate, enabled only when connected) ──
  const { data: userShares } = useReadContract({
    address: CONTRACT_ADDRESSES.hubVault as `0x${string}`,
    abi: VAULT_ABI,
    functionName: "balanceOf",
    args: [address!],
    query: {
      enabled: !!address,
      refetchInterval: 5000,
    },
  });

  const totalAssets      = data?.[0]?.result as bigint | undefined;
  const totalShares      = data?.[1]?.result as bigint | undefined;
  const vaultState       = data?.[2]?.result as number | undefined;
  const activeStrategyId = data?.[3]?.result as number | undefined;
  const nonce            = data?.[4]?.result as bigint | undefined;

  const strategyNames: Record<number, string> = {
    0: "Parachain A (ID: 1000)",
    1: "Parachain B (ID: 2000)",
  };

  return (
    <Card title="Vault Status" accent="purple">
      {isLoading ? (
        <div className="space-y-3">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="h-8 bg-gray-800 rounded animate-pulse" />
          ))}
        </div>
      ) : (
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <span className="text-sm text-gray-400">Vault State</span>
            <VaultStateBadge state={vaultState ?? 0} />
          </div>

          <div className="flex items-center justify-between">
            <span className="text-sm text-gray-400">Total Assets</span>
            <span className="text-sm font-mono text-white">
              {totalAssets !== undefined
                ? `${parseFloat(formatEther(totalAssets)).toFixed(4)} MTK`
                : "—"}
            </span>
          </div>

          <div className="flex items-center justify-between">
            <span className="text-sm text-gray-400">Total Shares</span>
            <span className="text-sm font-mono text-white">
              {totalShares !== undefined
                ? parseFloat(formatEther(totalShares)).toFixed(4)
                : "—"}
            </span>
          </div>

          {address && (
            <div className="flex items-center justify-between border-t border-gray-800 pt-3">
              <span className="text-sm text-gray-400">Your Shares</span>
              <span className="text-sm font-mono text-purple-300">
                {userShares !== undefined
                  ? parseFloat(formatEther(userShares as bigint)).toFixed(4)
                  : "—"}
              </span>
            </div>
          )}

          <div className="flex items-center justify-between">
            <span className="text-sm text-gray-400">Active Strategy</span>
            <span className="text-sm text-white">
              {activeStrategyId !== undefined
                ? strategyNames[activeStrategyId] ?? `ID: ${activeStrategyId}`
                : "None"}
            </span>
          </div>

          <div className="flex items-center justify-between">
            <span className="text-sm text-gray-400">Rebalance #</span>
            <span className="text-sm font-mono text-gray-300">
              {nonce?.toString() ?? "0"}
            </span>
          </div>
        </div>
      )}
    </Card>
  );
}
