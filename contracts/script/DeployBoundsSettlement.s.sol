// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {BoundsSettlement} from "../src/BoundsSettlement.sol";

contract DeployBoundsSettlement is Script {
    function run() external returns (BoundsSettlement settlement) {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address sourceTelemetryContract = vm.envAddress("TELEMETRY_CONTRACT_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);
        settlement = new BoundsSettlement(sourceTelemetryContract);
        vm.stopBroadcast();
    }
}
