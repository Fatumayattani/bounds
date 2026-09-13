// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title BoundsTelemetry
/// @notice Records device-originated cold-chain telemetry on a source chain.
/// @dev The submitTelemetry calldata is designed to be proven and decoded on
///      Creditcoin through the Attestcoin Protocol.
contract BoundsTelemetry {
    error Unauthorized();
    error ZeroAddress();
    error SensorAlreadyAuthorized();
    error SensorNotAuthorized();
    error InvalidShipmentId();
    error InvalidTelemetryHash();
    error InvalidTemperatureRange();
    error InvalidTimestamp();

    struct TelemetryRecord {
        address sensor;
        int16 minimumTemperature;
        int16 maximumTemperature;
        uint32 outOfRangeSeconds;
        uint64 recordedAt;
        uint64 nonce;
        bytes32 telemetryHash;
    }

    address public immutable owner;

    mapping(address sensor => bool authorized) public authorizedSensors;
    mapping(bytes32 shipmentId => uint64 nonce) public shipmentNonces;
    mapping(bytes32 shipmentId => TelemetryRecord record) public latestTelemetry;

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

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    constructor(address initialOwner) {
        if (initialOwner == address(0)) revert ZeroAddress();
        owner = initialOwner;
    }

    function authorizeSensor(address sensor) external onlyOwner {
        if (sensor == address(0)) revert ZeroAddress();
        if (authorizedSensors[sensor]) revert SensorAlreadyAuthorized();

        authorizedSensors[sensor] = true;

        emit SensorAuthorizationUpdated(sensor, true);
    }

    function revokeSensor(address sensor) external onlyOwner {
        if (!authorizedSensors[sensor]) revert SensorNotAuthorized();

        authorizedSensors[sensor] = false;

        emit SensorAuthorizationUpdated(sensor, false);
    }

    function submitTelemetry(
        bytes32 shipmentId,
        int16 minimumTemperature,
        int16 maximumTemperature,
        uint32 outOfRangeSeconds,
        uint64 recordedAt,
        bytes32 telemetryHash
    ) external returns (uint64 nonce) {
        if (!authorizedSensors[msg.sender]) revert SensorNotAuthorized();
        if (shipmentId == bytes32(0)) revert InvalidShipmentId();
        if (telemetryHash == bytes32(0)) revert InvalidTelemetryHash();

        if (minimumTemperature > maximumTemperature) {
            revert InvalidTemperatureRange();
        }

        if (recordedAt == 0) {
            revert InvalidTimestamp();
        }

        nonce = shipmentNonces[shipmentId] + 1;
        shipmentNonces[shipmentId] = nonce;

        latestTelemetry[shipmentId] = TelemetryRecord({
            sensor: msg.sender,
            minimumTemperature: minimumTemperature,
            maximumTemperature: maximumTemperature,
            outOfRangeSeconds: outOfRangeSeconds,
            recordedAt: recordedAt,
            nonce: nonce,
            telemetryHash: telemetryHash
        });

        emit TelemetryCommitted(
            shipmentId,
            msg.sender,
            nonce,
            minimumTemperature,
            maximumTemperature,
            outOfRangeSeconds,
            recordedAt,
            telemetryHash
        );
    }
}
