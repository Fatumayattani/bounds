// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";

import {BoundsTelemetry} from "../src/BoundsTelemetry.sol";

contract BoundsTelemetryTest is Test {
    BoundsTelemetry internal telemetry;

    address internal sensor;
    address internal stranger;

    bytes32 internal constant SHIPMENT_ID = keccak256("BND-001");
    bytes32 internal constant TELEMETRY_HASH = keccak256("bounds-readings");

    event SensorAuthorizationUpdated(address indexed sensor, bool authorized);

    event TelemetryCommitted(
        bytes32 indexed shipmentId,
        address indexed sensor,
        uint64 indexed nonce,
        int16 minimumTemperature,
        int16 maximumTemperature,
        uint32 outOfRangeSeconds,
        uint64 recordedAt,
        bytes32 telemetryHash
    );

    function setUp() public {
        sensor = makeAddr("sensor");
        stranger = makeAddr("stranger");
        telemetry = new BoundsTelemetry(address(this));
    }

    function testOwnerIsConfigured() public view {
        assertEq(telemetry.owner(), address(this));
    }

    function testOwnerCanAuthorizeSensor() public {
        vm.expectEmit(true, false, false, true);
        emit SensorAuthorizationUpdated(sensor, true);

        telemetry.authorizeSensor(sensor);

        assertTrue(telemetry.authorizedSensors(sensor));
    }

    function testNonOwnerCannotAuthorizeSensor() public {
        vm.prank(stranger);
        vm.expectRevert(BoundsTelemetry.Unauthorized.selector);

        telemetry.authorizeSensor(sensor);
    }

    function testCannotAuthorizeZeroAddress() public {
        vm.expectRevert(BoundsTelemetry.ZeroAddress.selector);

        telemetry.authorizeSensor(address(0));
    }

    function testCannotAuthorizeSensorTwice() public {
        telemetry.authorizeSensor(sensor);

        vm.expectRevert(BoundsTelemetry.SensorAlreadyAuthorized.selector);
        telemetry.authorizeSensor(sensor);
    }

    function testOwnerCanRevokeSensor() public {
        telemetry.authorizeSensor(sensor);

        vm.expectEmit(true, false, false, true);
        emit SensorAuthorizationUpdated(sensor, false);

        telemetry.revokeSensor(sensor);

        assertFalse(telemetry.authorizedSensors(sensor));
    }

    function testUnauthorizedSensorCannotSubmitTelemetry() public {
        vm.prank(sensor);
        vm.expectRevert(BoundsTelemetry.SensorNotAuthorized.selector);

        telemetry.submitTelemetry(SHIPMENT_ID, 380, 510, 0, 1_725_000_000, TELEMETRY_HASH);
    }

    function testRejectsInvalidShipmentId() public {
        telemetry.authorizeSensor(sensor);

        vm.prank(sensor);
        vm.expectRevert(BoundsTelemetry.InvalidShipmentId.selector);

        telemetry.submitTelemetry(bytes32(0), 380, 510, 0, 1_725_000_000, TELEMETRY_HASH);
    }

    function testRejectsInvalidTelemetryHash() public {
        telemetry.authorizeSensor(sensor);

        vm.prank(sensor);
        vm.expectRevert(BoundsTelemetry.InvalidTelemetryHash.selector);

        telemetry.submitTelemetry(SHIPMENT_ID, 380, 510, 0, 1_725_000_000, bytes32(0));
    }

    function testRejectsInvertedTemperatureRange() public {
        telemetry.authorizeSensor(sensor);

        vm.prank(sensor);
        vm.expectRevert(BoundsTelemetry.InvalidTemperatureRange.selector);

        telemetry.submitTelemetry(SHIPMENT_ID, 510, 380, 0, 1_725_000_000, TELEMETRY_HASH);
    }

    function testRejectsZeroTimestamp() public {
        telemetry.authorizeSensor(sensor);

        vm.prank(sensor);
        vm.expectRevert(BoundsTelemetry.InvalidTimestamp.selector);

        telemetry.submitTelemetry(SHIPMENT_ID, 380, 510, 0, 0, TELEMETRY_HASH);
    }

    function testAuthorizedSensorCommitsTelemetry() public {
        telemetry.authorizeSensor(sensor);

        vm.expectEmit(true, true, true, true);
        emit TelemetryCommitted(SHIPMENT_ID, sensor, 1, 380, 510, 0, 1_725_000_000, TELEMETRY_HASH);

        vm.prank(sensor);
        uint64 nonce = telemetry.submitTelemetry(SHIPMENT_ID, 380, 510, 0, 1_725_000_000, TELEMETRY_HASH);

        assertEq(nonce, 1);
        assertEq(telemetry.shipmentNonces(SHIPMENT_ID), 1);

        (
            address storedSensor,
            int16 minimumTemperature,
            int16 maximumTemperature,
            uint32 outOfRangeSeconds,
            uint64 recordedAt,
            uint64 storedNonce,
            bytes32 storedHash
        ) = telemetry.latestTelemetry(SHIPMENT_ID);

        assertEq(storedSensor, sensor);
        assertEq(minimumTemperature, 380);
        assertEq(maximumTemperature, 510);
        assertEq(outOfRangeSeconds, 0);
        assertEq(recordedAt, 1_725_000_000);
        assertEq(storedNonce, 1);
        assertEq(storedHash, TELEMETRY_HASH);
    }

    function testShipmentNonceIncrements() public {
        telemetry.authorizeSensor(sensor);

        vm.startPrank(sensor);

        telemetry.submitTelemetry(SHIPMENT_ID, 380, 510, 0, 1_725_000_000, TELEMETRY_HASH);

        uint64 secondNonce =
            telemetry.submitTelemetry(SHIPMENT_ID, 370, 620, 120, 1_725_000_300, keccak256("second-reading-batch"));

        vm.stopPrank();

        assertEq(secondNonce, 2);
        assertEq(telemetry.shipmentNonces(SHIPMENT_ID), 2);
    }
}
