// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";

import {BoundsTelemetry} from "../src/BoundsTelemetry.sol";

contract DeployBoundsTelemetry is Script {
    function run() external returns (BoundsTelemetry telemetry) {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address sensor = vm.envAddress("SENSOR_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        telemetry = new BoundsTelemetry(deployer);
        telemetry.authorizeSensor(sensor);

        vm.stopBroadcast();
    }
}
