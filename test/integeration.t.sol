// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {HubVault} from "../src/HubVault.sol";
import {YieldOracle} from "../src/YieldOracle.sol";
import {StrategyManager} from "../src/StrategyManager.sol";
import {XCMDispatcher} from "../src/XCMDispatcher.sol";
import {MockToken} from "./mocks/MockToken.sol";

/// @notice Mock XCM precompile for local testing
contract MockXcmPrecompile {
    event Executed(bytes message, uint64 refTime, uint64 proofSize);
    event Sent(bytes destination, bytes message);

    function weighMessage(bytes calldata)
        external pure returns (uint64 refTime, uint64 proofSize)
    {
        return (979_880_000, 10_943); // real values from Milestone 3
    }

    function execute(bytes calldata message, uint64 refTime, uint64 proofSize) external {
        emit Executed(message, refTime, proofSize);
    }

    function send(bytes calldata destination, bytes calldata message) external {
        emit Sent(destination, message);
    }
}

contract IntegrationTest is Test {

    MockToken       token;
    YieldOracle     oracle;
    StrategyManager strategyManager;
    XCMDispatcher   dispatcher;
    HubVault        vault;

    address owner = address(this);
    address alice = makeAddr("alice");

    function setUp() public {
        token           = new MockToken();
        oracle          = new YieldOracle(owner);
        strategyManager = new StrategyManager(owner, address(oracle));
        dispatcher      = new XCMDispatcher(owner, address(0));
        vault           = new HubVault(
            address(token),
            address(strategyManager),
            address(dispatcher),
            owner
        );

        // Wire dispatcher → vault
        dispatcher.setVault(address(vault));

        // Register strategies
        strategyManager.registerStrategy(0, 1000, makeAddr("stratA"), 500);
        strategyManager.registerStrategy(1, 2000, makeAddr("stratB"), 800);

        // Set oracle yields
        oracle.updateYield(0, 500);
        oracle.updateYield(1, 800);

        // Set cooldown to 0 for testing
        dispatcher.setCooldown(0);

        // Fund alice
        token.mint(alice, 1000 ether);
        vm.prank(alice);
        token.approve(address(vault), type(uint256).max);
    }

    function test_fullFlow_depositAndWithdraw() public {
        // 1. Alice deposits
        vm.prank(alice);
        vault.deposit(100 ether);

        assertEq(vault.balanceOf(alice), 100 ether);
        assertEq(vault.totalAssets(), 100 ether);
        console.log("Alice deposited 100 tokens, shares:", vault.balanceOf(alice));

        // 2. Alice withdraws
        vm.prank(alice);
        vault.withdraw(100 ether);

        assertEq(vault.balanceOf(alice), 0);
        assertEq(token.balanceOf(alice), 1000 ether);
        console.log("Alice withdrew successfully");
    }

    function test_fullFlow_vaultStateTransitions() public {
        vm.prank(alice);
        vault.deposit(100 ether);

        // Initial state = Idle
        assertEq(uint8(vault.vaultState()), 0);

        // Vault is Idle with funds — ready to rebalance
        console.log("Vault state (Idle=0):", uint8(vault.vaultState()));
    }

    function test_dispatcherWeightConfig() public view {
        (uint64 refTime, uint64 proofSize) = (
            dispatcher.maxRefTime(),
            dispatcher.maxProofSize()
        );
        assertEq(refTime,   1_500_000_000);
        assertEq(proofSize, 20_000);
        console.log("Max refTime:", refTime);
        console.log("Max proofSize:", proofSize);
    }
}
