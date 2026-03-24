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

**One-line deploy** (replace `YOUR_ALCHEMY_KEY` and `YOUR_ETHERSCAN_API_KEY`; never commit real secrets):

```bash
forge script script/DeploySuperOrbPositionalAMM.s.sol:DeploySuperOrbPositionalAMM --rpc-url "https://eth-mainnet.g.alchemy.com/v2/YOUR_ALCHEMY_KEY" --account shells --chain mainnet --broadcast --verify --etherscan-api-key "YOUR_ETHERSCAN_API_KEY" -vvvv
```

**Quoting:** Double-quote both the `--rpc-url` value and the `--etherscan-api-key` value. That is valid in `bash`/`zsh`, avoids surprises if the URL ever contains `&` or `?`, and keeps the API key from being mangled by the shell. (Unquoted values often work for simple alphanumeric URLs and keys, but quotes are the safe default.)

Deploy uses the canonical mainnet USDC/USDT addresses from the script (enforced when `chainid == 1` unless you set `SKIP_MAINNET_TOKEN_CHECK=true`). You can instead set `ETH_RPC_URL` and `ETHERSCAN_API_KEY` and use `"$ETH_RPC_URL"` / `"$ETHERSCAN_API_KEY"` in the same flags.

Foundry uses the `mainnet` etherscan entry from `foundry.toml` when the key is not passed on the CLI. If verification fails, confirm the RPC reports chain id `1` and the API key is valid for [Etherscan](https://etherscan.io/apis).

### Tests

```bash
forge test
```

