# Bounds contracts

This directory contains the smart contracts, deployment scripts, and tests for the Bounds cold-chain settlement protocol.

## Implemented contract

### BoundsTelemetry

`src/BoundsTelemetry.sol` records settlement-relevant shipment telemetry on Ethereum Sepolia.

The contract provides:

- Owner-controlled sensor authorization
- Sensor revocation
- Authorized telemetry submission
- Shipment-specific nonces
- Latest telemetry lookup
- Tamper-evident payload hashes
- Indexed events for cross-chain verification

### Telemetry record

Each record contains:

| Field | Solidity type | Meaning |
| --- | --- | --- |
| `sensor` | `address` | Authorized address that submitted the record |
| `minimumTemperature` | `int16` | Minimum temperature in centi-degrees Celsius |
| `maximumTemperature` | `int16` | Maximum temperature in centi-degrees Celsius |
| `outOfRangeSeconds` | `uint32` | Total time outside the permitted range |
| `recordedAt` | `uint64` | Sensor-provided Unix timestamp |
| `telemetryHash` | `bytes32` | Hash of the underlying telemetry payload |
| `nonce` | `uint64` | Shipment-specific submission sequence |

The contract validates authorization, nonzero identifiers and hashes, timestamp presence, and temperature-range consistency.

It intentionally does not claim that the blockchain can verify physical sensor calibration or the accuracy of the sensor clock.

## Ethereum Sepolia deployment

| Component | Address |
| --- | --- |
| BoundsTelemetry | [`0x4b403e46800A485fdE2a0be2228228f78f20C7D4`](https://sepolia.etherscan.io/address/0x4b403e46800A485fdE2a0be2228228f78f20C7D4) |
| Authorized sensor | [`0xB51A5de45176aE2bC606d837fb9Dd3aeD5647101`](https://sepolia.etherscan.io/address/0xB51A5de45176aE2bC606d837fb9Dd3aeD5647101) |

Deployment transaction:

[`0x25aac78a6e9e5d32e30d9fa0eabf649e2d626881c3216d90ca23cf330b40e7e5`](https://sepolia.etherscan.io/tx/0x25aac78a6e9e5d32e30d9fa0eabf649e2d626881c3216d90ca23cf330b40e7e5)

Sensor authorization transaction:

[`0x302f40188e52009177a31b8a618166d20f72c9a30b465612a08ba4cd7faa09f0`](https://sepolia.etherscan.io/tx/0x302f40188e52009177a31b8a618166d20f72c9a30b465612a08ba4cd7faa09f0)

## Test coverage

`test/BoundsTelemetry.t.sol` contains 13 tests covering:

- Owner configuration
- Sensor authorization and revocation
- Access control
- Invalid sensor addresses
- Duplicate authorization
- Invalid shipment identifiers
- Invalid telemetry hashes
- Invalid temperature ranges
- Missing timestamps
- Successful telemetry storage and events
- Shipment nonce increments

Run the tests from the repository root:

```bash
forge test --root contracts -vv
````

## Build

```bash
forge fmt --root contracts
forge build --root contracts
```

## Deployment

The deployment script reads configuration from environment variables, deploys `BoundsTelemetry`, and authorizes the configured sensor in the same broadcast sequence.

Required variables:

```dotenv
ETHEREUM_SEPOLIA_RPC_URL=
DEPLOYER_PRIVATE_KEY=
SENSOR_ADDRESS=
```

Load the local environment:

```bash
source .env
```

Deploy:

```bash
forge script contracts/script/DeployBoundsTelemetry.s.sol:DeployBoundsTelemetry \
  --root contracts \
  --rpc-url "$ETHEREUM_SEPOLIA_RPC_URL" \
  --broadcast \
  -vv
```

Never commit private keys or use a production wallet for testnet deployment.
