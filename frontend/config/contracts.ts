// ── Paste your deployed addresses here ──────────────────
export const CONTRACT_ADDRESSES = {
    hubVault:        "0x305C5085610EaeeC2AD66Ad32c46967786aA4e1A", 
    mockToken:       "0x4E8B88C443e2F60F869bd0b8321C716422711e3a",
    yieldOracle:     "0x3866060EcB76CcDd48b9DE79f4711cC7f0326bF8",
    strategyManager: "0x373D7ad973B2942BF4E6feb460F400155cE8883F",
    xcmDispatcher:   "0x0737c24991D283990477F6Ea20Df7bBfffEb9CAc",
  } as const;
  
  // ── ABIs (minimal — only functions we call) ──────────────
  
  export const VAULT_ABI = [
    // Read
    { name: "totalAssets",     type: "function", stateMutability: "view",       inputs: [],                                          outputs: [{ type: "uint256" }] },
    { name: "totalSupply",     type: "function", stateMutability: "view",       inputs: [],                                          outputs: [{ type: "uint256" }] },
    { name: "balanceOf",       type: "function", stateMutability: "view",       inputs: [{ name: "account", type: "address" }],      outputs: [{ type: "uint256" }] },
    { name: "vaultState",      type: "function", stateMutability: "view",       inputs: [],                                          outputs: [{ type: "uint8"   }] },
    { name: "activeStrategyId",type: "function", stateMutability: "view",       inputs: [],                                          outputs: [{ type: "uint8"   }] },
    { name: "convertToAssets", type: "function", stateMutability: "view",       inputs: [{ name: "shares", type: "uint256" }],       outputs: [{ type: "uint256" }] },
    { name: "rebalanceNonce",  type: "function", stateMutability: "view",       inputs: [],                                          outputs: [{ type: "uint256" }] },
    // Write
    { name: "deposit",         type: "function", stateMutability: "nonpayable", inputs: [{ name: "amount", type: "uint256" }],       outputs: [] },
    { name: "withdraw",        type: "function", stateMutability: "nonpayable", inputs: [{ name: "shares", type: "uint256" }],       outputs: [] },
    { name: "rebalance",       type: "function", stateMutability: "nonpayable", inputs: [],                                          outputs: [] },
    { name: "emergencyPause",  type: "function", stateMutability: "nonpayable", inputs: [],                                          outputs: [] },
    { name: "emergencyReset",  type: "function", stateMutability: "nonpayable", inputs: [],                                          outputs: [] },
    // Events
    { name: "Deposited",       type: "event",    inputs: [{ name: "user",   type: "address", indexed: true }, { name: "amount", type: "uint256" }, { name: "sharesIssued", type: "uint256" }] },
    { name: "Withdrawn",       type: "event",    inputs: [{ name: "user",   type: "address", indexed: true }, { name: "shares", type: "uint256" }, { name: "amountReturned", type: "uint256" }] },
    { name: "Rebalanced",      type: "event",    inputs: [{ name: "oldStrategyId", type: "uint8", indexed: true }, { name: "newStrategyId", type: "uint8", indexed: true }, { name: "amount", type: "uint256" }] },
  ] as const;
  
  export const TOKEN_ABI = [
    { name: "balanceOf", type: "function", stateMutability: "view",       inputs: [{ name: "account", type: "address" }],                               outputs: [{ type: "uint256" }] },
    { name: "allowance", type: "function", stateMutability: "view",       inputs: [{ name: "owner", type: "address" }, { name: "spender", type: "address" }], outputs: [{ type: "uint256" }] },
    { name: "approve",   type: "function", stateMutability: "nonpayable", inputs: [{ name: "spender", type: "address" }, { name: "amount", type: "uint256" }], outputs: [{ type: "bool"    }] },
    { name: "decimals",  type: "function", stateMutability: "view",       inputs: [],                                                                    outputs: [{ type: "uint8"   }] },
  ] as const;
  
  export const ORACLE_ABI = [
    { name: "getYield",    type: "function", stateMutability: "view",       inputs: [{ name: "strategyId", type: "uint8" }],                                    outputs: [{ type: "uint256" }] },
    { name: "isStale",     type: "function", stateMutability: "view",       inputs: [{ name: "strategyId", type: "uint8" }],                                    outputs: [{ type: "bool"    }] },
    { name: "lastUpdated", type: "function", stateMutability: "view",       inputs: [{ name: "strategyId", type: "uint8" }],                                    outputs: [{ type: "uint256" }] },
    { name: "updateYield", type: "function", stateMutability: "nonpayable", inputs: [{ name: "strategyId", type: "uint8" }, { name: "newYield", type: "uint256" }], outputs: [] },
  ] as const;
  
  export const DISPATCHER_ABI = [
    { name: "maxRefTime",         type: "function", stateMutability: "view", inputs: [], outputs: [{ type: "uint64" }] },
    { name: "maxProofSize",       type: "function", stateMutability: "view", inputs: [], outputs: [{ type: "uint64" }] },
    { name: "lastDispatchTime",   type: "function", stateMutability: "view", inputs: [], outputs: [{ type: "uint256" }] },
    { name: "nextDispatchAllowed",type: "function", stateMutability: "view", inputs: [], outputs: [{ type: "uint256" }] },
    { name: "lastDispatch",       type: "function", stateMutability: "view", inputs: [{ name: "parachainId", type: "uint32" }], outputs: [{ components: [{ name: "success", type: "bool" }, { name: "refTime", type: "uint64" }, { name: "proofSize", type: "uint64" }, { name: "messageId", type: "bytes32" }], type: "tuple" }] },
    // Event
    { name: "XCMDispatched", type: "event", inputs: [
      { name: "parachainId", type: "uint32",  indexed: true  },
      { name: "recipient",   type: "address", indexed: true  },
      { name: "amount",      type: "uint256", indexed: false },
      { name: "refTime",     type: "uint64",  indexed: false },
      { name: "proofSize",   type: "uint64",  indexed: false },
      { name: "timestamp",   type: "uint256", indexed: false },
    ]},
    { name: "WeightQueried", type: "event", inputs: [
      { name: "parachainId", type: "uint32", indexed: true  },
      { name: "refTime",     type: "uint64", indexed: false },
      { name: "proofSize",   type: "uint64", indexed: false },
    ]},
  ] as const;
  