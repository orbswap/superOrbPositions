# Super Orb Positions

Prototype of experimental SuperPosition integration with Barter & Orbital AMM

## Resources

https://orbswap.org/

https://barterswap.xyz/superposition

## Deploy (Ethereum mainnet)

Prerequisites: [Foundry](https://book.getfoundry.sh/), a Cast keystore account named `shells`, a mainnet RPC URL, and an [Etherscan API key](https://etherscan.io/apis).

Set environment variables (replace placeholders):

```bash
export ETH_RPC_URL="https://your-custom-mainnet-rpc.example"
export ETHERSCAN_API_KEY="your_etherscan_api_key"
```

Deploy `SuperOrbPositionalAMM` with the canonical mainnet USDC/USDT addresses (enforced when `chainid == 1` unless you set `SKIP_MAINNET_TOKEN_CHECK=true`):

```bash
forge script script/DeploySuperOrbPositionalAMM.s.sol:DeploySuperOrbPositionalAMM \
  --rpc-url "$ETH_RPC_URL" \
  --account shells \
  --broadcast \
  --verify \
  --etherscan-api-key "$ETHERSCAN_API_KEY" \
  -vvvv
```

Foundry uses the `mainnet` etherscan entry from `foundry.toml` (`ETHERSCAN_API_KEY`). If verification fails, confirm the RPC reports chain id `1` and the API key has access to Etherscan (not only other explorers).

### Tests

```bash
forge test
```

