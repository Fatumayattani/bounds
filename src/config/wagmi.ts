import { defineChain } from "viem";
import { createConfig, http } from "wagmi";
import { sepolia } from "wagmi/chains";
import { injected } from "wagmi/connectors";

export const creditcoinTestnet = defineChain({
  id: 102031,
  name: "Creditcoin Testnet",
  nativeCurrency: {
    name: "Test Creditcoin",
    symbol: "tCTC",
    decimals: 18,
  },
  rpcUrls: {
    default: {
      http: [
        process.env.NEXT_PUBLIC_CREDITCOIN_RPC_URL ||
          "https://rpc.cc3-testnet.creditcoin.network",
      ],
    },
  },
  blockExplorers: {
    default: {
      name: "Creditcoin Testnet Explorer",
      url: "https://creditcoin-testnet.blockscout.com",
    },
  },
  testnet: true,
});

export const wagmiConfig = createConfig({
  chains: [sepolia, creditcoinTestnet],
  connectors: [injected()],
  transports: {
    [sepolia.id]: http(process.env.NEXT_PUBLIC_SEPOLIA_RPC_URL),
    [creditcoinTestnet.id]: http(
      process.env.NEXT_PUBLIC_CREDITCOIN_RPC_URL ||
        "https://rpc.cc3-testnet.creditcoin.network",
    ),
  },
  ssr: true,
});