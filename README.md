# Bounds

Bounds is a DePIN settlement protocol that uses Attestcoin-verified sensor data to settle cold-chain shipments on Creditcoin.

**Physical conditions. Enforceable consequences.**

## The problem

Cold-chain monitoring systems can report when cargo exceeds its permitted temperature range, but payments, penalties, and disputes still depend on fragmented and trusted processes.

## The solution

Bounds connects device-originated telemetry with programmable settlement:

1. A registered sensor records shipment conditions.
2. The sensor commits its telemetry result on Ethereum Sepolia.
3. Attestcoin proves the source-chain event to Creditcoin.
4. Bounds releases payment or applies the agreed penalty.

## Current status

This repository is being developed for BUIDL CTC 2026 Fall.

PR 1 establishes the frontend, wallet, contract-development, testing, and documentation foundation. Sensor contracts, testnet deployments, and Attestcoin integration will be introduced in subsequent pull requests.

## Stack

- Next.js 16
- React 19
- TypeScript
- Tailwind CSS
- wagmi
- viem
- Solidity
- Foundry
- Ethereum Sepolia
- Creditcoin testnet
- Attestcoin Protocol

## Local development

Install dependencies:

```bash
pnpm install
````

Start the application:

```bash
pnpm dev
```

Run frontend checks:

```bash
pnpm lint
pnpm build
```

Run contract tests:

```bash
pnpm contracts:test
```

## Environment

Copy the environment template:

```bash
cp .env.example .env.local
```

Never commit private keys or populated environment files.

## Developer resources

* [Attestcoin Protocol](https://attestcoin.org/)
* [Developer documentation](https://docs.attestcoin.org/)
* [Chains and environments](https://docs.attestcoin.org/attestcoin-protocol/attestcoin-protocol-chains-environments)
* [Guided tutorials](https://docs.attestcoin.org/attestcoin-protocol/guided-tutorials)
* [Attestcoin SDK](https://docs.attestcoin.org/attestcoin-protocol/dapp-builder-infrastructure/attestcoin-sdk-usc-sdk)