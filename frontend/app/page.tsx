import { Header }          from "@/components/Header";
import { VaultStatus }     from "@/components/panels/VaultStatus";
import { DepositWithdraw } from "@/components/panels/DepositWithdraw";
import { XCMActivityLog }  from "@/components/panels/XCMActivityLog";
import { YieldScoreboard } from "@/components/panels/YieldScoreboard";
import { AdminPanel }      from "@/components/panels/AdminPanel";

export default function Home() {
  return (
    <div className="min-h-screen bg-gray-950">
      <Header />

      <main className="max-w-7xl mx-auto px-6 py-8">
        {/* Hero */}
        <div className="mb-8">
          <h2 className="text-2xl font-bold text-white mb-1">
            Cross-Chain Yield Optimizer
          </h2>
          <p className="text-gray-400 text-sm">
            Deposit once · Vault routes funds to highest yield via XCM ·
            Polkadot Hub PVM track
          </p>
        </div>

        {/* Main Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">

          {/* Left column */}
          <div className="space-y-5">
            <VaultStatus />
            <YieldScoreboard />
          </div>

          {/* Center column */}
          <div className="space-y-5">
            <DepositWithdraw />
            <AdminPanel />
          </div>

          {/* Right column — XCM Activity (full height, most important for demo) */}
          <div className="lg:row-span-2">
            <XCMActivityLog />
          </div>

        </div>
      </main>
    </div>
  );
}
