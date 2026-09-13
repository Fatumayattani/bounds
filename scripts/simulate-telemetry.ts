import {
  createPublicClient,
  createWalletClient,
  http,
  keccak256,
  toBytes,
  type Hex,
} from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { sepolia } from "viem/chains";

const telemetryAbi = [
  {
    type: "function",
    name: "submitTelemetry",
    stateMutability: "nonpayable",
    inputs: [
      { name: "shipmentId", type: "bytes32" },
      { name: "minimumTemperature", type: "int16" },
      { name: "maximumTemperature", type: "int16" },
      { name: "outOfRangeSeconds", type: "uint32" },
      { name: "recordedAt", type: "uint64" },
      { name: "telemetryHash", type: "bytes32" },
    ],
    outputs: [{ name: "nonce", type: "uint64" }],
  },
] as const;

const SAFE_MINIMUM_CELSIUS = 2;
const SAFE_MAXIMUM_CELSIUS = 8;
const READING_INTERVAL_SECONDS = 60;

const scenarios = {
  safe: [4.1, 4.3, 4.0, 4.5, 4.2],
  breach: [4.2, 4.6, 9.3, 10.1, 7.4],
} as const;

type Scenario = keyof typeof scenarios;

function readScenario(value: string | undefined): Scenario {
  if (value === "safe" || value === "breach") {
    return value;
  }

  throw new Error('Scenario must be either "safe" or "breach".');
}

function requireEnvironment(name: string): string {
  const value = process.env[name];

  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }

  return value;
}

async function main() {
  const scenario = readScenario(process.argv[2] ?? "safe");
  const shouldSubmit = process.argv.includes("--submit");
  const shipmentReference = process.env.SHIPMENT_REFERENCE ?? "BND-001";
  const readings = [...scenarios[scenario]];
  const recordedAt = Math.floor(Date.now() / 1_000);

  const minimumTemperature = Math.round(Math.min(...readings) * 100);
  const maximumTemperature = Math.round(Math.max(...readings) * 100);

  const outOfRangeReadings = readings.filter(
    (reading) =>
      reading < SAFE_MINIMUM_CELSIUS || reading > SAFE_MAXIMUM_CELSIUS,
  ).length;

  const outOfRangeSeconds =
    outOfRangeReadings * READING_INTERVAL_SECONDS;

  const payload = {
    shipmentReference,
    scenario,
    readings,
    permittedRange: {
      minimumCelsius: SAFE_MINIMUM_CELSIUS,
      maximumCelsius: SAFE_MAXIMUM_CELSIUS,
    },
    readingIntervalSeconds: READING_INTERVAL_SECONDS,
    recordedAt,
  };

  const shipmentId = keccak256(toBytes(shipmentReference));
  const telemetryHash = keccak256(toBytes(JSON.stringify(payload)));

  console.log(
    JSON.stringify(
      {
        mode: shouldSubmit ? "submit" : "dry-run",
        shipmentReference,
        shipmentId,
        scenario,
        readings,
        minimumTemperatureCelsius: minimumTemperature / 100,
        maximumTemperatureCelsius: maximumTemperature / 100,
        outOfRangeSeconds,
        compliant: outOfRangeSeconds === 0,
        recordedAt,
        telemetryHash,
      },
      null,
      2,
    ),
  );

  if (!shouldSubmit) {
    console.log(
      "\nDry run complete. Add --submit to create the Sepolia transaction.",
    );
    return;
  }

  const rpcUrl = requireEnvironment("ETHEREUM_SEPOLIA_RPC_URL");
  const contractAddress = requireEnvironment(
    "TELEMETRY_CONTRACT_ADDRESS",
  ) as Hex;
  const sensorPrivateKey = requireEnvironment("SENSOR_PRIVATE_KEY") as Hex;

  const account = privateKeyToAccount(sensorPrivateKey);

  const publicClient = createPublicClient({
    chain: sepolia,
    transport: http(rpcUrl),
  });

  const walletClient = createWalletClient({
    account,
    chain: sepolia,
    transport: http(rpcUrl),
  });

  const transactionHash = await walletClient.writeContract({
    address: contractAddress,
    abi: telemetryAbi,
    functionName: "submitTelemetry",
    args: [
      shipmentId,
      minimumTemperature,
      maximumTemperature,
      outOfRangeSeconds,
      BigInt(recordedAt),
      telemetryHash,
    ],
  });

  console.log(`\nSepolia transaction submitted: ${transactionHash}`);

  const receipt = await publicClient.waitForTransactionReceipt({
    hash: transactionHash,
  });

  console.log(`Transaction confirmed in block ${receipt.blockNumber}.`);
}

main().catch((error: unknown) => {
  const message = error instanceof Error ? error.message : String(error);
  console.error(`Sensor simulation failed: ${message}`);
  process.exitCode = 1;
});
