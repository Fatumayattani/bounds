"use client";

import { formatEther, parseAbi, type Address, type Hex } from "viem";
import { useReadContract } from "wagmi";

import { creditcoinTestnet } from "@/config/wagmi";

const settlementAddress = (process.env
  .NEXT_PUBLIC_SETTLEMENT_CONTRACT_ADDRESS ||
  "0x4b403e46800A485fdE2a0be2228228f78f20C7D4") as Address;

const settlementAbi = parseAbi([
  "function shipments(bytes32) view returns (address buyer, address carrier, uint128 amount, uint16 penaltyBps, uint8 status, address sensor, uint64 nonce, int16 minimumTemperature, int16 maximumTemperature, uint32 outOfRangeSeconds, uint64 recordedAt, bytes32 telemetryHash, bytes32 queryId)",
]);

const shipments = [
  {
    reference: "BND-001",
    shipmentId:
      "0xe908418e707a475835fe4f8bb35e818662999e2e266ef4603592c42a0f2e4fb5" as Hex,
  },
  {
    reference: "BND-BREACH-001",
    shipmentId:
      "0xec6bd16d157da907465e09f3b2598a231f7613c0166d0dec3ded799336993e33" as Hex,
  },
];

const statusLabels = ["Unfunded", "Funded", "Compliant", "Breached"];

function formatTemperature(value: number) {
  return `${(value / 100).toFixed(1)}°C`;
}

function LiveShipment({
  reference,
  shipmentId,
}: {
  reference: string;
  shipmentId: Hex;
}) {
  const { data, error, isPending, dataUpdatedAt } = useReadContract({
    address: settlementAddress,
    abi: settlementAbi,
    functionName: "shipments",
    args: [shipmentId],
    chainId: creditcoinTestnet.id,
    query: {
      refetchInterval: 12_000,
    },
  });

  if (isPending) {
    return (
      <article className="chain-read-card loading">
        <span className="chain-read-pulse" />
        Reading {reference} from Creditcoin…
      </article>
    );
  }

  if (error || !data) {
    return (
      <article className="chain-read-card failed">
        <strong>{reference}</strong>
        <span>Creditcoin read unavailable · explorer evidence remains linked below</span>
      </article>
    );
  }

  const [
    ,
    ,
    amount,
    ,
    status,
    ,
    ,
    minimumTemperature,
    maximumTemperature,
    outOfRangeSeconds,
    ,
    ,
    queryId,
  ] = data;

  const statusNumber = Number(status);
  const statusLabel = statusLabels[statusNumber] || "Unknown";
  const statusClass =
    statusNumber === 2
      ? "compliant"
      : statusNumber === 3
        ? "breached"
        : "pending";

  return (
    <article className="chain-read-card">
      <div className="chain-read-heading">
        <div>
          <span>Live Creditcoin state</span>
          <strong>{reference}</strong>
        </div>
        <span className={`status-badge ${statusClass}`}>{statusLabel}</span>
      </div>

      <div className="chain-read-values">
        <div>
          <span>Escrow</span>
          <strong>{formatEther(amount)} tCTC</strong>
        </div>
        <div>
          <span>Attested range</span>
          <strong>
            {formatTemperature(Number(minimumTemperature))} —{" "}
            {formatTemperature(Number(maximumTemperature))}
          </strong>
        </div>
        <div>
          <span>Exposure</span>
          <strong>{Number(outOfRangeSeconds)} seconds</strong>
        </div>
      </div>

      <div className="chain-read-footer">
        <span className="network-dot" />
        Read directly from contract · refreshed{" "}
        {dataUpdatedAt ? new Date(dataUpdatedAt).toLocaleTimeString() : "now"}
        <code>{`${queryId.slice(0, 10)}…${queryId.slice(-6)}`}</code>
      </div>
    </article>
  );
}

export function LiveSettlements() {
  return (
    <div className="live-chain-grid" aria-label="Live Creditcoin contract state">
      {shipments.map((shipment) => (
        <LiveShipment key={shipment.shipmentId} {...shipment} />
      ))}
    </div>
  );
}