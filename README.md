# Bounds

Bounds is a DePIN settlement protocol that uses Attestcoin-verified sensor data to settle cold-chain shipments on Creditcoin.

**Physical conditions. Enforceable consequences.**

## The problem

Cold-chain monitoring systems can report when cargo exceeds its permitted temperature range, but payments, penalties, and disputes still depend on fragmented records and trusted intermediaries.

This creates costly delays for pharmaceutical distributors, food exporters, logistics providers, insurers, and healthcare procurement teams.

## The solution

Bounds connects device-originated telemetry with programmable cross-chain settlement:

1. An authorized sensor records shipment temperatures.
2. The sensor commits a tamper-evident telemetry summary on Ethereum Sepolia.
3. Attestcoin verifies the source-chain telemetry on Creditcoin.
4. Bounds evaluates the verified conditions.
5. Payment is released for a compliant shipment or penalized after a breach.

## Architecture

```text
Sensor simulator
      |
      | commits telemetry
      v
BoundsTelemetry
Ethereum Sepolia
      |
      | verified cross-chain state
      v
Attestcoin Protocol
      |
      | authenticated result
      v
BoundsSettlement
Creditcoin Testnet
      |
      v
Release or penalty
````

## Current implementation

PR 1 established the application, wallet, contract-development, testing, and CI foundation.

PR 2 implements the source-chain telemetry layer:

* Authorized sensor registry
* Sensor authorization and revocation
* Shipment-specific telemetry records
* Tamper-evident telemetry hashes
* Safe and breach sensor simulations
* Shipment nonce tracking
* Ethereum Sepolia deployment
* Real safe and breached telemetry transactions
* 13 passing Foundry tests

The Attestcoin verification and Creditcoin settlement contracts are introduced in PR 3.

## Ethereum Sepolia deployment

| Component              | Address                                                                                                                         |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| BoundsTelemetry        | [`0x4b403e46800A485fdE2a0be2228228f78f20C7D4`](https://sepolia.etherscan.io/address/0x4b403e46800A485fdE2a0be2228228f78f20C7D4) |
| Authorized test sensor | [`0xB51A5de45176aE2bC606d837fb9Dd3aeD5647101`](https://sepolia.etherscan.io/address/0xB51A5de45176aE2bC606d837fb9Dd3aeD5647101) |

### Verified telemetry transactions

| Scenario | Shipment         | Result                                  | Transaction                                                                                                           |
| -------- | ---------------- | --------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| Safe     | `BND-001`        | 4.0°C–4.5°C, 0 seconds outside range    | [`0x88b3...d3c`](https://sepolia.etherscan.io/tx/0x88b3be315db41b61d5369693691f395d11765149f205ee5119ac120286263d3c)  |
| Breach   | `BND-BREACH-001` | 4.2°C–10.1°C, 120 seconds outside range | [`0x6cf7...6fa3`](https://sepolia.etherscan.io/tx/0x6cf74d0a14391598734aaf07b79801d02a4d9d06386ca0cd152a45216e2c6fa3) |

## Telemetry contract

`BoundsTelemetry.sol` is the source-chain record used by Bounds.

Each committed record contains:

* Shipment identifier
* Authorized sensor address
* Shipment nonce
* Minimum recorded temperature
* Maximum recorded temperature
* Time outside the permitted range
* Sensor recording timestamp
* Hash of the underlying telemetry payload

Temperatures are stored in centi-degrees Celsius. For example, `420` represents `4.20°C`.

Only an address authorized by the contract owner can submit telemetry. Raw readings remain offchain while their deterministic hash and settlement-relevant summary are committed onchain.

## Sensor simulator

The simulator produces deterministic cold-chain scenarios without requiring physical hardware.

Run a safe dry run:

```bash
pnpm sensor:safe
```

Run a breach dry run:

```bash
pnpm sensor:breach
```

Submit the safe scenario to Ethereum Sepolia:

```bash
pnpm exec tsx scripts/simulate-telemetry.ts safe --submit
```

Submit a breached shipment with a separate reference:

```bash
SHIPMENT_REFERENCE=BND-BREACH-001 pnpm exec tsx scripts/simulate-telemetry.ts breach --submit
```

Dry runs require no wallet or RPC configuration.

## Stack

* Next.js 16
* React 19
* TypeScript
* Tailwind CSS
* wagmi
* viem
* Solidity
* Foundry
* Ethereum Sepolia
* Creditcoin Testnet
* Attestcoin Protocol

## Local development

Install dependencies:

```bash
pnpm install
```

Install the Foundry test library if it is not already present:

```bash
forge install foundry-rs/forge-std --root contracts --no-git
```

Create the local environment file:

```bash
cp .env.example .env
```

Start the application:

```bash
pnpm dev
```

## Environment variables

```dotenv
NEXT_PUBLIC_SEPOLIA_RPC_URL=
ETHEREUM_SEPOLIA_RPC_URL=
DEPLOYER_PRIVATE_KEY=
SENSOR_PRIVATE_KEY=
SENSOR_ADDRESS=
TELEMETRY_CONTRACT_ADDRESS=
SHIPMENT_REFERENCE=BND-001
```

Never commit private keys or populated environment files. Use disposable testnet-only wallets.

## Contracts

Format contracts:

```bash
forge fmt --root contracts
```

Build contracts:

```bash
forge build --root contracts
```

Run the test suite:

```bash
pnpm contracts:test
```

Deploy and authorize the configured sensor:

```bash
forge script contracts/script/DeployBoundsTelemetry.s.sol:DeployBoundsTelemetry \
  --root contracts \
  --rpc-url "$ETHEREUM_SEPOLIA_RPC_URL" \
  --broadcast \
  -vv
```

## Frontend checks

```bash
pnpm lint
pnpm build
```

## Repository structure

```text
contracts/
  script/       Foundry deployment scripts
  src/          Solidity contracts
  test/         Foundry tests
scripts/        Sensor telemetry simulator
src/app/        Next.js application
src/components/ Shared frontend providers
src/config/     Chain and wallet configuration
src/lib/        Application constants
src/types/      Bounds domain types
```

## Security scope

Bounds is currently a hackathon testnet prototype and has not been audited.

The telemetry contract proves that an authorized sensor address committed a specific data summary. Physical sensor integrity, hardware identity, calibration, and secure raw-data storage remain outside the current prototype’s trust boundary.

## Developer resources

* [Attestcoin Protocol](https://attestcoin.org/)
* [Developer documentation](https://docs.attestcoin.org/)
* [Chains and environments](https://docs.attestcoin.org/attestcoin-protocol/attestcoin-protocol-chains-environments)
* [Guided tutorials](https://docs.attestcoin.org/attestcoin-protocol/guided-tutorials)
* [Attestcoin SDK](https://docs.attestcoin.org/attestcoin-protocol/dapp-builder-infrastructure/attestcoin-sdk-usc-sdk)
