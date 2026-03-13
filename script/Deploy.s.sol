// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {XCMProbe} from "../src/XCMProbe.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        XCMProbe probe = new XCMProbe();

        vm.stopBroadcast();

        console.log("XCMProbe deployed at:", address(probe));
        console.log("XCM Precompile address:", probe.getPrecompileAddress());
        console.log("Chain ID:", block.chainid);
    }
}
