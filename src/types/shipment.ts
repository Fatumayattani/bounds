export type ShipmentStatus =
  | "created"
  | "bonded"
  | "in_transit"
  | "telemetry_committed"
  | "proof_pending"
  | "compliant"
  | "breached"
  | "settled"
  | "cancelled";

export type SettlementOutcome =
  | "pending"
  | "full_payment"
  | "penalized"
  | "refunded";

export interface TemperaturePolicy {
  minimumCelsius: number;
  maximumCelsius: number;
}

export interface Shipment {
  id: string;
  cargo: string;
  origin: string;
  destination: string;
  carrier: string;
  sensor: string;
  paymentAmount: string;
  bondAmount: string;
  policy: TemperaturePolicy;
  status: ShipmentStatus;
  outcome: SettlementOutcome;
}
