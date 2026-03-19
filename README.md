# XCM Yield Router 🔀

> Cross-chain yield optimizer built on Polkadot Hub (PVM track)  
> Deposit once. Vault routes funds to highest-yield parachain via XCM automatically.

## Live Contracts (Polkadot Hub TestNet)

| Contract        | Address                                      |
| --------------- | -------------------------------------------- |
| HubVault        | `0x305C5085610EaeeC2AD66Ad32c46967786aA4e1A` |
| XCMDispatcher   | `0x0737c24991D283990477F6Ea20Df7bBfffEb9CAc` |
| StrategyManager | `0x373D7ad973B2942BF4E6feb460F400155cE8883F` |
| MockToken (MTK) | `0x4E8B88C443e2F60F869bd0b8321C716422711e3a` |

## How It Works

1. User deposits MTK tokens into HubVault
2. StrategyManager tracks APY across parachains via oracle
3. When Para B APY > Para A APY, keeper calls `rebalance()`
4. HubVault → XCMDispatcher → XCM Precompile (`0xA0000`)
5. `weighMessage()` estimates gas cost → `execute()` dispatches cross-chain

## XCM Precompile Integration

The core innovation: Solidity contract calling Polkadot's native XCM precompile.

```solidity
// weighMessage() → get cost estimate
IXcm.Weight memory weight = XCM.weighMessage(message);

// execute() → dispatch cross-chain transfer
XCM.execute(message, weight);
```

## Verified XCM Weights (Polkadot Hub TestNet)

| Metric      | Value       |
| ----------- | ----------- |
| `refTime`   | 979,880,000 |
| `proofSize` | 10,943      |

---

## Run Locally

```bash
git clone <your-repo>
cd xcm-yield-router
npm install

# Copy and fill environment variables
cp .env.example .env
# Add your PRIVATE_KEY and RPC_URL to .env

# Deploy contracts
forge run scripts/deploy.ts --network polkadotHubTestnet

# Start frontend
cd frontend
npm install
npm run dev
```

## Tech Stack

| Layer           | Technology                                   |
| --------------- | -------------------------------------------- |
| Smart Contracts | Solidity ^0.8.28 + OpenZeppelin              |
| XCM Integration | Polkadot XCM Precompile at `0xA0000`         |
| Deployment      | Foundry                                      |
| Frontend        | React + Viem + Wagmi                         |
| Network         | Polkadot Hub TestNet (Chain ID: `420420417`) |
