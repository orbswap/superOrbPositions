# Super Orb Positions

Prototype of experimental SuperPosition integration with Barter & Orbital AMM

## Resources

https://orbswap.org/

https://barterswap.xyz/superposition

## Deploy (Ethereum mainnet)

**Canonical token addresses (Ethereum mainnet, chain id 1)**

| Token | Address |
|-------|---------|
| USDC | `0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48` |
| USDT | `0xdAC17F958D2ee523a2206206994597C13D831ec7` |

These match `USDC_MAINNET` / `USDT_MAINNET` in `script/DeploySuperOrbPositionalAMM.s.sol`.

Prerequisites: [Foundry](https://book.getfoundry.sh/), a Cast keystore account named `shells`, a mainnet RPC URL, and an [Etherscan API key](https://etherscan.io/apis).

Set environment variables locally (never commit real keys; `.env` is gitignored):

```bash
# Ethereum mainnet — Alchemy shape: https://eth-mainnet.g.alchemy.com/v2/<YOUR_KEY>
export ETH_RPC_URL="https://eth-mainnet.g.alchemy.com/v2/YOUR_ALCHEMY_KEY"
export ETHERSCAN_API_KEY="YOUR_ETHERSCAN_API_KEY"
```

Deploy `SuperOrbPositionalAMM` with the canonical mainnet USDC/USDT addresses (enforced when `chainid == 1` unless you set `SKIP_MAINNET_TOKEN_CHECK=true`):

```bash
forge script script/DeploySuperOrbPositionalAMM.s.sol:DeploySuperOrbPositionalAMM \
  --rpc-url "$ETH_RPC_URL" \
  --account shells \
  --chain mainnet \
  --broadcast \
  --verify \
  --etherscan-api-key "$ETHERSCAN_API_KEY" \
  -vvvv
```

Foundry uses the `mainnet` etherscan entry from `foundry.toml` when the key is not passed on the CLI. If verification fails, confirm the RPC reports chain id `1` and the API key is valid for [Etherscan](https://etherscan.io/apis).

### Tests

```bash
forge test
```

