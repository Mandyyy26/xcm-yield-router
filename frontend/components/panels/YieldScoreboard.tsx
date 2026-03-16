"use client";

import { useReadContracts } from "wagmi";
import { Card } from "@/components/ui/Card";
import { Badge } from "@/components/ui/Badge";
import { CONTRACT_ADDRESSES, ORACLE_ABI, VAULT_ABI } from "@/config/contracts";

export function YieldScoreboard() {
  const { data } = useReadContracts({
    contracts: [
      // Read isStale for both strategies
      { address: CONTRACT_ADDRESSES.yieldOracle as `0x${string}`, abi: ORACLE_ABI, functionName: "isStale",  args: [0] },
      { address: CONTRACT_ADDRESSES.yieldOracle as `0x${string}`, abi: ORACLE_ABI, functionName: "isStale",  args: [1] },
      // ✅ Actually read APY from oracle — these were hardcoded before
      { address: CONTRACT_ADDRESSES.yieldOracle as `0x${string}`, abi: ORACLE_ABI, functionName: "getYield", args: [0] },
      { address: CONTRACT_ADDRESSES.yieldOracle as `0x${string}`, abi: ORACLE_ABI, functionName: "getYield", args: [1] },
      // Active strategy from vault
      { address: CONTRACT_ADDRESSES.hubVault as `0x${string}`,    abi: VAULT_ABI,  functionName: "activeStrategyId" },
    ] as const,
    query: { refetchInterval: 3000 }, // poll every 3s
  });

  const stale0           = data?.[0]?.result as boolean | undefined;
  const stale1           = data?.[1]?.result as boolean | undefined;
  // Use result if call succeeded, fallback to 0 if stale (getYield reverts when stale)
  const apy0             = data?.[2]?.status === "success" ? Number(data[2].result as bigint) : 0;
  const apy1             = data?.[3]?.status === "success" ? Number(data[3].result as bigint) : 0;
  const activeStrategyId = data?.[4]?.result as number | undefined;

  const strategies = [
    { id: 0, name: "Parachain A", parachainId: 1000, apy: apy0, stale: stale0 },
    { id: 1, name: "Parachain B", parachainId: 2000, apy: apy1, stale: stale1 },
  ];

  // Best = highest APY among non-stale strategies
  const bestId = strategies.reduce((best, s) =>
    s.apy > strategies[best].apy ? s.id : best, 0
  );

  return (
    <Card title="Yield Scoreboard" accent="orange">
      <div className="space-y-3">
        {strategies.map((s) => (
          <div
            key={s.id}
            className={`rounded-lg p-3 border transition-all ${
              s.id === bestId && s.apy > 0
                ? "border-green-500/40 bg-green-500/10"
                : "border-gray-700/50 bg-gray-800/40"
            }`}
          >
            <div className="flex items-center justify-between mb-2">
              <div className="flex items-center gap-2">
                <span className="text-sm font-medium text-white">{s.name}</span>
                {s.id === bestId && s.apy > 0 && (
                  <Badge label="Best" variant="active" />
                )}
                {s.id === activeStrategyId && (
                  <Badge label="Active" variant="allocated" />
                )}
              </div>
              {s.stale !== undefined && (
                <Badge
                  label={s.stale ? "Stale" : "Live"}
                  variant={s.stale ? "stale" : "active"}
                />
              )}
            </div>

            {/* APY Bar */}
            <div className="space-y-1">
              <div className="flex justify-between text-xs">
                <span className="text-gray-400">APY</span>
                <span className="font-mono text-green-300 font-bold">
                  {s.apy > 0 ? `${(s.apy / 100).toFixed(2)}%` : "—"}
                </span>
              </div>
              <div className="w-full bg-gray-700 rounded-full h-1.5">
                <div
                  className="bg-linear-to-r from-purple-500 to-green-500 h-1.5 rounded-full transition-all duration-500"
                  style={{ width: `${Math.min((s.apy / 1000) * 100, 100)}%` }}
                />
              </div>
            </div>

            <div className="mt-2 text-xs text-gray-500 font-mono">
              Parachain ID: {s.parachainId}
            </div>
          </div>
        ))}
      </div>

      <div className="mt-3 text-xs text-gray-500 text-center">
        APY sourced from YieldOracle contract · refreshes every 3s
      </div>
    </Card>
  );
}
