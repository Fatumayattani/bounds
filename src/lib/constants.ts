export const APP_NAME = "Bounds";

export const APP_DESCRIPTION =
  "A DePIN settlement protocol that uses Attestcoin-verified sensor data to settle cold-chain shipments on Creditcoin.";

export const PROTOCOL_FLOW = [
  {
    step: "01",
    label: "Sense",
    description: "A registered device records shipment temperature.",
  },
  {
    step: "02",
    label: "Commit",
    description: "The device commits its telemetry event on Ethereum Sepolia.",
  },
  {
    step: "03",
    label: "Verify",
    description: "Attestcoin proves the source-chain event on Creditcoin.",
  },
  {
    step: "04",
    label: "Settle",
    description: "Bounds releases payment or applies the agreed penalty.",
  },
] as const;
