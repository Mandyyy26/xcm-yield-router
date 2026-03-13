// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {HelloHub} from "../src/HelloHub.sol";

contract Deploy is Script {
    function run() public {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        HelloHub hello = new HelloHub("Hello, World!");
        vm.stopBroadcast();

        console.log("HelloHub deployed at:", address(hello));
        console.log("Deployer:", vm.addr(deployerKey));
        console.log("Chain ID:", block.chainid);
    }
}