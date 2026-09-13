import { proofProvider } from "@gluwa/usc-sdk";
import {
  Contract,
  JsonRpcProvider,
  Wallet,
  type TransactionReceipt,
} from "ethers";

const ETHEREUM_SEPOLIA_CHAIN_KEY = 1;
const CREDITCOIN_TESTNET_CHAIN_ID = 102031;
const DEFAULT_SAFE_TX =
  "0x88b3be315db41b61d5369693691f395d11765149f205ee5119ac120286263d3c";

const settlementAbi = [
  "function settleWithAttestcoin(uint64 chainKey,uint64 blockHeight,bytes encodedTransaction,bytes32 merkleRoot,(bytes32 hash,bool isLeft)[] siblings,bytes32 lowerEndpointDigest,bytes32[] continuityRoots) returns (bool)",
] as const;

function required(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

async function main() {
  const sourceTransactionHash = process.argv[2] ?? DEFAULT_SAFE_TX;

  const sepoliaProvider = new JsonRpcProvider(
    required("ETHEREUM_SEPOLIA_RPC_URL"),
  );
  const sourceReceipt: TransactionReceipt | null =
    await sepoliaProvider.getTransactionReceipt(sourceTransactionHash);

  if (!sourceReceipt) {
    throw new Error(`Sepolia transaction not found: ${sourceTransactionHash}`);
  }
  if (sourceReceipt.status !== 1) {
    throw new Error("The source telemetry transaction failed");
  }

  const proofBuilder = new proofProvider.service.ProofBuilder(
    ETHEREUM_SEPOLIA_CHAIN_KEY,
    required("CREDITCOIN_PROOF_BUILDER_URL"),
  );

  console.log(
    `Waiting for Sepolia block ${sourceReceipt.blockNumber} to be available through Attestcoin...`,
  );

  await proofBuilder.waitUntilHeightAttested(
    ETHEREUM_SEPOLIA_CHAIN_KEY,
    sourceReceipt.blockNumber,
    5_000,
    120_000,
    0,
  );

  const proofResult = await proofBuilder.getProof(sourceTransactionHash);
  if (!proofResult.success || !proofResult.data) {
    throw new Error(`Proof generation failed: ${proofResult.error}`);
  }

  const proof = proofResult.data;

  console.log(
    `Attestcoin proof generated for chain key ${proof.chainKey}, block ${proof.headerNumber}.`,
  );

  const creditcoinProvider = new JsonRpcProvider(
    required("CREDITCOIN_RPC_URL"),
    {
      chainId: CREDITCOIN_TESTNET_CHAIN_ID,
      name: "creditcoin-testnet",
    },
    { staticNetwork: true },
  );

  const wallet = new Wallet(
    required("DEPLOYER_PRIVATE_KEY"),
    creditcoinProvider,
  );
  const settlement = new Contract(
    required("SETTLEMENT_CONTRACT_ADDRESS"),
    settlementAbi,
    wallet,
  );

  const transaction = await settlement.settleWithAttestcoin(
    proof.chainKey,
    proof.headerNumber,
    proof.txBytes,
    proof.merkleProof.root,
    proof.merkleProof.siblings,
    proof.continuityProof.lowerEndpointDigest,
    proof.continuityProof.roots,
    {
      type: 0,
      gasPrice: 500_000_000,
      gasLimit: 3_000_000,
    },
  );

  console.log(`Creditcoin settlement submitted: ${transaction.hash}`);

  const receipt = await transaction.wait();
  if (!receipt || receipt.status !== 1) {
    throw new Error("Creditcoin settlement transaction failed");
  }

  console.log(`Settlement confirmed in block ${receipt.blockNumber}.`);
  console.log(
    `Explorer: https://creditcoin-testnet.blockscout.com/tx/${transaction.hash}`,
  );
}

main().catch((error: unknown) => {
  console.error(error);
  process.exit(1);
});
