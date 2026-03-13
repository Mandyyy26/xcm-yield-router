// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {HubVault} from "../src/HubVault.sol";
import {YieldOracle} from "../src/YieldOracle.sol";
import {StrategyManager} from "../src/StrategyManager.sol";

/// @dev Simple mock ERC20 for testing
contract MockToken is ERC20 {
    constructor() ERC20("Mock Token", "MTK") {}
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

/// @dev Minimal mock XCMDispatcher — just approves and emits
contract MockXCMDispatcher {
    event MockDispatched(uint32 parachainId, address recipient, uint256 amount);

    function sendToParachain(uint32 parachainId, address recipient, uint256 amount)
        external
        returns (bool)
    {
        emit MockDispatched(parachainId, recipient, amount);
        return true;
    }
}

contract HubVaultTest is Test {

    MockToken          token;
    YieldOracle        oracle;
    StrategyManager    strategyManager;
    MockXCMDispatcher  dispatcher;
    HubVault           vault;

    address owner = address(this);
    address alice = makeAddr("alice");
    address bob   = makeAddr("bob");

    function setUp() public {
        // Deploy dependencies
        token      = new MockToken();
        oracle     = new YieldOracle(owner);
        dispatcher = new MockXCMDispatcher();
        strategyManager = new StrategyManager(owner, address(oracle));

        // Deploy vault
        vault = new HubVault(
            address(token),
            address(strategyManager),
            address(dispatcher),
            owner
        );

        // Register 2 strategies
        strategyManager.registerStrategy(0, 1000, makeAddr("stratA"), 500); // 5% APY
        strategyManager.registerStrategy(1, 2000, makeAddr("stratB"), 800); // 8% APY

        // Fund alice and bob
        token.mint(alice, 1000 ether);
        token.mint(bob,   1000 ether);

        // Approvals
        vm.prank(alice);
        token.approve(address(vault), type(uint256).max);
        vm.prank(bob);
        token.approve(address(vault), type(uint256).max);
    }

    // ── Deposit Tests ──────────────────────────────────────────

    function test_deposit_mintsShares() public {
        vm.prank(alice);
        vault.deposit(100 ether);

        assertEq(vault.balanceOf(alice), 100 ether);
        assertEq(vault.totalAssets(), 100 ether);
        assertEq(token.balanceOf(address(vault)), 100 ether);
    }

    function test_deposit_secondUser_correctShares() public {
        vm.prank(alice);
        vault.deposit(100 ether);

        vm.prank(bob);
        vault.deposit(100 ether);

        // Both should have equal shares since equal deposit
        assertEq(vault.balanceOf(alice), vault.balanceOf(bob));
        assertEq(vault.totalAssets(), 200 ether);
    }

    function test_deposit_revertsOnZero() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSignature("ZeroAmount()"));
        vault.deposit(0);
    }

    function test_deposit_revertsWhenPaused() public {
        vault.emergencyPause();
        vm.prank(alice);
        vm.expectRevert();
        vault.deposit(100 ether);
    }

    // ── Withdraw Tests ─────────────────────────────────────────

    function test_withdraw_returnsCorrectAssets() public {
        vm.prank(alice);
        vault.deposit(100 ether);

        uint256 shares = vault.balanceOf(alice);

        vm.prank(alice);
        vault.withdraw(shares);

        assertEq(vault.balanceOf(alice), 0);
        assertEq(token.balanceOf(alice), 1000 ether); // full amount back
    }

    function test_withdraw_revertsOnZero() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSignature("ZeroAmount()"));
        vault.withdraw(0);
    }

    function test_withdraw_revertsOnInsufficientShares() public {
        vm.prank(alice);
        vault.deposit(100 ether);

        vm.prank(alice);
        vm.expectRevert();
        vault.withdraw(200 ether); // more than deposited
    }

    // ── Share Math Tests ───────────────────────────────────────

    function test_shareMath_firstDepositOneToOne() public {
        uint256 amount = 500 ether;
        vm.prank(alice);
        vault.deposit(amount);
        assertEq(vault.balanceOf(alice), amount); // 1:1 on first deposit
    }

    function test_shareMath_invariant_roundTrip(uint256 amount) public {
        vm.assume(amount > 0 && amount <= 1000 ether);
        vm.prank(alice);
        vault.deposit(amount);

        uint256 shares = vault.balanceOf(alice);
        uint256 assets = vault.convertToAssets(shares);

        // Should get back same amount (no yield in mock)
        assertEq(assets, amount);
    }

    // ── Oracle Tests ───────────────────────────────────────────

    function test_oracle_updateYield() public {
        oracle.updateYield(0, 600); // update strategy 0 to 6%
        assertEq(oracle.getYield(0), 600);
    }

    function test_oracle_revertsOnExcessiveDelta() public {
        oracle.updateYield(0, 500);
        vm.expectRevert();
        oracle.updateYield(0, 1500); // delta = 1000 > maxDelta 500
    }

    function test_oracle_revertsWhenStale() public {
        oracle.updateYield(0, 500);
        // Fast forward 2 days
        vm.warp(block.timestamp + 2 days);
        vm.expectRevert();
        oracle.getYield(0);
    }

    // ── Strategy Tests ─────────────────────────────────────────

    function test_strategy_getBestStrategy() public {
        oracle.updateYield(0, 500);
        oracle.updateYield(1, 800);
        uint8 best = strategyManager.getBestStrategy();
        assertEq(best, 1); // strategy 1 has higher APY
    }

    function test_strategy_getBestAfterUpdate() public {
        oracle.updateYield(0, 500);
        oracle.updateYield(1, 800);

        // Now update strategy 0 to be better
        oracle.updateYield(0, 900); // 9% > 8%
        uint8 best = strategyManager.getBestStrategy();
        assertEq(best, 0);
    }

    // ── Emergency Tests ────────────────────────────────────────

    function test_emergencyPause_blocksDeposit() public {
        vault.emergencyPause();
        vm.prank(alice);
        vm.expectRevert();
        vault.deposit(100 ether);
    }

    function test_emergencyReset_setsIdle() public {
        vault.emergencyPause();
        vault.unpause();
        vault.emergencyReset();
        // Should be back to Idle
        assertEq(uint8(vault.vaultState()), uint8(0)); // 0 = Idle
    }
}
