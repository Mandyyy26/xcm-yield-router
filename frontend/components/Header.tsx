"use client";

import { useAccount, useConnect, useDisconnect } from "wagmi";
import { injected } from "wagmi/connectors";
import { Button } from "./ui/Button";

export function Header() {
  const { address, isConnected } = useAccount();
  const { connect }              = useConnect();
  const { disconnect }           = useDisconnect();

  return (
    <header className="border-b border-gray-800 px-6 py-4 flex items-center justify-between">
      <div className="flex items-center gap-3">
        <div className="w-8 h-8 rounded-lg bg-purple-600 flex items-center justify-center text-sm font-bold">
          X
        </div>
        <div>
          <h1 className="text-lg font-bold text-white">XCMYieldRouter</h1>
          <p className="text-xs text-gray-400">Cross-chain yield optimizer · Polkadot Hub</p>
        </div>
      </div>

      <div className="flex items-center gap-3">
        <div className="flex items-center gap-1.5 text-xs text-green-400">
          <span className="w-1.5 h-1.5 rounded-full bg-green-400 animate-pulse" />
          Polkadot Hub TestNet
        </div>

        {isConnected ? (
          <div className="flex items-center gap-2">
            <span className="text-xs text-gray-400 font-mono">
              {address?.slice(0, 6)}...{address?.slice(-4)}
            </span>
            <Button variant="secondary" onClick={() => disconnect()}>
              Disconnect
            </Button>
          </div>
        ) : (
          <Button onClick={() => connect({ connector: injected() })}>
            Connect Wallet
          </Button>
        )}
      </div>
    </header>
  );
}
