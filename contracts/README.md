# Bounds Contracts

Bounds uses two contracts across two testnets to convert cold-chain telemetry into Attestcoin-verified settlement.

## Contracts

### `BoundsTelemetry.sol`

Deployed on Ethereum Sepolia.

- Maintains an authorized sensor allowlist.
- Commits temperature extrema, out-of-range duration, timestamp, and a telemetry hash.
- Emits `TelemetryCommitted`, which becomes the source event proved through Attestcoin.
- Tracks a per-shipment nonce to distinguish successive readings.

### `BoundsSettlement.sol`

Deployed on Creditcoin Testnet.

- Escrows native tCTC against a shipment.
- Accepts only Ethereum Sepolia proofs using Attestcoin chain key `1`.
- Calls Creditcoin’s native query verifier at `0x0000000000000000000000000000000000000FD2`.
- Decodes the verified EVM transaction and receipt using the official Gluwa contracts package.
- Requires a successful transaction and an exact `TelemetryCommitted` event from the registered source contract.
- Releases full payment when telemetry remains within bounds.
- Applies the configured penalty when telemetry records a breach.
- Prevents proof replay and uses pull payments for withdrawals.

## Structure

```text
contracts/
├── script/
│   ├── DeployBoundsSettlement.s.sol
│   └── DeployBoundsTelemetry.s.sol
├── src/
│   ├── BoundsSettlement.sol
│   └── BoundsTelemetry.sol
└── test/
    ├── BoundsSettlement.t.sol
    └── BoundsTelemetry.t.sol
```

## Build

From the repository root:

```bash
forge build --root contracts
```

## Format

```bash
forge fmt --root contracts
```

## Test

```bash
forge test --root contracts -vv
```

The suite contains 21 tests:

- 13 telemetry and sensor-authorization tests.
- 8 escrow and Attestcoin settlement tests.

The settlement tests cover compliant payment, breach penalties, withdrawals, incorrect source chains, incorrect destination chains, forged event emitters, and proof replay.

## Deploy source telemetry

```bash
forge script contracts/script/DeployBoundsTelemetry.s.sol:DeployBoundsTelemetry \
  --root contracts \
  --rpc-url "$ETHEREUM_SEPOLIA_RPC_URL" \
  --broadcast \
  -vv
```

## Deploy settlement

The standard Foundry script is:

```bash
forge script contracts/script/DeployBoundsSettlement.s.sol:DeployBoundsSettlement \
  --root contracts \
  --rpc-url "$CREDITCOIN_RPC_URL" \
  --broadcast \
  -vv
```

Some Creditcoin RPC responses omit the `mixHash` field expected by current Foundry simulation. The live deployment was therefore broadcast as a legacy raw contract-creation transaction after compilation.

## Live addresses

| Network | Contract | Address |
| --- | --- | --- |
| Ethereum Sepolia | `BoundsTelemetry` | `0x4b403e46800A485fdE2a0be2228228f78f20C7D4` |
| Creditcoin Testnet | `BoundsSettlement` | `0x4b403e46800A485fdE2a0be2228228f78f20C7D4` |

The identical addresses are expected: the same deployer used the same creation nonce on separate chains.

Full transaction hashes and verified settlement records are stored under `deployments/`.