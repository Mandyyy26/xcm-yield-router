"use client";

import { useState } from "react";
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt } from "wagmi";
import { parseEther, formatEther, maxUint256 } from "viem";
import { Card } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";
import { CONTRACT_ADDRESSES, VAULT_ABI, TOKEN_ABI } from "@/config/contracts";

export function DepositWithdraw() {
  const { address } = useAccount();
  const [tab,    setTab]    = useState<"deposit" | "withdraw">("deposit");
  const [amount, setAmount] = useState("");
  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming } = useWaitForTransactionReceipt({ hash });

  const { data: tokenBalance } = useReadContract({
    address: CONTRACT_ADDRESSES.mockToken,
    abi: TOKEN_ABI,
    functionName: "balanceOf",
    args: address ? [address] : undefined,
    query: { enabled: !!address, refetchInterval: 5000 },
  });

  const { data: shareBalance } = useReadContract({
    address: CONTRACT_ADDRESSES.hubVault,
    abi: VAULT_ABI,
    functionName: "balanceOf",
    args: address ? [address] : undefined,
    query: { enabled: !!address, refetchInterval: 5000 },
  });

  const { data: allowance } = useReadContract({
    address: CONTRACT_ADDRESSES.mockToken,
    abi: TOKEN_ABI,
    functionName: "allowance",
    args: address ? [address, CONTRACT_ADDRESSES.hubVault] : undefined,
    query: { enabled: !!address, refetchInterval: 5000 },
  });

  const parsedAmount = amount ? parseEther(amount) : BigInt(0);
  const needsApproval = tab === "deposit" && (allowance ?? BigInt(0)) < parsedAmount;

  function handleApprove() {
    writeContract({
      address: CONTRACT_ADDRESSES.mockToken,
      abi: TOKEN_ABI,
      functionName: "approve",
      args: [CONTRACT_ADDRESSES.hubVault, maxUint256],
    });
  }

  function handleDeposit() {
    writeContract({
      address: CONTRACT_ADDRESSES.hubVault,
      abi: VAULT_ABI,
      functionName: "deposit",
      args: [parsedAmount],
    });
  }

  function handleWithdraw() {
    writeContract({
      address: CONTRACT_ADDRESSES.hubVault,
      abi: VAULT_ABI,
      functionName: "withdraw",
      args: [parsedAmount],
    });
  }

  const isLoading = isPending || isConfirming;

  return (
    <Card title="Deposit / Withdraw" accent="green">
      {/* Tab Toggle */}
      <div className="flex rounded-lg overflow-hidden border border-gray-700 mb-5">
        {(["deposit", "withdraw"] as const).map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={`flex-1 py-2 text-sm font-medium transition-colors capitalize
              ${tab === t
                ? "bg-purple-600 text-white"
                : "bg-gray-800 text-gray-400 hover:text-gray-200"
              }`}
          >
            {t}
          </button>
        ))}
      </div>

      {/* Balances */}
      <div className="grid grid-cols-2 gap-3 mb-4 text-xs">
        <div className="bg-gray-800/60 rounded-lg p-3">
          <div className="text-gray-400 mb-1">Wallet Balance</div>
          <div className="font-mono text-white">
            {tokenBalance !== undefined
              ? `${parseFloat(formatEther(tokenBalance as bigint)).toFixed(2)} MTK`
              : "—"}
          </div>
        </div>
        <div className="bg-gray-800/60 rounded-lg p-3">
          <div className="text-gray-400 mb-1">Your Shares</div>
          <div className="font-mono text-purple-300">
            {shareBalance !== undefined
              ? parseFloat(formatEther(shareBalance as bigint)).toFixed(4)
              : "—"}
          </div>
        </div>
      </div>

      {/* Amount Input */}
      <div className="mb-4">
        <div className="flex items-center justify-between mb-1.5">
          <label className="text-xs text-gray-400">Amount</label>
          <button
            className="text-xs text-purple-400 hover:text-purple-300"
            onClick={() => {
              const bal = tab === "deposit" ? tokenBalance : shareBalance;
              if (bal) setAmount(formatEther(bal as bigint));
            }}
          >
            Max
          </button>
        </div>
        <input
          type="number"
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
          placeholder="0.00"
          className="w-full bg-gray-800 border border-gray-700 rounded-lg px-3 py-2.5
                     text-sm text-white placeholder-gray-500 focus:outline-none
                     focus:border-purple-500 font-mono"
        />
      </div>

      {/* Action Buttons */}
      {!address ? (
        <p className="text-center text-sm text-gray-500">Connect wallet to continue</p>
      ) : tab === "deposit" ? (
        <div className="space-y-2">
          {needsApproval && (
            <Button
              className="w-full"
              variant="secondary"
              onClick={handleApprove}
              loading={isLoading}
            >
              Approve MTK
            </Button>
          )}
          <Button
            className="w-full"
            onClick={handleDeposit}
            loading={isLoading}
            disabled={!amount || parsedAmount === BigInt(0) || needsApproval}
          >
            Deposit
          </Button>
        </div>
      ) : (
        <Button
          className="w-full"
          onClick={handleWithdraw}
          loading={isLoading}
          disabled={!amount || parsedAmount === BigInt(0)}
        >
          Withdraw
        </Button>
      )}

      {/* Tx Hash */}
      {hash && (
        <div className="mt-3 text-xs text-gray-400 font-mono break-all">
          Tx: <a
            href={`https://blockscout-testnet.polkadot.io/tx/${hash}`}
            target="_blank"
            rel="noopener noreferrer"
            className="text-purple-400 hover:underline"
          >
            {hash.slice(0, 20)}...
          </a>
        </div>
      )}
    </Card>
  );
}
