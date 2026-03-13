// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {YieldOracle} from "../src/YieldOracle.sol";
import {StrategyManager} from "../src/StrategyManager.sol";
import {XCMDispatcher} from "../src/XCMDispatcher.sol";
import {HubVault} from "../src/HubVault.sol";
import {MockToken} from "../test/mocks/MockToken.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer    = vm.addr(deployerKey);

        vm.startBroadcast(deployerKey);

        // 1. Deploy MockToken (test asset)
        MockToken token = new MockToken();
        console.log("MockToken deployed at:", address(token));

        // 2. Deploy YieldOracle
        YieldOracle oracle = new YieldOracle(deployer);
        console.log("YieldOracle deployed at:", address(oracle));

        // 3. Deploy StrategyManager
        StrategyManager strategyManager = new StrategyManager(deployer, address(oracle));
        console.log("StrategyManager deployed at:", address(strategyManager));

        // 4. Deploy XCMDispatcher (vault address = address(0) for now, update after)
        XCMDispatcher dispatcher = new XCMDispatcher(deployer, address(0));
        console.log("XCMDispatcher deployed at:", address(dispatcher));

        // 5. Deploy HubVault
        HubVault vault = new HubVault(
            address(token),
            address(strategyManager),
            address(dispatcher),
            deployer
        );
        console.log("HubVault deployed at:", address(vault));

        // 6. Wire dispatcher → vault
        dispatcher.setVault(address(vault));
        console.log("Dispatcher wired to vault");

        // 7. Register 2 strategies
        strategyManager.registerStrategy(0, 1000, makeAddr("stratA"), 500);
        strategyManager.registerStrategy(1, 2000, makeAddr("stratB"), 800);
        console.log("Strategies registered");

        // 8. Set initial oracle yields
        oracle.updateYield(0, 500);  // Strategy 0: 5% APY
        oracle.updateYield(1, 800);  // Strategy 1: 8% APY
        console.log("Oracle yields set");

        // 9. Mint test tokens to deployer
        token.mint(deployer, 10_000 ether);
        console.log("Minted 10,000 test tokens to deployer");

        vm.stopBroadcast();

        console.log("---");
        console.log("Chain ID:", block.chainid);
        console.log("Deployer:", deployer);
    }

    function makeAddr(string memory name) internal pure override returns (address) {
        return address(uint160(uint256(keccak256(bytes(name)))));
    }
}
